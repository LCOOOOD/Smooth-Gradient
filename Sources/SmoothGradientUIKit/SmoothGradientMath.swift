import Foundation

/// Smoothing quality tier used to sample gradient stop locations.
/// Curves are fitted from the original chart samples.
public enum SmoothGradientSmoothing: String, CaseIterable, Sendable {
    case high
    case medium
    case low

    /// Transforms normalized progress `t` in [0, 1] to eased progress.
    public func transform(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        let points = anchorPoints
        if x <= points[0].x { return points[0].y }
        if x >= points[points.count - 1].x { return points[points.count - 1].y }

        for idx in 1..<points.count {
            let left = points[idx - 1]
            let right = points[idx]
            if x <= right.x {
                let dx = right.x - left.x
                if dx == 0 { return right.y }
                let ratio = (x - left.x) / dx
                return left.y + (right.y - left.y) * ratio
            }
        }

        return points[points.count - 1].y
    }

    private var anchorPoints: [(x: Double, y: Double)] {
        switch self {
        case .high:
            return [
                (0.00, 0.00),
                (0.01, 0.00), (0.12, 0.02), (0.24, 0.10), (0.35, 0.22), (0.46, 0.40),
                (0.57, 0.60), (0.68, 0.78), (0.79, 0.90), (0.90, 0.98), (1.00, 1.00),
            ]
        case .medium:
            return [
                (0.00, 0.00),
                (0.01, 0.00), (0.12, 0.00), (0.24, 0.04), (0.35, 0.15), (0.46, 0.35),
                (0.57, 0.65), (0.68, 0.85), (0.79, 0.95), (0.90, 0.99), (1.00, 1.00),
            ]
        case .low:
            return [
                (0.00, 0.00),
                (0.01, 0.00), (0.12, 0.00), (0.24, 0.00), (0.35, 0.06), (0.46, 0.28),
                (0.57, 0.72), (0.68, 0.93), (0.79, 0.99), (0.90, 1.00), (1.00, 1.00),
            ]
        }
    }
}

/// Controls whether smooth sampling or plain linear gradient is used.
public enum SmoothGradientFallbackMode: Equatable {
    case automatic
    case linearOnly
}

/// Math helpers for stop sampling and fallback decisions.
public enum SmoothGradientMath {
    struct ColorProgress {
        let leftIndex: Int
        let rightIndex: Int
        let t: Double
    }

    /// Minimum supported number of sampled stops.
    public static let minSteps = 2
    /// Maximum supported number of sampled stops.
    public static let maxSteps = 64

    /// Clamps `steps` to supported range [2, 64].
    public static func clampedSteps(_ steps: Int) -> Int {
        min(max(steps, minSteps), maxSteps)
    }

    /// Generates eased stop locations in [0, 1], count equals clamped `steps`.
    public static func sampledLocations(steps: Int, smoothing: SmoothGradientSmoothing) -> [Double] {
        let safeSteps = clampedSteps(steps)
        guard safeSteps > 1 else { return [0, 1] }

        let lastIndex = safeSteps - 1
        var values = [Double]()
        values.reserveCapacity(safeSteps)

        for idx in 0..<safeSteps {
            let t = Double(idx) / Double(lastIndex)
            values.append(smoothing.transform(t))
        }

        values[0] = 0
        values[lastIndex] = 1
        return values
    }

    /// Returns whether the renderer should use plain linear gradient.
    public static func shouldUseLinearFallback(
        mode: SmoothGradientFallbackMode,
        colorCount: Int,
        steps: Int,
        lowPowerModeEnabled: Bool
    ) -> Bool {
        _ = lowPowerModeEnabled
        if mode == .linearOnly { return true }
        if colorCount < 2 { return true }
        if clampedSteps(steps) <= 2 { return true }
        return false
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

    static func evenlySpacedLocations(count: Int) -> [Double] {
        guard count > 1 else { return [0, 1] }
        let maxIndex = Double(count - 1)
        return (0..<count).map { Double($0) / maxIndex }
    }
}
