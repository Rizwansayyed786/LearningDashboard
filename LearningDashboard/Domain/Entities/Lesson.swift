import Foundation

struct Lesson: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    var isCompleted: Bool
}
