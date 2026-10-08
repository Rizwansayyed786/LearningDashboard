import Foundation

enum DashboardState: Equatable {
    case idle
    case loading
    case loaded(courses: [Course], isFromCache: Bool)
    case empty
    case error(String)
}
