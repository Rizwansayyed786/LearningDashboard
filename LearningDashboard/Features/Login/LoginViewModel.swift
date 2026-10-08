import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""

    private(set) var state: LoginState = .idle
    private(set) var emailError: String?
    private(set) var passwordError: String?

    private let loginUseCase: LoginUseCase
    private let validator: LoginValidator

    init(loginUseCase: LoginUseCase, validator: LoginValidator = LoginValidator()) {
        self.loginUseCase = loginUseCase
        self.validator = validator
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func login() async {
        guard !isLoading else { return }
        guard validate() else { return }

        state = .loading
        do {
            let user = try await loginUseCase.execute(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            state = .success(user)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .error(error.userMessage)
        }
    }

    private func validate() -> Bool {
        emailError = validator.validateEmail(email)?.userMessage
        passwordError = validator.validatePassword(password)?.userMessage
        if emailError != nil || passwordError != nil {
            state = .idle
            return false
        }
        return true
    }
}
