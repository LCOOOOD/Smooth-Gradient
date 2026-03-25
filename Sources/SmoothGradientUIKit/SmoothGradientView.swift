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

    /// Convenience API to update only stop locations.
    public func setLocations(
        _ locations: [CGFloat],
        animated: Bool = true,
        duration: TimeInterval = 0.35,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        var next = configuration
        next.locations = locations
        setConfiguration(next, animated: animated, duration: duration, timing: timing)
    }

    /// Convenience API to update only curve.
    public func setCurve(
        _ curve: SmoothGradientCubic,
        animated: Bool = true,
        duration: TimeInterval = 0.35,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        var next = configuration
        next.curve = curve
        setConfiguration(next, animated: animated, duration: duration, timing: timing)
    }

    /// Convenience API to update only named curve preset.
    public func setCurvePreset(
        _ preset: SmoothGradientCurvePreset,
        animated: Bool = true,
        duration: TimeInterval = 0.35,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        setCurve(preset.cubic, animated: animated, duration: duration, timing: timing)
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
        precondition(configuration.colors.count >= 2, "SmoothGradientConfiguration.colors must contain at least 2 colors")
        precondition(configuration.locations.count >= 2, "SmoothGradientConfiguration.locations must contain at least 2 values")

        let safeSteps = SmoothGradientMath.validatedSteps(configuration.steps)
        let controls = normalizedControls(colors: configuration.colors, locations: configuration.locations)
        precondition(controls.count >= 2, "Matched color/location control points must contain at least 2 values")

        let sampledLocations = SmoothGradientMath.sampledLocations(steps: safeSteps)
        let sampledColors = sampledLocations.map { position in
            sampledColor(
                at: position,
                controls: controls,
                curve: configuration.curve
            )
        }

        return GradientPayload(
            colors: sampledColors.map(\.cgColor),
            locations: sampledLocations.map(NSNumber.init(value:)),
            startPoint: configuration.direction.startPoint,
            endPoint: configuration.direction.endPoint
        )
    }

    private func normalizedControls(
        colors: [UIColor],
        locations: [CGFloat]
    ) -> [(color: UIColor, location: Double)] {
        let count = min(colors.count, locations.count)
        guard count > 0 else { return [] }

        var pairs = [(color: UIColor, location: Double)]()
        pairs.reserveCapacity(count)

        for idx in 0..<count {
            let clamped = min(max(Double(locations[idx]), 0), 1)
            pairs.append((colors[idx], clamped))
        }

        return pairs.sorted { $0.location < $1.location }
    }

    private func sampledColor(
        at position: Double,
        controls: [(color: UIColor, location: Double)],
        curve: SmoothGradientCubic
    ) -> UIColor {
        let controlLocations = controls.map(\.location)
        guard let progress = SmoothGradientMath.colorProgress(at: position, controlLocations: controlLocations) else {
            preconditionFailure("Expected at least two control locations")
        }

        if progress.leftIndex == progress.rightIndex {
            return controls[progress.leftIndex].color
        }

        let leftColor = controls[progress.leftIndex].color
        let rightColor = controls[progress.rightIndex].color
        return sampleColorPair(
            from: leftColor,
            to: rightColor,
            t: Double(curve.transform(CGFloat(progress.t)))
        )
    }

    private func sampleColorPair(
        from leftColor: UIColor,
        to rightColor: UIColor,
        t: Double
    ) -> UIColor {
        let a = rgba(from: leftColor)
        let b = rgba(from: rightColor)
        let localT = CGFloat(min(max(t, 0), 1))

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
