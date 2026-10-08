import Foundation

enum LoginState: Equatable {
    case idle
    case loading
    case success(User)
    case error(String)
}
