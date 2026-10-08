import Foundation

protocol AuthAPI: Sendable {
    func login(email: String, password: String) async throws -> UserModel
}

/// Mock backend. Valid credentials: student@example.com / password123.
/// A real API would also return an access token, which belongs in the Keychain.
struct MockAuthAPI: AuthAPI {
    static let validEmail = "student@example.com"
    static let validPassword = "password123"

    func login(email: String, password: String) async throws -> UserModel {
        try await Task.sleep(for: .seconds(1))
        guard email.lowercased() == Self.validEmail, password == Self.validPassword else {
            throw APIError.invalidCredentials
        }
        return UserModel(id: 1, name: "Student")
    }
}
