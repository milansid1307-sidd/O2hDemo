import UIKit

// MARK: - Shimmer Animation

private enum ShimmerKey {
    static let layerName = "shimmerLayer"
    static let animationKey = "shimmerAnimation"
}

extension UIView {

    /// Adds an animated shimmer overlay to mimic content loading.
    /// Call `stopShimmering()` once real content is ready.
    func startShimmering() {
        // Prevent duplicate layers
        stopShimmering()

        let shimmerLayer = CAGradientLayer()
        shimmerLayer.name = ShimmerKey.layerName
        shimmerLayer.frame = bounds
        shimmerLayer.cornerRadius = layer.cornerRadius

        // Three-band gradient: base → highlight → base
        shimmerLayer.colors = [
            AppColors.shimmerBase.cgColor,
            AppColors.shimmerHighlight.cgColor,
            AppColors.shimmerBase.cgColor
        ]

        // Angled sweep left-to-right
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations  = [-1.0, -0.5, 0.0]

        layer.addSublayer(shimmerLayer)

        // Animate the gradient locations across the view
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue   = [1.0,  1.5,  2.0]
        animation.duration  = 1.4
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        shimmerLayer.add(animation, forKey: ShimmerKey.animationKey)
    }

    /// Removes the shimmer overlay and fades in the real content.
    func stopShimmering() {
        layer.sublayers?
            .filter { $0.name == ShimmerKey.layerName }
            .forEach { $0.removeFromSuperlayer() }
    }

    /// Updates the shimmer layer frame — call from `layoutSubviews` if the view resizes.
    func updateShimmerFrame() {
        layer.sublayers?
            .filter { $0.name == ShimmerKey.layerName }
            .forEach { $0.frame = bounds }
    }
}
