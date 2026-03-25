import CoreGraphics

/// Gradient axis represented by start and end points in unit coordinates.
public struct SmoothGradientDirection: Equatable, Sendable {
    public let startPoint: CGPoint
    public let endPoint: CGPoint

    /// Creates a direction from explicit unit coordinates.
    public init(startPoint: CGPoint, endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    /// Creates a direction from angle in degrees (0 = left to right).
    public init(angleDegrees: CGFloat) {
        let radians = angleDegrees * .pi / 180
        let dx = cos(radians) * 0.5
        let dy = sin(radians) * 0.5
        self.startPoint = CGPoint(x: 0.5 - dx, y: 0.5 - dy)
        self.endPoint = CGPoint(x: 0.5 + dx, y: 0.5 + dy)
    }

    public static let topToBottom = SmoothGradientDirection(
        startPoint: CGPoint(x: 0.5, y: 0),
        endPoint: CGPoint(x: 0.5, y: 1)
    )

    public static let leftToRight = SmoothGradientDirection(
        startPoint: CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint(x: 1, y: 0.5)
    )

    public static let topLeftToBottomRight = SmoothGradientDirection(
        startPoint: CGPoint(x: 0, y: 0),
        endPoint: CGPoint(x: 1, y: 1)
    )
}

#if canImport(UIKit)
import UIKit

/// Public configuration for `SmoothGradientView`.
public struct SmoothGradientConfiguration {
    public var colors: [UIColor]
    public var locations: [CGFloat]
    public var steps: Int
    public var curve: SmoothGradientCubic
    public var direction: SmoothGradientDirection

    /// - Parameters:
    ///   - colors: Input color keyframes.
    ///   - locations: Per-color locations in [0, 1]. Length mismatch is resolved by taking the minimum count.
    ///   - steps: Sampling count for generated gradient stops. Range is [2, 64]. Default is `10`.
    ///   - curve: Cubic curve resolver. Default is `.high` preset.
    ///   - direction: Gradient direction in unit coordinates.
    public init(
        colors: [UIColor] = [
            UIColor(red: 0.98, green: 0.55, blue: 0.45, alpha: 1),
            UIColor(red: 0.98, green: 0.78, blue: 0.45, alpha: 1),
            UIColor(red: 0.56, green: 0.82, blue: 0.98, alpha: 1)
        ],
        locations: [CGFloat] = [0, 0.5, 1],
        steps: Int = 10,
        curve: SmoothGradientCubic = SmoothGradientCurvePreset.high.cubic,
        direction: SmoothGradientDirection = .topToBottom
    ) {
        self.colors = colors
        self.locations = locations
        self.steps = steps
        self.curve = curve
        self.direction = direction
    }

    /// Convenience initializer using named presets.
    public init(
        colors: [UIColor],
        locations: [CGFloat],
        steps: Int = 10,
        preset: SmoothGradientCurvePreset,
        direction: SmoothGradientDirection = .topToBottom
    ) {
        self.init(
            colors: colors,
            locations: locations,
            steps: steps,
            curve: preset.cubic,
            direction: direction
        )
    }
}
#endif
