import Foundation

protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> User
}
