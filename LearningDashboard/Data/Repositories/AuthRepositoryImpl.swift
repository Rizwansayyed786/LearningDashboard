import Foundation

struct AuthRepositoryImpl: AuthRepository {
    private let api: AuthAPI

    init(api: AuthAPI) {
        self.api = api
    }

    func login(email: String, password: String) async throws -> User {
        try await api.login(email: email, password: password).toDomain()
    }
}
