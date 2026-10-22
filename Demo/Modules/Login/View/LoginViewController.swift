import UIKit

// MARK: - LoginViewController

/// Entry point for the authentication flow.
/// All constraints are in Main.storyboard — this file wires up logic only.
final class LoginViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var appTitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var googleSignInButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    private var viewModel: LoginViewModel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        configureAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }

    // MARK: - Setup

    private func setupViewModel() {
        viewModel = LoginViewModel(authService: GoogleAuthService())
        viewModel.delegate = self
    }

    private func configureAppearance() {
        view.backgroundColor = AppColors.backgroundPrimary

        logoImageView.image = UIImage(systemName: "photo.stack.fill")
        logoImageView.tintColor = AppColors.accent
        logoImageView.contentMode = .scaleAspectFit

        appTitleLabel.font = AppTheme.Font.largeTitle()
        appTitleLabel.textColor = AppColors.textPrimary

        subtitleLabel.font = AppTheme.Font.body()
        subtitleLabel.textColor = AppColors.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        activityIndicator.hidesWhenStopped = true

        styleGoogleButton()

        // Elements start invisible — animated in viewDidAppear
        [logoImageView, appTitleLabel, subtitleLabel, googleSignInButton].forEach {
            $0?.alpha = 0
            $0?.transform = CGAffineTransform(translationX: 0, y: 24)
        }
    }

    private func styleGoogleButton() {
        googleSignInButton.layer.cornerRadius = AppTheme.Radius.pill
        googleSignInButton.layer.borderWidth  = 1
        googleSignInButton.layer.borderColor  = AppColors.border.cgColor
        googleSignInButton.backgroundColor    = AppColors.surface
        googleSignInButton.setTitleColor(AppColors.textPrimary, for: .normal)
        googleSignInButton.titleLabel?.font   = AppTheme.Font.subheadline()
        googleSignInButton.clipsToBounds      = false
        googleSignInButton.applyShadow(AppTheme.Shadow.button)
    }

    // MARK: - Entrance Animation

    private func animateEntrance() {
        let elements: [UIView?] = [logoImageView, appTitleLabel, subtitleLabel, googleSignInButton]
        elements.enumerated().forEach { index, view in
            UIView.animate(
                withDuration: AppTheme.Animation.standardDuration,
                delay: Double(index) * 0.10,
                usingSpringWithDamping: AppTheme.Animation.springDamping,
                initialSpringVelocity: AppTheme.Animation.springVelocity
            ) {
                view?.alpha = 1
                view?.transform = .identity
            }
        }
    }

    // MARK: - IBActions

    @IBAction private func googleSignInButtonTapped(_ sender: UIButton) {
        // Spring press feedback
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        viewModel.signInWithGoogle(from: self)
    }
}

// MARK: - LoginViewModelDelegate

extension LoginViewController: LoginViewModelDelegate {

    func loginDidStart() {
        googleSignInButton.isEnabled = false
        activityIndicator.startAnimating()
    }

    func loginDidSucceed(user: LoginUser) {
        activityIndicator.stopAnimating()
        googleSignInButton.isEnabled = true

        // Persist session so the app reopens directly to the gallery
        SessionManager.saveSession(user: user)

        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
        sceneDelegate.showMainFlow()
    }

    func loginDidFail(with error: Error) {
        activityIndicator.stopAnimating()
        googleSignInButton.isEnabled = true

        let alert = UIAlertController(
            title: "Sign-In Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
