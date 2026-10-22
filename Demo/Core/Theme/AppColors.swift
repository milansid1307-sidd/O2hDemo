import UIKit

// MARK: - AppColors
// All colour tokens live here. Add to this enum; never hardcode hex values in view files.
// Every token automatically resolves to light or dark variant based on UITraitCollection.

enum AppColors {

    // MARK: Brand
    /// Primary accent — used for buttons, active tabs, and highlighted elements
    static let accent = UIColor(light: UIColor(hex: "#4285F4"), dark: UIColor(hex: "#5B9EFF"))

    // MARK: Backgrounds
    static let backgroundPrimary   = UIColor.systemBackground
    static let backgroundSecondary = UIColor.secondarySystemBackground
    static let backgroundGrouped   = UIColor.systemGroupedBackground

    // MARK: Surface / Card
    static let surface = UIColor(light: .white, dark: UIColor(hex: "#1C1C1E"))
    static let surfaceElevated = UIColor(light: UIColor(hex: "#F2F2F7"), dark: UIColor(hex: "#2C2C2E"))

    // MARK: Text
    static let textPrimary   = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let textTertiary  = UIColor.tertiaryLabel

    // MARK: Separator / Border
    static let separator = UIColor.separator
    static let border = UIColor(light: UIColor(hex: "#E0E0E0"), dark: UIColor(hex: "#3A3A3C"))
    /// Cell border: black in light mode, white in dark mode
    static let cellBorder = UIColor(light: UIColor.black, dark: UIColor.white)

    // MARK: Shimmer
    static let shimmerBase      = UIColor(light: UIColor(hex: "#E8E8E8"), dark: UIColor(hex: "#2A2A2A"))
    static let shimmerHighlight = UIColor(light: UIColor(hex: "#F5F5F5"), dark: UIColor(hex: "#3D3D3D"))

    // MARK: Semantic
    static let error   = UIColor.systemRed
    static let success = UIColor.systemGreen
    static let warning = UIColor.systemOrange

    // MARK: Tab Bar
    static let tabBarTint     = UIColor(light: UIColor(hex: "#4285F4"), dark: UIColor(hex: "#5B9EFF"))
    static let tabBarUnselect = UIColor.tertiaryLabel
}

// MARK: - UIColor Convenience

extension UIColor {

    /// Creates a colour that adapts between light and dark trait environments.
    convenience init(light: UIColor, dark: UIColor) {
        self.init { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    /// Initialises a UIColor from a CSS hex string (e.g. "#4285F4" or "4285F4").
    convenience init(hex: String) {
        var sanitised = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitised = sanitised.hasPrefix("#") ? String(sanitised.dropFirst()) : sanitised

        var rgb: UInt64 = 0
        Scanner(string: sanitised).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
        let b = CGFloat(rgb & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
