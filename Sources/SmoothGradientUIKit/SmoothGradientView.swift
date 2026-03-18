#if canImport(UIKit)
import UIKit

/// UIView wrapper that renders smooth gradients via `CAGradientLayer`.
public final class SmoothGradientView: UIView {
    public override class var layerClass: AnyClass { CAGradientLayer.self }

    /// Current rendering configuration.
    public var configuration: SmoothGradientConfiguration {
        get { storageConfiguration }
        set {
            storageConfiguration = newValue
            applyConfiguration(animated: false, duration: 0, timing: .linear)
        }
    }

    private var storageConfiguration: SmoothGradientConfiguration

    private var gradientLayer: CAGradientLayer {
        guard let layer = self.layer as? CAGradientLayer else {
            preconditionFailure("Expected CAGradientLayer")
        }
        return layer
    }

    public override init(frame: CGRect) {
        self.storageConfiguration = SmoothGradientConfiguration()
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        self.storageConfiguration = SmoothGradientConfiguration()
        super.init(coder: coder)
        commonInit()
    }

    public init(configuration: SmoothGradientConfiguration) {
        self.storageConfiguration = configuration
        super.init(frame: .zero)
        commonInit()
    }

    /// Applies a new configuration, optionally animating the transition.
    public func setConfiguration(
        _ configuration: SmoothGradientConfiguration,
        animated: Bool = true,
        duration: TimeInterval = 0.35,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        self.storageConfiguration = configuration
        applyConfiguration(animated: animated, duration: duration, timing: timing)
    }

    /// Convenience API to update only colors.
    public func setColors(
        _ colors: [UIColor],
        animated: Bool = true,
        duration: TimeInterval = 0.35,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        var next = configuration
        next.colors = colors
        setConfiguration(next, animated: animated, duration: duration, timing: timing)
    }

    /// Convenience API to update only direction.
    public func setDirection(
        _ direction: SmoothGradientDirection,
        animated: Bool = true,
        duration: TimeInterval = 0.35,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        var next = configuration
        next.direction = direction
        setConfiguration(next, animated: animated, duration: duration, timing: timing)
    }

    private func commonInit() {
        isOpaque = false
        applyConfiguration(animated: false, duration: 0, timing: .linear)
    }

    private func applyConfiguration(
        animated: Bool,
        duration: TimeInterval,
        timing: CAMediaTimingFunctionName
    ) {
        let payload = resolvedPayload(for: configuration)
        let layer = gradientLayer

        if animated {
            animate(layer: layer, keyPath: "colors", from: layer.colors, to: payload.colors, duration: duration, timing: timing)
            animate(layer: layer, keyPath: "locations", from: layer.locations, to: payload.locations, duration: duration, timing: timing)
            animate(layer: layer, keyPath: "startPoint", from: NSValue(cgPoint: layer.startPoint), to: NSValue(cgPoint: payload.startPoint), duration: duration, timing: timing)
            animate(layer: layer, keyPath: "endPoint", from: NSValue(cgPoint: layer.endPoint), to: NSValue(cgPoint: payload.endPoint), duration: duration, timing: timing)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.colors = payload.colors
        layer.locations = payload.locations
        layer.startPoint = payload.startPoint
        layer.endPoint = payload.endPoint
        CATransaction.commit()
    }

    private func animate(
        layer: CAGradientLayer,
        keyPath: String,
        from: Any?,
        to: Any?,
        duration: TimeInterval,
        timing: CAMediaTimingFunctionName
    ) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: timing)
        animation.isRemovedOnCompletion = true
        layer.add(animation, forKey: keyPath)
    }

    private func resolvedPayload(for configuration: SmoothGradientConfiguration) -> GradientPayload {
        let safeSteps = SmoothGradientMath.clampedSteps(configuration.steps)

        let useFallback = SmoothGradientMath.shouldUseLinearFallback(
            mode: configuration.fallbackMode,
            colorCount: configuration.colors.count,
            steps: safeSteps,
            lowPowerModeEnabled: false
        )

        let baseColors = configuration.colors.isEmpty ? [UIColor.clear, UIColor.clear] : configuration.colors

        let colors: [UIColor]
        let locations: [Double]

        if useFallback {
            colors = baseColors.count == 1 ? [baseColors[0], baseColors[0]] : baseColors
            locations = SmoothGradientMath.evenlySpacedLocations(count: colors.count)
        } else {
            let sampledLocations = SmoothGradientMath.sampledLocations(steps: safeSteps, smoothing: configuration.smoothing)
            colors = sampledLocations.map { sampleColor(in: baseColors, position: $0) }
            locations = sampledLocations
        }

        return GradientPayload(
            colors: colors.map(\.cgColor),
            locations: locations.map(NSNumber.init(value:)),
            startPoint: configuration.direction.startPoint,
            endPoint: configuration.direction.endPoint
        )
    }

    private func sampleColor(in colors: [UIColor], position: Double) -> UIColor {
        guard colors.count > 1 else { return colors.first ?? .clear }

        let clampedPosition = min(max(position, 0), 1)
        let segmentCount = colors.count - 1
        let scaled = clampedPosition * Double(segmentCount)
        let lowerIndex = min(Int(floor(scaled)), segmentCount - 1)
        let upperIndex = lowerIndex + 1
        let localT = CGFloat(scaled - Double(lowerIndex))

        let a = rgba(from: colors[lowerIndex])
        let b = rgba(from: colors[upperIndex])

        return UIColor(
            red: a.r + (b.r - a.r) * localT,
            green: a.g + (b.g - a.g) * localT,
            blue: a.b + (b.b - a.b) * localT,
            alpha: a.a + (b.a - a.a) * localT
        )
    }

    private func rgba(from color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        }

        guard let components = color.cgColor.components else {
            return (0, 0, 0, 0)
        }

        if components.count == 2 {
            let value = components[0]
            return (value, value, value, components[1])
        }

        if components.count >= 4 {
            return (components[0], components[1], components[2], components[3])
        }

        return (0, 0, 0, 0)
    }
}

private struct GradientPayload {
    let colors: [CGColor]
    let locations: [NSNumber]
    let startPoint: CGPoint
    let endPoint: CGPoint
}
#endif
