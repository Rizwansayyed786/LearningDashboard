import Foundation

/// Courses plus a flag telling the UI whether they came from the local cache.
struct CoursesResult: Equatable, Sendable {
    let courses: [Course]
    let isFromCache: Bool
}
