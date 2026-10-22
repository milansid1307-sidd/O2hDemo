import UIKit

// MARK: - GalleryImageCell

/// Two-column grid cell. Shows a shimmer while the image loads, then cross-fades it in.
/// Layout is programmatic (no XIB) so the cell registers cleanly without a storyboard reference.
final class GalleryImageCell: UICollectionViewCell {

    static let reuseID = "GalleryImageCell"

    // MARK: - UI Elements

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = AppTheme.Radius.sm
        iv.backgroundColor = AppColors.shimmerBase
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// Semi-transparent gradient overlay — makes the author label readable over any image.
    private let gradientOverlay: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
        layer.locations = [0.5, 1.0]
        return layer
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Font.caption()
        label.textColor = .white
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientOverlay.frame = imageView.bounds
        imageView.updateShimmerFrame()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CGColor doesn't observe trait changes — refresh manually on appearance switch
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            contentView.layer.borderColor = AppColors.cellBorder.cgColor
        }
    }

    // MARK: - Setup

    private func setupUI() {
        // Outer cell: shadow lives here — must NOT clip so shadow is visible
        layer.cornerRadius = AppTheme.Radius.lg
        layer.masksToBounds = false
        applyShadow(AppTheme.Shadow.card)
        backgroundColor = .clear

        // contentView: rounded corners + border + clips image to the rounded rect
        contentView.layer.cornerRadius  = AppTheme.Radius.lg
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth   = 1.5
        contentView.layer.borderColor   = AppColors.cellBorder.cgColor
        contentView.backgroundColor     = AppColors.shimmerBase

        contentView.addSubview(imageView)
        imageView.layer.addSublayer(gradientOverlay)
        contentView.addSubview(authorLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppTheme.Spacing.sm),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppTheme.Spacing.sm),
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppTheme.Spacing.sm)
        ])
    }

    // MARK: - Configuration

    func configure(with image: GalleryImage) {
        authorLabel.text = image.author
        imageView.loadImage(from: image.imageURL)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        authorLabel.text = nil
        imageView.stopShimmering()
    }

    // MARK: - Press Animation

    override var isHighlighted: Bool {
        didSet {
            let scale: CGFloat = isHighlighted ? 0.96 : 1.0
            UIView.animate(
                withDuration: AppTheme.Animation.quickDuration,
                delay: 0,
                usingSpringWithDamping: AppTheme.Animation.springDamping,
                initialSpringVelocity: AppTheme.Animation.springVelocity
            ) {
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }
}
