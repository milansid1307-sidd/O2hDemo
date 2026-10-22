import Foundation

// MARK: - NetworkError

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(Int)
    case noInternet
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "The request URL is invalid."
        case .noData:               return "No data was returned from the server."
        case .decodingFailed(let e): return "Failed to parse response: \(e.localizedDescription)"
        case .serverError(let code): return "Server returned error code \(code)."
        case .noInternet:           return "No internet connection. Showing cached content."
        case .unknown(let e):       return e.localizedDescription
        }
    }
}

// MARK: - NetworkServiceProtocol

protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(_ type: T.Type, from endpoint: APIEndpoint) async throws -> T
}

// MARK: - NetworkService

/// Thin URLSession wrapper. Keeps ViewModels free of URLSession details.
final class NetworkService: NetworkServiceProtocol {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable>(_ type: T.Type, from endpoint: APIEndpoint) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noInternet
        }

        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.unknown(error)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NetworkError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
