import Foundation

struct LoginUseCase: Sendable {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> User {
        try await repository.login(email: email, password: password)
    }
}
