import Foundation

// MARK: - GalleryImage (Domain Model)

/// Pure value type used throughout the app. Decoupled from Realm and the network layer.
struct GalleryImage: Equatable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let imageURL: String    // Picsum download URL (thumbnail-sized)

    /// Aspect ratio — used to calculate dynamic cell height in the grid.
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }
}

// MARK: - PicsumPhoto (API DTO)

/// Matches the JSON shape returned by picsum.photos/v2/list
struct PicsumPhoto: Decodable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case id, author, width, height
        case downloadURL = "download_url"
    }

    /// Maps the network DTO to the domain model.
    func toDomainModel() -> GalleryImage {
        // Request a 400px-wide version to keep bandwidth reasonable
        let thumbnailURL = "https://picsum.photos/id/\(id)/400/300"
        return GalleryImage(
            id: id,
            author: author,
            width: width,
            height: height,
            imageURL: thumbnailURL
        )
    }
}

// MARK: - GalleryImageObject (Realm Persistence Model)

import RealmSwift

/// Realm-managed object. Keep it thin — only storage concerns live here.
/// Convert to/from GalleryImage at the repository boundary.
final class GalleryImageObject: Object {

    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var author: String = ""
    @Persisted var width: Int = 0
    @Persisted var height: Int = 0
    @Persisted var imageURL: String = ""
    @Persisted var page: Int = 0
    /// Preserves server-side ordering within a page.
    @Persisted var sortIndex: Int = 0
    @Persisted var cachedAt: Date = Date()

    // MARK: Convenience init from domain model
    convenience init(from image: GalleryImage, page: Int, sortIndex: Int) {
        self.init()
        self.id        = image.id
        self.author    = image.author
        self.width     = image.width
        self.height    = image.height
        self.imageURL  = image.imageURL
        self.page      = page
        self.sortIndex = sortIndex
        self.cachedAt  = Date()
    }

    /// Maps back to the domain model.
    func toDomainModel() -> GalleryImage {
        GalleryImage(id: id, author: author, width: width, height: height, imageURL: imageURL)
    }
}
