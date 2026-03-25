import CoreGraphics
import Foundation

/// Cubic-bezier curve resolver for non-linear interpolation.
public struct SmoothGradientCubic: Equatable, Sendable {
    public let x1: CGFloat
    public let y1: CGFloat
    public let x2: CGFloat
    public let y2: CGFloat

    public init(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) {
        precondition((0...1).contains(x1), "SmoothGradientCubic.x1 must be in [0, 1]")
        precondition((0...1).contains(x2), "SmoothGradientCubic.x2 must be in [0, 1]")
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }

    /// Transforms normalized progress `t` in [0, 1] using cubic-bezier x->y mapping.
    public func transform(_ t: CGFloat) -> CGFloat {
        let x = min(max(t, 0), 1)
        if x == 0 || x == 1 { return x }

        let solvedT = solveParameter(forX: x)
        return min(max(sampleCurveY(solvedT), 0), 1)
    }

    private func sampleCurveX(_ t: CGFloat) -> CGFloat {
        let invT = 1 - t
        let p1 = 3 * invT * invT * t * x1
        let p2 = 3 * invT * t * t * x2
        let p3 = t * t * t
        return p1 + p2 + p3
    }

    private func sampleCurveY(_ t: CGFloat) -> CGFloat {
        let invT = 1 - t
        let p1 = 3 * invT * invT * t * y1
        let p2 = 3 * invT * t * t * y2
        let p3 = t * t * t
        return p1 + p2 + p3
    }

    private func sampleCurveDerivativeX(_ t: CGFloat) -> CGFloat {
        let invT = 1 - t
        return 3 * invT * invT * x1 + 6 * invT * t * (x2 - x1) + 3 * t * t * (1 - x2)
    }

    private func solveParameter(forX x: CGFloat) -> CGFloat {
        var guess = x
        for _ in 0..<8 {
            let currentX = sampleCurveX(guess) - x
            let slope = sampleCurveDerivativeX(guess)
            if abs(slope) < 1e-6 { break }
            guess -= currentX / slope
            if guess <= 0 { return 0 }
            if guess >= 1 { return 1 }
        }

        var low: CGFloat = 0
        var high: CGFloat = 1
        for _ in 0..<20 {
            guess = (low + high) * 0.5
            let currentX = sampleCurveX(guess)
            if currentX < x {
                low = guess
            } else {
                high = guess
            }
        }
        return guess
    }
}

/// Named cubic presets for readability and easy usage.
public enum SmoothGradientCurvePreset: String, CaseIterable, Sendable {
    case high
    case medium
    case low

    public var cubic: SmoothGradientCubic {
        switch self {
        case .high:
            return SmoothGradientCubic(x1: 0.455, y1: 0.03, x2: 0.515, y2: 0.955)
        case .medium:
            return SmoothGradientCubic(x1: 0.645, y1: 0.045, x2: 0.355, y2: 1.0)
        case .low:
            return SmoothGradientCubic(x1: 0.83, y1: 0.0, x2: 0.17, y2: 1.0)
        }
    }

    public var controlPointsDescription: String {
        let c = cubic
        return String(format: "cubic-bezier(%.3f, %.3f, %.3f, %.3f)", c.x1, c.y1, c.x2, c.y2)
    }
}

/// Math helpers for stop sampling and color interpolation.
public enum SmoothGradientMath {
    struct ColorProgress {
        let leftIndex: Int
        let rightIndex: Int
        let t: Double
    }

    public static let minSteps = 2
    public static let maxSteps = 64

    /// Validates and returns steps in supported range [2, 64].
    public static func validatedSteps(_ steps: Int) -> Int {
        precondition((minSteps...maxSteps).contains(steps), "steps must be in [\(minSteps), \(maxSteps)]")
        return steps
    }

    /// Generates evenly spaced stop locations in [0, 1], count equals `steps`.
    public static func sampledLocations(steps: Int) -> [Double] {
        let safeSteps = validatedSteps(steps)
        let maxIndex = Double(safeSteps - 1)
        return (0..<safeSteps).map { Double($0) / maxIndex }
    }

    static func colorProgress(
        at position: Double,
        controlLocations: [Double]
    ) -> ColorProgress? {
        guard controlLocations.count > 1 else { return nil }
        let x = min(max(position, 0), 1)
        let lastIndex = controlLocations.count - 1

        if x <= controlLocations[0] {
            return ColorProgress(leftIndex: 0, rightIndex: 0, t: 0)
        }
        if x >= controlLocations[lastIndex] {
            return ColorProgress(leftIndex: lastIndex, rightIndex: lastIndex, t: 0)
        }

        for idx in 1..<controlLocations.count {
            let left = controlLocations[idx - 1]
            let right = controlLocations[idx]
            if x <= right {
                let dx = right - left
                if dx == 0 {
                    return ColorProgress(leftIndex: idx, rightIndex: idx, t: 0)
                }
                let t = min(max((x - left) / dx, 0), 1)
                return ColorProgress(leftIndex: idx - 1, rightIndex: idx, t: t)
            }
        }

        return ColorProgress(leftIndex: lastIndex, rightIndex: lastIndex, t: 0)
    }
}
