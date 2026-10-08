import Foundation
import os

/// Remote first, local cache as fallback. An `actor` so the read-modify-write in
/// `completeLesson` and the cache refresh in `getCourses` can never interleave.
actor CourseRepositoryImpl: CourseRepository {
    private let remote: CourseAPI
    private let local: CourseLocalDataSource
    private let logger = Logger(subsystem: "LearningDashboard", category: "CourseRepository")

    init(remote: CourseAPI, local: CourseLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    // MARK: CourseRepository

    func getCourses() async throws -> CoursesResult {
        let remoteModels: [CourseModel]
        do {
            remoteModels = try await remote.fetchCourses()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return try cachedResult(after: error)
        }

        // Local progress wins over remote so a refresh never un-completes a lesson.
        let merged = Self.merge(remote: remoteModels, cached: cachedModels() ?? [])
        do {
            try local.saveCourses(merged)
        } catch {
            logger.error("Failed to write course cache: \(error.localizedDescription)")
        }
        return CoursesResult(courses: merged.map { $0.toDomain() }, isFromCache: false)
    }

    func getCourse(id: Int) async throws -> Course {
        guard let model = cachedModels()?.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return model.toDomain()
    }

    func completeLesson(courseId: Int, lessonId: Int) async throws -> Course {
        var models = cachedModels() ?? []
        guard let courseIndex = models.firstIndex(where: { $0.id == courseId }),
              let lessonIndex = models[courseIndex].lessons.firstIndex(where: { $0.id == lessonId })
        else {
            throw APIError.notFound
        }

        models[courseIndex].lessons[lessonIndex].isCompleted = true
        do {
            try local.saveCourses(models)
        } catch {
            logger.error("Failed to persist lesson completion: \(error.localizedDescription)")
            throw APIError.storageError
        }
        return models[courseIndex].toDomain()
    }

    // MARK: Helpers

    private func cachedResult(after remoteError: Error) throws -> CoursesResult {
        if let cached = cachedModels() {
            return CoursesResult(courses: cached.map { $0.toDomain() }, isFromCache: true)
        }
        // Only translate connectivity failures; other errors keep their own message.
        if let apiError = remoteError as? APIError, apiError == .networkError {
            throw APIError.noCachedData
        }
        throw remoteError
    }

    /// A corrupt cache is treated as "no cache" rather than crashing or blocking the user.
    private func cachedModels() -> [CourseModel]? {
        do {
            return try local.loadCourses()
        } catch {
            logger.error("Failed to read course cache: \(error.localizedDescription)")
            return nil
        }
    }

    private static func merge(remote: [CourseModel], cached: [CourseModel]) -> [CourseModel] {
        let completedByCourse: [Int: Set<Int>] = Dictionary(
            cached.map { course in
                (course.id, Set(course.lessons.filter(\.isCompleted).map(\.id)))
            },
            uniquingKeysWith: { first, _ in first }
        )

        return remote.map { course in
            var course = course
            let completed = completedByCourse[course.id] ?? []
            course.lessons = course.lessons.map { lesson in
                var lesson = lesson
                lesson.isCompleted = lesson.isCompleted || completed.contains(lesson.id)
                return lesson
            }
            return course
        }
    }
}
