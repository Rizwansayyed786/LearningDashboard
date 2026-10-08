import XCTest
@testable import LearningDashboard

final class CourseRepositoryTests: XCTestCase {
    private var storage: InMemoryStorage!
    private var local: UserDefaultsCourseLocalDataSource!

    override func setUp() {
        super.setUp()
        storage = InMemoryStorage()
        local = UserDefaultsCourseLocalDataSource(storage: storage)
    }

    private func repository(remote: Result<[CourseModel], Error>) -> CourseRepositoryImpl {
        CourseRepositoryImpl(remote: FakeCourseAPI(result: remote), local: local)
    }

    func testOnlineReturnsRemoteCoursesAndCachesThem() async throws {
        let repo = repository(remote: .success(TestData.models()))

        let result = try await repo.getCourses()

        XCTAssertFalse(result.isFromCache)
        XCTAssertEqual(result.courses.count, 2)
        XCTAssertEqual(try local.loadCourses()?.count, 2)
    }

    func testOfflineWithCacheReturnsCachedCourses() async throws {
        _ = try await repository(remote: .success(TestData.models())).getCourses()

        // "Relaunch" offline: new repository, same storage.
        let offline = repository(remote: .failure(APIError.networkError))
        let result = try await offline.getCourses()

        XCTAssertTrue(result.isFromCache)
        XCTAssertEqual(result.courses.map(\.id), [1, 2])
    }

    func testOfflineWithoutCacheThrowsNoCachedData() async {
        let repo = repository(remote: .failure(APIError.networkError))

        do {
            _ = try await repo.getCourses()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .noCachedData)
        }
    }

    func testCompleteLessonPersistsAndUpdatesProgress() async throws {
        let repo = repository(remote: .success(TestData.models()))
        _ = try await repo.getCourses()

        let updated = try await repo.completeLesson(courseId: 1, lessonId: 101)
        XCTAssertEqual(updated.progress, 25)

        // Survives a "relaunch" while offline.
        let offline = repository(remote: .failure(APIError.networkError))
        let cached = try await offline.getCourses()
        XCTAssertEqual(cached.courses.first { $0.id == 1 }?.progress, 25)
    }

    func testRefreshDoesNotUndoLocallyCompletedLessons() async throws {
        let repo = repository(remote: .success(TestData.models()))
        _ = try await repo.getCourses()
        _ = try await repo.completeLesson(courseId: 1, lessonId: 101)

        // Remote still reports the lesson as pending.
        let refreshed = try await repo.getCourses()

        XCTAssertEqual(refreshed.courses.first { $0.id == 1 }?.progress, 25)
    }

    func testCompleteUnknownLessonThrowsNotFound() async throws {
        let repo = repository(remote: .success(TestData.models()))
        _ = try await repo.getCourses()

        do {
            _ = try await repo.completeLesson(courseId: 1, lessonId: 999)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .notFound)
        }
    }
}

// MARK: - Fakes

private struct FakeCourseAPI: CourseAPI {
    let result: Result<[CourseModel], Error>

    func fetchCourses() async throws -> [CourseModel] {
        try result.get()
    }
}

final class InMemoryStorage: LocalStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data] = [:]

    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        lock.lock(); defer { lock.unlock() }
        values[key] = data
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        lock.lock(); defer { lock.unlock() }
        guard let data = values[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}
