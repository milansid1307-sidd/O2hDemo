import UIKit
import ImageIO

final class SplashViewController: UIViewController {

    var onFinished: (() -> Void)?

    private let gifImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(gifImageView)
        NSLayoutConstraint.activate([
            gifImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gifImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gifImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            gifImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
        ])
        loadGIF()
    }

    private func loadGIF() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let name = isDark ? "O2h_splash_dark" : "O2h_splash_light"

        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let (image, duration) = animatedImage(from: url) else {
            onFinished?()
            return
        }

        gifImageView.image = image
        gifImageView.startAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.onFinished?()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            loadGIF()
        }
    }
}

// MARK: - GIF Decoder

private func animatedImage(from url: URL) -> (UIImage, TimeInterval)? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

    let count = CGImageSourceGetCount(source)
    var frames: [UIImage] = []
    var totalDuration: TimeInterval = 0

    for i in 0..<count {
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
        let frameDuration = gifFrameDuration(source: source, index: i)
        totalDuration += frameDuration

        // Repeat each frame proportionally (UIImage.animatedImage uses equal frame time).
        // We normalise to 1/100s slots.
        let repeatCount = max(1, Int(frameDuration * 100))
        for _ in 0..<repeatCount {
            frames.append(UIImage(cgImage: cgImage))
        }
    }

    guard !frames.isEmpty else { return nil }
    let animated = UIImage.animatedImage(with: frames, duration: totalDuration)
    return animated.map { ($0, totalDuration) }
}

private func gifFrameDuration(source: CGImageSource, index: Int) -> TimeInterval {
    guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
          let gifProps = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
        return 0.1
    }
    let delay = (gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval)
             ?? (gifProps[kCGImagePropertyGIFDelayTime as String] as? TimeInterval)
             ?? 0.1
    return delay < 0.011 ? 0.1 : delay
}
