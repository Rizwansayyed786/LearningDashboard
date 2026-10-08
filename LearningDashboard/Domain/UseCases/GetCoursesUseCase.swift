import Foundation

struct GetCoursesUseCase: Sendable {
    private let repository: CourseRepository

    init(repository: CourseRepository) {
        self.repository = repository
    }

    func execute() async throws -> CoursesResult {
        try await repository.getCourses()
    }
}
