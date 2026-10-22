import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Show login first, then silently try to restore a Google session in the background.
        // This avoids a flash of the tab bar before token validation completes.
        let splash = SplashViewController()
        window.rootViewController = splash
        window.makeKeyAndVisible()

        splash.onFinished = { [weak self] in
            guard let self else { return }
            if SessionManager.isLoggedIn {
                self.showMainFlow()
            } else {
                self.showLoginScreen()
            }
        }

        // Attempt silent sign-in restore while splash plays
        Task {
            if let user = try? await GoogleAuthService().restorePreviousSignIn() {
                SessionManager.saveSession(user: user)
            }
        }
    }

    // MARK: - Navigation Helpers (called by ViewControllers too)

    /// Transitions to the main tab bar after a successful login.
    func showMainFlow() {
        guard let window else { return }
        let tabBar = makeMainTabBar()
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = tabBar
        }
    }

    /// Transitions back to the login screen after logout.
    func showLoginScreen() {
        guard let window else { return }
        let login = makeLoginViewController()
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = login
        }
    }

    // MARK: - Factory Methods

    private func makeLoginViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "LoginViewController")
    }

    private func makeMainTabBar() -> UITabBarController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // Gallery tab
        let galleryVC = storyboard.instantiateViewController(withIdentifier: "GalleryViewController")
        let galleryNav = UINavigationController(rootViewController: galleryVC)
        galleryNav.tabBarItem = UITabBarItem(title: "Gallery",
                                             image: UIImage(systemName: "photo.stack"),
                                             selectedImage: UIImage(systemName: "photo.stack.fill"))

        // Profile tab
        let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(title: "Profile",
                                             image: UIImage(systemName: "person.crop.circle"),
                                             selectedImage: UIImage(systemName: "person.crop.circle.fill"))

        let tabBar = UITabBarController()
        tabBar.viewControllers = [galleryNav, profileNav]
        return tabBar
    }
}

// MARK: - SessionManager

/// Lightweight session state backed by UserDefaults.
/// Google Sign-In token management (refresh, revoke) should be added here.
enum SessionManager {

    static var isLoggedIn: Bool {
        UserDefaults.standard.bool(forKey: "com.demo.isLoggedIn")
    }

    static func saveSession(user: LoginUser) {
        let ud = UserDefaults.standard
        ud.set(true,                                forKey: "com.demo.isLoggedIn")
        ud.set(user.uid,                            forKey: UserDefaultsKey.userUID)
        ud.set(user.displayName,                    forKey: UserDefaultsKey.userName)
        ud.set(user.email,                          forKey: UserDefaultsKey.userEmail)
        ud.set(user.profileImageURL?.absoluteString, forKey: UserDefaultsKey.userPhotoURL)
    }

    static func clearSession() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "com.demo.isLoggedIn")
        ud.removeObject(forKey: UserDefaultsKey.userUID)
        ud.removeObject(forKey: UserDefaultsKey.userName)
        ud.removeObject(forKey: UserDefaultsKey.userEmail)
        ud.removeObject(forKey: UserDefaultsKey.userPhotoURL)
    }
}
