import Foundation

struct Course: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    let instructor: String
    var lessons: [Lesson]

    var totalLessons: Int { lessons.count }
    var completedLessons: Int { lessons.filter(\.isCompleted).count }

    /// Derived from lessons, never stored, so it can't drift out of sync.
    var progress: Int {
        ProgressCalculator.calculateProgress(
            completedLessons: completedLessons,
            totalLessons: totalLessons
        )
    }
}
