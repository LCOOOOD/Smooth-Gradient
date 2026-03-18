import Foundation

/// Legacy easing enum kept for source compatibility.
/// Prefer `SmoothGradientSmoothing`.
@available(*, deprecated, message: "Use SmoothGradientSmoothing instead.")
public enum SmoothEasing: String, CaseIterable, Sendable {
    case easeOutQuad
    case easeInOutQuad
    case easeOutCubic
    case easeInOutCubic
    case easeOutQuint
    case easeInOutQuint
    case easeOutExpo
    case easeInOutExpo
    case easeOutCirc
    case easeInOutCirc

    /// Maps legacy easing values to the 3 smoothing tiers.
    public var smoothing: SmoothGradientSmoothing {
        switch self {
        case .easeOutQuad, .easeInOutQuad:
            return .high
        case .easeOutCubic, .easeInOutCubic:
            return .medium
        case .easeOutQuint, .easeInOutQuint, .easeOutExpo, .easeInOutExpo, .easeOutCirc, .easeInOutCirc:
            return .low
        }
    }
}

/// Smoothing quality tier used to sample gradient stop locations.
/// - `high` maps to easeInOutQuad
/// - `medium` maps to easeInOutCubic
/// - `low` maps to easeInOutQuint
public enum SmoothGradientSmoothing: String, CaseIterable, Sendable {
    case high
    case medium
    case low

    /// Transforms normalized progress `t` in [0, 1] to eased progress.
    public func transform(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)

        switch self {
        case .high:
            return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
        case .medium:
            return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
        case .low:
            return x < 0.5 ? 16 * pow(x, 5) : 1 - pow(-2 * x + 2, 5) / 2
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

    /// Deprecated compatibility overload.
    @available(*, deprecated, message: "Use sampledLocations(steps:smoothing:) instead.")
    public static func sampledLocations(steps: Int, easing: SmoothEasing) -> [Double] {
        sampledLocations(steps: steps, smoothing: easing.smoothing)
    }

    /// Returns whether the renderer should use plain linear gradient.
    public static func shouldUseLinearFallback(
        mode: SmoothGradientFallbackMode,
        colorCount: Int,
        steps: Int,
        lowPowerModeEnabled: Bool
    ) -> Bool {
        if mode == .linearOnly { return true }
        if colorCount < 2 { return true }
        if clampedSteps(steps) <= 2 { return true }
        if lowPowerModeEnabled { return true }
        return false
    }

    static func evenlySpacedLocations(count: Int) -> [Double] {
        guard count > 1 else { return [0, 1] }
        let maxIndex = Double(count - 1)
        return (0..<count).map { Double($0) / maxIndex }
    }
}
