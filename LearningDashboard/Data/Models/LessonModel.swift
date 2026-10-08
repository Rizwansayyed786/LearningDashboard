import Foundation

struct LessonModel: Codable, Equatable, Sendable {
    let id: Int
    let title: String
    var isCompleted: Bool
}

extension LessonModel {
    init(_ lesson: Lesson) {
        self.init(id: lesson.id, title: lesson.title, isCompleted: lesson.isCompleted)
    }

    func toDomain() -> Lesson {
        Lesson(id: id, title: title, isCompleted: isCompleted)
    }
}
