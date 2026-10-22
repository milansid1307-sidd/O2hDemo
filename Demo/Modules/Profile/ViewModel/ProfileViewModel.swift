import UIKit
import GoogleSignIn

// MARK: - ProfileViewModelDelegate

protocol ProfileViewModelDelegate: AnyObject {
    func didLogout()
    func didFailLogout(with error: Error)
}

// MARK: - ProfileViewModel

@MainActor
final class ProfileViewModel {

    // MARK: Dependencies
    weak var delegate: ProfileViewModelDelegate?
    private let authService: GoogleAuthServiceProtocol
    private let realmManager: RealmManager

    // MARK: User Data
    let user: LoginUser

    // MARK: Init
    init(user: LoginUser,
         authService: GoogleAuthServiceProtocol = GoogleAuthService(),
         realmManager: RealmManager = .shared) {
        self.user         = user
        self.authService  = authService
        self.realmManager = realmManager
    }

    // MARK: - Public API

    func logout() {
        realmManager.clearGalleryCache()
        // Sign out from Google SDK so restorePreviousSignIn() returns nil on next launch
        GIDSignIn.sharedInstance.signOut()
        // Clear all session keys so isLoggedIn returns false
        SessionManager.clearSession()
        delegate?.didLogout()
    }
}

// MARK: - UserDefaults Keys

enum UserDefaultsKey {
    static let loggedInUser = "com.demo.loggedInUser"
    static let userName     = "com.demo.userName"
    static let userEmail    = "com.demo.userEmail"
    static let userUID      = "com.demo.userUID"
    static let userPhotoURL = "com.demo.userPhotoURL"
}
