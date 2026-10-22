import Foundation

// MARK: - APIEndpoint

/// Typed endpoint definitions. Adding a new API call = adding a case here.
/// No raw URL strings scattered across the codebase.
enum APIEndpoint {

    // Picsum Photos — free, no auth required
    // Docs: https://picsum.photos/
    case galleryImages(page: Int, limit: Int)

    // MARK: Base
    private static let baseURL = "https://picsum.photos"

    // MARK: URL Construction
    var url: URL? {
        switch self {
        case .galleryImages(let page, let limit):
            var components = URLComponents(string: Self.baseURL + "/v2/list")
            components?.queryItems = [
                URLQueryItem(name: "page",  value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            return components?.url
        }
    }
}
