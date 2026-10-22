import UIKit

// MARK: - GalleryViewController

/// Two-column image grid with infinite scroll, shimmer loading,
/// pull-to-refresh, and an offline banner when there's no internet.
final class GalleryViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var offlineBannerView: UIView!
    @IBOutlet private weak var offlineBannerLabel: UILabel!

    // Constraint managed in code — storyboard sets initial constant to -44 (off-screen)
    private var offlineBannerTopConstraint: NSLayoutConstraint?

    // MARK: - Properties
    private var viewModel: GalleryViewModel!
    private var refreshControl: UIRefreshControl!
    private let shimmerPlaceholderCount = 6
    private var isShowingShimmer = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupNavigationBar()
        setupCollectionView()
        setupRefreshControl()
        setupOfflineBanner()
        viewModel.loadFirstPage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
    }

    // MARK: - Setup

    private func setupViewModel() {
        viewModel = GalleryViewModel()
        viewModel.delegate = self
    }

    private func setupNavigationBar() {
        title = "Gallery"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        // iOS 26 liquid glass: must set on navigationBar directly, not just navigationItem.
        // Setting only on navigationItem leaves the bar transparent when scrolled.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.backgroundPrimary
        appearance.titleTextAttributes = [
            .foregroundColor: AppColors.textPrimary,
            .font: AppTheme.Font.headline()
        ]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.compactAppearance    = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.standardAppearance   = appearance
        navigationItem.compactAppearance    = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }

    private func setupCollectionView() {
        collectionView.register(GalleryImageCell.self,
                                forCellWithReuseIdentifier: GalleryImageCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.collectionViewLayout = makeCompositionalLayout()
        collectionView.backgroundColor = AppColors.backgroundPrimary
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
    }

    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    private func setupOfflineBanner() {
        offlineBannerView.backgroundColor   = AppColors.warning
        offlineBannerView.layer.cornerRadius = AppTheme.Radius.sm
        offlineBannerView.alpha = 0

        offlineBannerLabel.font      = AppTheme.Font.footnote()
        offlineBannerLabel.textColor = .white
        offlineBannerLabel.text      = "No internet connection — showing cached content"

        // Grab the top constraint so we can animate the banner in/out
        offlineBannerTopConstraint = offlineBannerView.superview?
            .constraints
            .first(where: {
                $0.firstItem === offlineBannerView && $0.firstAttribute == .top
            })
    }

    // MARK: - Compositional Layout

    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let itemSize  = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                               heightDimension: .fractionalHeight(1.0))
        let item      = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(0.52))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item, item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Offline Banner

    private func showOfflineBanner() {
        guard offlineBannerView.alpha == 0 else { return }
        offlineBannerTopConstraint?.constant = 8
        UIView.animate(withDuration: AppTheme.Animation.standardDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5) {
            self.offlineBannerView.alpha = 1
            self.view.layoutIfNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.hideOfflineBanner()
        }
    }

    private func hideOfflineBanner() {
        offlineBannerTopConstraint?.constant = -44
        UIView.animate(withDuration: AppTheme.Animation.standardDuration) {
            self.offlineBannerView.alpha = 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    @objc private func handlePullToRefresh() {
        viewModel.loadFirstPage()
    }
}

// MARK: - GalleryViewModelDelegate

extension GalleryViewController: GalleryViewModelDelegate {

    func didStartLoading(isFirstPage: Bool) {
        if isFirstPage {
            isShowingShimmer = true
            collectionView.reloadData()
        }
    }

    func didLoadImages(_ images: [GalleryImage], isFirstPage: Bool) {
        isShowingShimmer = false
        refreshControl.endRefreshing()

        if isFirstPage {
            collectionView.reloadData()
            collectionView.alpha = 0
            UIView.animate(withDuration: AppTheme.Animation.standardDuration) {
                self.collectionView.alpha = 1
            }
        } else {
            let existing = collectionView.numberOfItems(inSection: 0)
            let newCount = images.count
            guard newCount > existing else { return }
            let paths = (existing..<newCount).map { IndexPath(item: $0, section: 0) }
            collectionView.insertItems(at: paths)
        }
    }

    func didFailLoading(with error: Error, showingCached: Bool) {
        isShowingShimmer = false
        refreshControl.endRefreshing()

        if showingCached {
            showOfflineBanner()
        } else {
            let alert = UIAlertController(title: "Couldn't Load Images",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                self?.viewModel.loadFirstPage()
            })
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

    func didUpdateConnectivity(isConnected: Bool) {
        isConnected ? hideOfflineBanner() : showOfflineBanner()
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        isShowingShimmer ? shimmerPlaceholderCount : viewModel.images.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryImageCell.reuseID, for: indexPath
        ) as? GalleryImageCell else { return UICollectionViewCell() }

        if isShowingShimmer {
            cell.startShimmering()
        } else {
            cell.stopShimmering()
            cell.configure(with: viewModel.images[indexPath.item])
            viewModel.loadNextPageIfNeeded(currentIndex: indexPath.item)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension GalleryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard !isShowingShimmer else { return }

        let image = viewModel.images[indexPath.item]
        let previewVM = ImagePreviewViewModel(image: image)
        let previewVC = ImagePreviewViewController(viewModel: previewVM)
        let nav = UINavigationController(rootViewController: previewVC)

        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle   = .crossDissolve

        present(nav, animated: false)
    }
}
