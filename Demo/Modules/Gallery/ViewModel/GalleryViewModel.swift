import UIKit

// MARK: - GalleryViewModelDelegate

protocol GalleryViewModelDelegate: AnyObject {
    func didStartLoading(isFirstPage: Bool)
    func didLoadImages(_ images: [GalleryImage], isFirstPage: Bool)
    func didFailLoading(with error: Error, showingCached: Bool)
    func didUpdateConnectivity(isConnected: Bool)
}

// MARK: - GalleryViewModel

@MainActor
final class GalleryViewModel {

    // MARK: Configuration
    private let pageSize = 20

    // MARK: Dependencies
    weak var delegate: GalleryViewModelDelegate?
    private let networkService: NetworkServiceProtocol
    private let realmManager: RealmManager

    // MARK: State
    private(set) var images: [GalleryImage] = []
    private(set) var currentPage: Int = 1
    private(set) var isFetching: Bool = false
    private(set) var hasMorePages: Bool = true

    // MARK: Init
    init(networkService: NetworkServiceProtocol = NetworkService(),
         realmManager: RealmManager = .shared) {
        self.networkService = networkService
        self.realmManager   = realmManager
        observeConnectivity()
    }

    // MARK: - Public API

    /// Initial load — resets pagination and clears existing data.
    func loadFirstPage() {
        currentPage  = 1
        hasMorePages = true
        images       = []
        fetchPage(currentPage, isFirstPage: true)
    }

    /// Called when the user scrolls near the bottom of the list.
    func loadNextPageIfNeeded(currentIndex: Int) {
        let threshold = images.count - 4
        guard currentIndex >= threshold,
              !isFetching,
              hasMorePages else { return }
        currentPage += 1
        fetchPage(currentPage, isFirstPage: false)
    }

    // MARK: - Private Fetch Logic

    private func fetchPage(_ page: Int, isFirstPage: Bool) {
        guard !isFetching else { return }
        isFetching = true
        delegate?.didStartLoading(isFirstPage: isFirstPage)

        Task {
            defer { self.isFetching = false }

            // No internet — serve from Realm if we have cached data
            guard NetworkMonitor.shared.isConnected else {
                let cached = realmManager.fetchAllGalleryImages().map { $0.toDomainModel() }
                if !cached.isEmpty {
                    images = cached
                    delegate?.didLoadImages(cached, isFirstPage: true)
                    delegate?.didFailLoading(
                        with: NetworkError.noInternet,
                        showingCached: true
                    )
                } else {
                    delegate?.didFailLoading(
                        with: NetworkError.noInternet,
                        showingCached: false
                    )
                }
                return
            }

            do {
                let photos = try await networkService.fetch(
                    [PicsumPhoto].self,
                    from: .galleryImages(page: page, limit: pageSize)
                )

                let newImages = photos.map { $0.toDomainModel() }

                // Persist to Realm for offline access
                let objects = newImages.enumerated().map { index, img in
                    GalleryImageObject(from: img, page: page, sortIndex: index)
                }
                realmManager.saveGalleryImages(objects)

                // If the server returned fewer items than the page size, we've hit the end
                hasMorePages = photos.count == pageSize

                if isFirstPage {
                    images = newImages
                } else {
                    images.append(contentsOf: newImages)
                }

                delegate?.didLoadImages(images, isFirstPage: isFirstPage)

            } catch {
                // Fall back to Realm cache on error
                if isFirstPage {
                    let cached = realmManager.fetchAllGalleryImages().map { $0.toDomainModel() }
                    if !cached.isEmpty {
                        images = cached
                        delegate?.didLoadImages(cached, isFirstPage: true)
                    }
                }
                delegate?.didFailLoading(with: error, showingCached: !images.isEmpty)
            }
        }
    }

    // MARK: - Connectivity Observer

    private func observeConnectivity() {
        NetworkMonitor.shared.onStatusChange = { [weak self] connected in
            guard let self else { return }
            Task { @MainActor in
                self.delegate?.didUpdateConnectivity(isConnected: connected)
                // Auto-reload when connection is restored
                if connected && self.images.isEmpty {
                    self.loadFirstPage()
                }
            }
        }
    }
}
