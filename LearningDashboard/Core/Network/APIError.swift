import Foundation

/// App-wide error model. Messages are user-facing and never leak implementation details.
enum APIError: Error, Equatable {
    case invalidResponse
    case networkError
    case decodingError
    case serverError(String)
    case noCachedData
    case invalidCredentials
    case notFound
    case storageError
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse, .decodingError:
            return "We received an unexpected response. Please try again later."
        case .networkError:
            return "Unable to connect. Check your internet connection and try again."
        case .serverError:
            return "The server is having trouble right now. Please try again later."
        case .noCachedData:
            return "You're offline and there are no saved courses yet. Connect to the internet and try again."
        case .invalidCredentials:
            return "Incorrect email or password."
        case .notFound:
            return "We couldn't find that course or lesson."
        case .storageError:
            return "We couldn't save your progress on this device."
        }
    }
}
