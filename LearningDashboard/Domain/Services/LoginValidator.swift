import Foundation

enum ValidationError: Error, Equatable, LocalizedError {
    case emptyEmail
    case invalidEmail
    case emptyPassword
    case passwordTooShort

    var errorDescription: String? {
        switch self {
        case .emptyEmail: return "Please enter your email."
        case .invalidEmail: return "Please enter a valid email address."
        case .emptyPassword: return "Please enter your password."
        case .passwordTooShort: return "Password must be at least 6 characters."
        }
    }
}

struct LoginValidator {
    static let minimumPasswordLength = 6
    private let emailPattern = #"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$"#

    func validateEmail(_ email: String) -> ValidationError? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .emptyEmail }
        if trimmed.range(of: emailPattern, options: .regularExpression) == nil { return .invalidEmail }
        return nil
    }

    func validatePassword(_ password: String) -> ValidationError? {
        if password.isEmpty { return .emptyPassword }
        if password.count < Self.minimumPasswordLength { return .passwordTooShort }
        return nil
    }
}
