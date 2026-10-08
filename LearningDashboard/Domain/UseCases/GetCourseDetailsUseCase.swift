import Foundation

struct GetCourseDetailsUseCase: Sendable {
    private let repository: CourseRepository

    init(repository: CourseRepository) {
        self.repository = repository
    }

    func execute(courseId: Int) async throws -> Course {
        try await repository.getCourse(id: courseId)
    }
}
