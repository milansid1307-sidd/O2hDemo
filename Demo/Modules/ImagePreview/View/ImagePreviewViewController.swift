import UIKit

// MARK: - ImagePreviewViewController

/// Full-screen image viewer presented modally.
/// Supports pinch-to-zoom, double-tap to zoom, and a close button.
/// Built entirely in code so the layout adapts to the image's natural aspect ratio.
final class ImagePreviewViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: ImagePreviewViewModel

    // MARK: - UI Elements

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.showsVerticalScrollIndicator   = false
        sv.showsHorizontalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .automatic
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// Subtle author credit at the bottom
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font      = AppTheme.Font.footnote()
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        label.alpha = 0.85
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = AppColors.textSecondary
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Init

    init(viewModel: ImagePreviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupGestures()
        loadImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Entrance: fade + subtle scale
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(
            withDuration: AppTheme.Animation.standardDuration,
            delay: 0,
            usingSpringWithDamping: AppTheme.Animation.springDamping,
            initialSpringVelocity: AppTheme.Animation.springVelocity
        ) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppColors.backgroundPrimary

        // Scroll view fills the screen
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(authorLabel)
        view.addSubview(activityIndicator)

        scrollView.delegate = self

        NSLayoutConstraint.activate([
            // scrollView: fills visible area below nav bar
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // imageView: matches scroll view frame; aspect ratio applied after load
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Author label: bottom of safe area
            authorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.md),
            authorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.md),
            authorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AppTheme.Spacing.md),

            // Spinner: center screen
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        authorLabel.text = "Photo by \(viewModel.authorName)"
    }

    private func setupNavigationBar() {
        title = "Image Preview"

        // Close button — top right
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.tintColor = AppColors.textPrimary
        navigationItem.rightBarButtonItem = closeButton

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

    private func setupGestures() {
        // Double-tap to toggle zoom between 1× and 2.5×
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - Image Loading

    private func loadImage() {
        // Step 1: show thumbnail from cache instantly — zero wait, no spinner flash
        if let thumbnail = ImageLoader.shared.cachedImage(for: viewModel.imageURL) {
            imageView.image = thumbnail
        } else {
            activityIndicator.startAnimating()
        }

        // Step 2: load full-res in background; replaces thumbnail when ready
        Task { @MainActor in
            let fullRes = await ImageLoader.shared.loadImage(from: viewModel.fullResolutionURL)
            activityIndicator.stopAnimating()

            UIView.transition(with: self.imageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.imageView.image = fullRes ?? self.imageView.image
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        UIView.animate(
            withDuration: AppTheme.Animation.quickDuration,
            animations: {
                self.view.alpha = 0
                self.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            },
            completion: { _ in
                self.dismiss(animated: false)
            }
        )
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: point.x - 50,
                y: point.y - 50,
                width: 100,
                height: 100
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate (pinch-to-zoom)

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    /// Re-centre the image after zooming so it never drifts to a corner.
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
