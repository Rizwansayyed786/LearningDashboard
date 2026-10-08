import Foundation

/// Wire/cache representation. Kept separate from the domain `Course` so API or
/// storage format changes never leak into business logic.
struct CourseModel: Codable, Equatable, Sendable {
    let id: Int
    let title: String
    let instructor: String
    var lessons: [LessonModel]
}

extension CourseModel {
    init(_ course: Course) {
        self.init(
            id: course.id,
            title: course.title,
            instructor: course.instructor,
            lessons: course.lessons.map(LessonModel.init)
        )
    }

    func toDomain() -> Course {
        Course(id: id, title: title, instructor: instructor, lessons: lessons.map { $0.toDomain() })
    }
}
