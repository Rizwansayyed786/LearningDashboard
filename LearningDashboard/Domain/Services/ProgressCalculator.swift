import Foundation

enum ProgressCalculator {
    /// Whole-number percentage (truncated), clamped to 0...100.
    /// Uses integer arithmetic on purpose: `Int(Double(29) / 100 * 100)` evaluates to 28
    /// because of floating-point error.
    static func calculateProgress(completedLessons: Int, totalLessons: Int) -> Int {
        guard totalLessons > 0 else { return 0 }
        let percentage = (completedLessons * 100) / totalLessons
        return min(max(percentage, 0), 100)
    }
}
