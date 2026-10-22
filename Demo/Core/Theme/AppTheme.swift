import UIKit

// MARK: - AppTheme
// Design system constants — spacing, corner radius, typography, shadow.
// Centralised so a single change ripples across every screen.

enum AppTheme {

    // MARK: Spacing
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Corner Radius
    enum Radius {
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 20    // gallery cell — visibly rounded
        static let pill: CGFloat = 26   // half of standard button height (52 / 2)
    }

    // MARK: Typography
    enum Font {
        static func largeTitle()    -> UIFont { .systemFont(ofSize: 34, weight: .bold) }
        static func title1()        -> UIFont { .systemFont(ofSize: 28, weight: .bold) }
        static func title2()        -> UIFont { .systemFont(ofSize: 22, weight: .semibold) }
        static func headline()      -> UIFont { .systemFont(ofSize: 17, weight: .semibold) }
        static func body()          -> UIFont { .systemFont(ofSize: 16, weight: .regular) }
        static func callout()       -> UIFont { .systemFont(ofSize: 15, weight: .regular) }
        static func subheadline()   -> UIFont { .systemFont(ofSize: 15, weight: .medium) }
        static func footnote()      -> UIFont { .systemFont(ofSize: 13, weight: .regular) }
        static func caption()       -> UIFont { .systemFont(ofSize: 12, weight: .regular) }
    }

    // MARK: Shadow
    struct Shadow {
        let color: UIColor
        let offset: CGSize
        let opacity: Float
        let radius: CGFloat

        static let card = Shadow(
            color: .black,
            offset: CGSize(width: 0, height: 2),
            opacity: 0.10,
            radius: 6
        )

        static let button = Shadow(
            color: .black,
            offset: CGSize(width: 0, height: 2),
            opacity: 0.12,
            radius: 4
        )
    }

    // MARK: Animation
    enum Animation {
        /// Standard spring for interactive elements (button press, cell selection)
        static let springDamping:   CGFloat = 0.7
        static let springVelocity:  CGFloat = 0.5
        static let standardDuration: TimeInterval = 0.3
        static let quickDuration:    TimeInterval = 0.15
    }

    // MARK: Tab Bar Appearance
    static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.backgroundPrimary

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor    = AppColors.tabBarTint
        itemAppearance.selected.titleTextAttributes   = [.foregroundColor: AppColors.tabBarTint]
        itemAppearance.normal.iconColor      = AppColors.tabBarUnselect
        itemAppearance.normal.titleTextAttributes     = [.foregroundColor: AppColors.tabBarUnselect]

        appearance.stackedLayoutAppearance   = itemAppearance
        appearance.inlineLayoutAppearance    = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: Navigation Bar Appearance
    static func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.backgroundPrimary
        appearance.titleTextAttributes     = [.foregroundColor: AppColors.textPrimary,
                                              .font: Font.headline()]
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColors.textPrimary,
                                               .font: Font.largeTitle()]

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor            = AppColors.accent
    }
}

// MARK: - UIView Shadow Helper

extension UIView {
    /// Applies a pre-defined shadow style to the layer.
    func applyShadow(_ style: AppTheme.Shadow) {
        layer.shadowColor   = style.color.cgColor
        layer.shadowOffset  = style.offset
        layer.shadowOpacity = style.opacity
        layer.shadowRadius  = style.radius
        layer.masksToBounds = false
    }
}
