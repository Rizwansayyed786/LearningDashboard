import Foundation

protocol CourseLocalDataSource: Sendable {
    /// `nil` means nothing has been cached yet.
    func loadCourses() throws -> [CourseModel]?
    func saveCourses(_ courses: [CourseModel]) throws
}

struct UserDefaultsCourseLocalDataSource: CourseLocalDataSource {
    private static let cacheKey = "cache.courses.v1"
    private let storage: LocalStorage

    init(storage: LocalStorage) {
        self.storage = storage
    }

    func loadCourses() throws -> [CourseModel]? {
        try storage.load([CourseModel].self, forKey: Self.cacheKey)
    }

    func saveCourses(_ courses: [CourseModel]) throws {
        try storage.save(courses, forKey: Self.cacheKey)
    }
}
