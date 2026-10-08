import Foundation

struct CompleteLessonUseCase: Sendable {
    private let repository: CourseRepository

    init(repository: CourseRepository) {
        self.repository = repository
    }

    func execute(courseId: Int, lessonId: Int) async throws -> Course {
        try await repository.completeLesson(courseId: courseId, lessonId: lessonId)
    }
}
