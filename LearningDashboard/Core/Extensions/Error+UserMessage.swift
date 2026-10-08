import Foundation

extension Error {
    /// A message that is safe to show to the user.
    var userMessage: String {
        if let localized = self as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
