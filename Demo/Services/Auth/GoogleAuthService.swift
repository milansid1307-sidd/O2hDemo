import UIKit
import GoogleSignIn

// MARK: - GoogleAuthService

/// Wraps GIDSignIn and maps its result to our domain model (LoginUser).
/// If the SDK isn't added yet, Xcode will error here — follow README setup steps.
final class GoogleAuthService: GoogleAuthServiceProtocol {

    func signIn(from viewController: UIViewController) async throws -> LoginUser {
        // GIDSignIn.signIn is callback-based; wrap it in a continuation for async/await
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let user    = result?.user,
                          let profile = user.profile else {
                        continuation.resume(throwing: AuthError.missingProfile)
                        return
                    }

                    let loginUser = LoginUser(
                        uid: user.userID ?? UUID().uuidString,
                        displayName: profile.name,
                        email: profile.email,
                        profileImageURL: profile.imageURL(withDimension: 200)
                    )
                    continuation.resume(returning: loginUser)
                }
            }
        }
    }

    func restorePreviousSignIn() async throws -> LoginUser {
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let user    = user,
                      let profile = user.profile else {
                    continuation.resume(throwing: AuthError.noSavedSession)
                    return
                }
                let loginUser = LoginUser(
                    uid: user.userID ?? UUID().uuidString,
                    displayName: profile.name,
                    email: profile.email,
                    profileImageURL: profile.imageURL(withDimension: 200)
                )
                continuation.resume(returning: loginUser)
            }
        }
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case missingProfile
    case noSavedSession

    var errorDescription: String? {
        switch self {
        case .missingProfile:  return "Google account profile data is unavailable."
        case .noSavedSession:  return "No previous sign-in session found."
        }
    }
}
