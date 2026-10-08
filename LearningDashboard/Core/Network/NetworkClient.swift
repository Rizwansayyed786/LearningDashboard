import Foundation

struct Endpoint: Sendable {
    let path: String
}

protocol NetworkClient: Sendable {
    func get<T: Decodable>(_ type: T.Type, from endpoint: Endpoint) async throws -> T
}

/// Production-style client. Not used by the mock setup, but `RemoteCourseAPI`
/// can be wired to it in `AppContainer` without touching any other layer.
struct URLSessionNetworkClient: NetworkClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ type: T.Type, from endpoint: Endpoint) async throws -> T {
        let request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))

        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw APIError.networkError
        }

        guard let http = result.1 as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError("HTTP \(http.statusCode)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: result.0)
        } catch {
            throw APIError.decodingError
        }
    }
}
