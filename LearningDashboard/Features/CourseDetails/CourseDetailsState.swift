import Foundation

enum CourseDetailsState: Equatable {
    case idle
    case loading
    case loaded(Course)
    case error(String)
}
