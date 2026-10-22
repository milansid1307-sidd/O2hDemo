import UIKit

// MARK: - ProfileViewController

/// Displays the signed-in user's avatar, name, email, info cards, and a logout action.
final class ProfileViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var avatarContainerView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var initialsLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var logoutButton: UIButton!

    // MARK: - Properties
    private var viewModel: ProfileViewModel!

    /// Info card rows inserted between the email and logout button.
    private var infoStackView: UIStackView!
    /// Title label of the last card — updated dynamically when theme changes.
    private weak var themeTitleLabel: UILabel?
    private weak var themeSubtitleLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupNavigationBar()
        configureAppearance()
        insertInfoCards()
        populateUserInfo()
    }

    // MARK: - Setup

    private func setupViewModel() {
        let photoURL: URL? = {
            guard let str = UserDefaults.standard.string(forKey: UserDefaultsKey.userPhotoURL) else { return nil }
            return URL(string: str)
        }()
        let user = LoginUser(
            uid: UserDefaults.standard.string(forKey: UserDefaultsKey.userUID) ?? "",
            displayName: UserDefaults.standard.string(forKey: UserDefaultsKey.userName) ?? "User",
            email: UserDefaults.standard.string(forKey: UserDefaultsKey.userEmail) ?? "",
            profileImageURL: photoURL
        )
        viewModel = ProfileViewModel(user: user)
        viewModel.delegate = self
    }

    private func setupNavigationBar() {
        title = "Profile"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

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

    private func configureAppearance() {
        view.backgroundColor = AppColors.backgroundPrimary

        // clipsToBounds=true clips both the accent background and the photo to a circle
        avatarContainerView.backgroundColor     = AppColors.accent
        avatarContainerView.layer.cornerRadius  = 50
        avatarContainerView.clipsToBounds       = true

        avatarImageView.contentMode         = .scaleAspectFill
        avatarImageView.clipsToBounds       = true
        avatarImageView.layer.cornerRadius  = 50

        initialsLabel.font          = AppTheme.Font.title1()
        initialsLabel.textColor     = .white
        initialsLabel.textAlignment = .center

        nameLabel.font          = AppTheme.Font.title2()
        nameLabel.textColor     = AppColors.textPrimary
        nameLabel.textAlignment = .center

        emailLabel.font          = AppTheme.Font.body()
        emailLabel.textColor     = AppColors.textSecondary
        emailLabel.textAlignment = .center

        styleLogoutButton()
    }

    // MARK: - Info Cards

    private var currentThemeTitle: String {
        traitCollection.userInterfaceStyle == .dark ? "Dark Mode" : "Light Mode"
    }
    private var currentThemeSubtitle: String {
        traitCollection.userInterfaceStyle == .dark ? "Currently using dark theme" : "Currently using light theme"
    }
    private var currentThemeIcon: String {
        traitCollection.userInterfaceStyle == .dark ? "moon.stars.fill" : "sun.max.fill"
    }

    /// Inserts a card stack between emailLabel and logoutButton in the storyboard hierarchy.
    private func insertInfoCards() {
        let rows: [(String, String, String)] = [
            ("photo.stack.fill",       "Gallery",       "Explore curated photos"),
            ("icloud.and.arrow.down",  "Offline Mode",  "Cached images available anytime"),
            ("magnifyingglass",        "Zoom & Pan",    "Pinch to zoom, drag to pan"),
            (currentThemeIcon,         currentThemeTitle, currentThemeSubtitle),
        ]

        let cards = rows.enumerated().map { index, row -> UIView in
            makeInfoRow(row.0, title: row.1, subtitle: row.2, isThemeCard: index == rows.count - 1)
        }
        let stack = UIStackView(arrangedSubviews: cards)
        stack.axis      = .vertical
        stack.spacing   = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.infoStackView = stack

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.md),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.md),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: logoutButton.topAnchor, constant: -24)
        ])
    }

    private func makeInfoRow(_ icon: String, title: String, subtitle: String, isThemeCard: Bool = false) -> UIView {
        let card = UIView()
        card.backgroundColor    = AppColors.backgroundSecondary
        card.layer.cornerRadius = AppTheme.Radius.md
        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = true
        let selector = isThemeCard ? #selector(themeCardTapped) : #selector(infoCardTapped)
        let tap = UITapGestureRecognizer(target: self, action: selector)
        card.addGestureRecognizer(tap)

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor      = AppColors.accent
        iconView.contentMode    = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text      = title
        titleLabel.font      = AppTheme.Font.callout()
        titleLabel.textColor = AppColors.textPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text      = subtitle
        subtitleLabel.font      = AppTheme.Font.caption()
        subtitleLabel.textColor = AppColors.textSecondary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis    = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        if isThemeCard {
            themeTitleLabel    = titleLabel
            themeSubtitleLabel = subtitleLabel
        }

        card.addSubview(iconView)
        card.addSubview(textStack)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 56),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func styleLogoutButton() {
        logoutButton.layer.cornerRadius = AppTheme.Radius.pill
        logoutButton.backgroundColor    = AppColors.error
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.titleLabel?.font   = AppTheme.Font.headline()
        logoutButton.applyShadow(AppTheme.Shadow.button)
    }

    private func populateUserInfo() {
        let user = viewModel.user
        nameLabel.text  = user.displayName
        emailLabel.text = user.email

        if let url = user.profileImageURL {
            avatarImageView.loadImage(from: url.absoluteString)
            initialsLabel.isHidden = true
        } else {
            initialsLabel.isHidden = false
            initialsLabel.text     = user.displayName.initials
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        themeTitleLabel?.text    = currentThemeTitle
        themeSubtitleLabel?.text = currentThemeSubtitle
    }

    // MARK: - Actions

    @objc private func themeCardTapped() {
        let current = traitCollection.userInterfaceStyle == .dark ? "Dark Mode" : "Light Mode"
        let alert = UIAlertController(
            title: "Appearance: \(current)",
            message: "This card reflects your current system theme. Go to Settings → Display & Brightness to switch between Light and Dark mode — the title here will update automatically.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    @objc private func infoCardTapped() {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "This feature is currently in progress. Stay tuned for updates!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    @IBAction private func logoutButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.viewModel.logout()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - ProfileViewModelDelegate

extension ProfileViewController: ProfileViewModelDelegate {

    func didLogout() {
        // Return to login screen by replacing the root VC
        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
        sceneDelegate.showLoginScreen()
    }

    func didFailLogout(with error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - String Helper

private extension String {
    /// Returns up to two initials from a full name ("John Doe" → "JD", "Alice" → "A").
    var initials: String {
        let parts = components(separatedBy: " ").filter { !$0.isEmpty }
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0).uppercased() }.joined()
    }
}
