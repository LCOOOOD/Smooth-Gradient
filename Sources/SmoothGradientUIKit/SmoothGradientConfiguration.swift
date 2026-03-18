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
    public var steps: Int
    public var smoothing: SmoothGradientSmoothing
    public var direction: SmoothGradientDirection
    public var fallbackMode: SmoothGradientFallbackMode

    /// - Parameters:
    ///   - colors: Input color keyframes. At least two colors are recommended.
    ///   - steps: Sampling count for generated gradient stops. Default is `10`.
    ///   - smoothing: Smoothing tier. Default is `.high`.
    ///   - direction: Gradient direction in unit coordinates.
    ///   - fallbackMode: Fallback strategy for linear gradient.
    public init(
        colors: [UIColor] = [
            UIColor(red: 0.98, green: 0.55, blue: 0.45, alpha: 1),
            UIColor(red: 0.98, green: 0.78, blue: 0.45, alpha: 1),
            UIColor(red: 0.56, green: 0.82, blue: 0.98, alpha: 1)
        ],
        steps: Int = 10,
        smoothing: SmoothGradientSmoothing = .high,
        direction: SmoothGradientDirection = .topToBottom,
        fallbackMode: SmoothGradientFallbackMode = .automatic
    ) {
        self.colors = colors
        self.steps = steps
        self.smoothing = smoothing
        self.direction = direction
        self.fallbackMode = fallbackMode
    }
}
#endif
