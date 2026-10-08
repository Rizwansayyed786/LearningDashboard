import Foundation

protocol CourseRepository: Sendable {
    func getCourses() async throws -> CoursesResult
    func getCourse(id: Int) async throws -> Course
    func completeLesson(courseId: Int, lessonId: Int) async throws -> Course
}
