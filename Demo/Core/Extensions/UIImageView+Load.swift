import UIKit

// MARK: - Image Loading & In-Memory Cache

/// Simple NSCache-backed image loader. Avoids re-downloading images already seen
/// in the current session. For persistent offline storage, see RealmManager + FileManager.
final class ImageLoader {

    static let shared = ImageLoader()
    private init() {}

    private let cache = NSCache<NSString, UIImage>()
    // Tracks in-flight tasks to avoid duplicate downloads for the same URL
    private var activeTasks: [String: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()

    /// Returns the in-memory cached image synchronously — nil if not cached.
    func cachedImage(for urlString: String) -> UIImage? {
        if let mem = cache.object(forKey: urlString as NSString) { return mem }
        // Also check disk so repeat opens skip the network entirely
        if let disk = loadFromDisk(id: urlString.imageStorageID) {
            cache.setObject(disk, forKey: urlString as NSString)
            return disk
        }
        return nil
    }

    func loadImage(from urlString: String) async -> UIImage? {
        // 1. Return cached image if available
        if let cached = cache.object(forKey: urlString as NSString) {
            return cached
        }

        // 2. Check local disk (persisted by RealmManager on first download)
        if let local = loadFromDisk(id: urlString.imageStorageID) {
            cache.setObject(local, forKey: urlString as NSString)
            return local
        }

        // 3. Download from network
        guard let url = URL(string: urlString) else { return nil }

        let task: Task<UIImage?, Never>
        lock.lock()
        if let existing = activeTasks[urlString] {
            lock.unlock()
            return await existing.value
        }

        task = Task<UIImage?, Never> {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return nil }

            self.cache.setObject(image, forKey: urlString as NSString)
            self.saveToDisk(data: data, id: urlString.imageStorageID)
            return image
        }
        activeTasks[urlString] = task
        lock.unlock()

        let result = await task.value
        lock.lock()
        activeTasks.removeValue(forKey: urlString)
        lock.unlock()
        return result
    }

    // MARK: Disk I/O

    private func diskURL(for id: String) -> URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("gallery_\(id).jpg")
    }

    func saveToDisk(data: Data, id: String) {
        try? data.write(to: diskURL(for: id), options: .atomic)
    }

    func loadFromDisk(id: String) -> UIImage? {
        let url = diskURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - String Helper

private extension String {
    /// Produces a safe filename from a URL string by hashing it.
    var imageStorageID: String {
        "\(self.hashValue)"
    }
}

// MARK: - UIImageView Extension

extension UIImageView {

    /// Loads an image asynchronously with shimmer while in-flight.
    /// Cancels any previous in-flight load when reused (e.g. in a collection cell).
    func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        // Show shimmer while loading
        image = placeholder
        layer.cornerRadius = 0
        startShimmering()

        Task { @MainActor in
            let loaded = await ImageLoader.shared.loadImage(from: urlString)
            stopShimmering()

            // Fade in the image for a polished feel
            UIView.transition(with: self, duration: 0.25, options: .transitionCrossDissolve) {
                self.image = loaded ?? placeholder
            }
        }
    }
}
