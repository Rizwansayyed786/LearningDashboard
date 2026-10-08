import Foundation

protocol CourseAPI: Sendable {
    func fetchCourses() async throws -> [CourseModel]
}

/// Real HTTP implementation, built on `NetworkClient`.
struct RemoteCourseAPI: CourseAPI {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func fetchCourses() async throws -> [CourseModel] {
        try await client.get([CourseModel].self, from: Endpoint(path: "courses"))
    }
}

/// Serves the bundled `courses.json` after a short artificial delay, and fails with
/// `networkError` when the device is offline, so the repository can't tell it from a real API.
struct MockCourseAPI: CourseAPI {
    private let connectivity: ConnectivityMonitor
    private let bundle: Bundle
    private let latency: Duration

    init(
        connectivity: ConnectivityMonitor,
        bundle: Bundle = .main,
        latency: Duration = .milliseconds(600)
    ) {
        self.connectivity = connectivity
        self.bundle = bundle
        self.latency = latency
    }

    func fetchCourses() async throws -> [CourseModel] {
        try await Task.sleep(for: latency)
        guard connectivity.isOnline else { throw APIError.networkError }

        guard let url = bundle.url(forResource: "courses", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw APIError.invalidResponse
        }
        do {
            return try JSONDecoder().decode([CourseModel].self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
