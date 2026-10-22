import Foundation
import RealmSwift

// MARK: - RealmManager

/// Centralised access point for Realm operations.
/// All reads/writes go through here — no direct Realm access from ViewModels.
final class RealmManager {

    // MARK: Shared
    static let shared = RealmManager()
    private init() {}

    // MARK: Private
    private var realm: Realm? {
        // Realm must be accessed on the same thread it was opened on.
        // For background work, open a new Realm instance per-thread.
        try? Realm()
    }

    // MARK: - Gallery Images

    /// Saves (or updates) an array of gallery images for a given page.
    func saveGalleryImages(_ images: [GalleryImageObject]) {
        guard let realm else { return }
        try? realm.write {
            realm.add(images, update: .modified)
        }
    }

    /// Returns all cached gallery images sorted by page then by their natural order.
    func fetchAllGalleryImages() -> [GalleryImageObject] {
        guard let realm else { return [] }
        return Array(
            realm.objects(GalleryImageObject.self)
                .sorted(byKeyPath: "page", ascending: true)
        )
    }

    /// Returns cached images for a specific page (used to check if page is already stored).
    func fetchGalleryImages(forPage page: Int) -> [GalleryImageObject] {
        guard let realm else { return [] }
        return Array(
            realm.objects(GalleryImageObject.self)
                .filter("page == %@", page)
                .sorted(byKeyPath: "sortIndex", ascending: true)
        )
    }

    /// True if at least one image exists for the given page.
    func hasCache(forPage page: Int) -> Bool {
        guard let realm else { return false }
        return !realm.objects(GalleryImageObject.self)
            .filter("page == %@", page)
            .isEmpty
    }

    /// Removes all cached gallery data — called on logout.
    func clearGalleryCache() {
        guard let realm else { return }
        try? realm.write {
            realm.delete(realm.objects(GalleryImageObject.self))
        }
    }
}
