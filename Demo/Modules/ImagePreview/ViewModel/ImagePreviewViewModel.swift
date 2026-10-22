import Foundation

// MARK: - ImagePreviewViewModel

/// Holds the image data for the preview screen.
/// Intentionally thin — preview has no business logic beyond displaying the image.
final class ImagePreviewViewModel {

    let image: GalleryImage

    init(image: GalleryImage) {
        self.image = image
    }

    var imageURL: String  { image.imageURL }
    var authorName: String { image.author }

    /// Full-resolution URL — swap the thumbnail dimensions for the original size.
    var fullResolutionURL: String {
        "https://picsum.photos/id/\(image.id)/\(image.width)/\(image.height)"
    }
}
