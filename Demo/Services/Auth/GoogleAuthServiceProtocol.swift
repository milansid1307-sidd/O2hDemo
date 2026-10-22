import UIKit

// MARK: - GoogleAuthServiceProtocol

/// Abstraction over the Google Sign-In flow.
/// Keeps LoginViewModel testable without a real SDK dependency.
protocol GoogleAuthServiceProtocol {
    func signIn(from viewController: UIViewController) async throws -> LoginUser
}
