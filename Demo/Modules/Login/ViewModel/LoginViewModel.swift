import UIKit

// MARK: - LoginViewModelDelegate

/// View adopts this to react to state changes driven by the ViewModel.
/// Keeping it delegate-based avoids Combine overhead for a simple auth flow.
protocol LoginViewModelDelegate: AnyObject {
    func loginDidStart()
    func loginDidSucceed(user: LoginUser)
    func loginDidFail(with error: Error)
}

// MARK: - LoginViewModel

/// Owns the sign-in business logic and exposes a clean API to the View.
/// The authService dependency is injected, so this is unit-testable in isolation.
@MainActor
final class LoginViewModel {

    // MARK: Dependencies
    weak var delegate: LoginViewModelDelegate?
    private let authService: GoogleAuthServiceProtocol

    // MARK: Init
    init(authService: GoogleAuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: Public API

    /// Kicks off the Google Sign-In flow using the provided presenting view controller.
    func signInWithGoogle(from viewController: UIViewController) {
        delegate?.loginDidStart()

        Task {
            do {
                let user = try await authService.signIn(from: viewController)
                delegate?.loginDidSucceed(user: user)
            } catch {
                delegate?.loginDidFail(with: error)
            }
        }
    }
}
