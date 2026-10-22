import Foundation

// MARK: - LoginUser

/// Represents the authenticated user returned after a successful Google Sign-In.
/// This is a plain value type — no business logic lives here.
struct LoginUser {
    let uid: String
    let displayName: String
    let email: String
    let profileImageURL: URL?
}
