import CoreGraphics
import Testing
@testable import SmoothGradientUIKit

struct SmoothGradientMathTests {
    @Test
    func cubicEndpointsAreStable() {
        for preset in SmoothGradientCurvePreset.allCases {
            let curve = preset.cubic
            #expect(curve.transform(0) == 0)
            #expect(curve.transform(1) == 1)
        }
    }

    @Test
    func cubicOutputIsMonotonicAndInBounds() {
        for preset in SmoothGradientCurvePreset.allCases {
            let curve = preset.cubic
            var previous: CGFloat = 0

            for step in 0...100 {
                let t = CGFloat(step) / 100
                let value = curve.transform(t)
                #expect(value >= 0)
                #expect(value <= 1)
                #expect(value >= previous)
                previous = value
            }
        }
    }

    @Test
    func sampledLocationsHaveExpectedShape() {
        let locations = SmoothGradientMath.sampledLocations(steps: 10)
        #expect(locations.count == 10)
        #expect(locations.first == 0)
        #expect(locations.last == 1)

        for idx in 1..<locations.count {
            #expect(locations[idx] > locations[idx - 1])
        }
    }

    @Test
    func presetCurvesRemainCloseToLegacyAnchors() {
        assertCurveApproximation(
            SmoothGradientCurvePreset.high.cubic,
            anchors: [(0.12, 0.02), (0.24, 0.10), (0.35, 0.22), (0.46, 0.40), (0.57, 0.60), (0.68, 0.78), (0.79, 0.90), (0.90, 0.98)],
            maxError: 0.08,
            rmseLimit: 0.055
        )
        assertCurveApproximation(
            SmoothGradientCurvePreset.medium.cubic,
            anchors: [(0.12, 0.00), (0.24, 0.04), (0.35, 0.15), (0.46, 0.35), (0.57, 0.65), (0.68, 0.85), (0.79, 0.95), (0.90, 0.99)],
            maxError: 0.08,
            rmseLimit: 0.055
        )
        assertCurveApproximation(
            SmoothGradientCurvePreset.low.cubic,
            anchors: [(0.12, 0.00), (0.24, 0.00), (0.35, 0.06), (0.46, 0.28), (0.57, 0.72), (0.68, 0.93), (0.79, 0.99), (0.90, 1.00)],
            maxError: 0.08,
            rmseLimit: 0.055
        )
    }

    @Test
    func presetSeparationMatchesVisualExpectation() {
        let t: CGFloat = 0.57
        let high = SmoothGradientCurvePreset.high.cubic.transform(t)
        let medium = SmoothGradientCurvePreset.medium.cubic.transform(t)
        let low = SmoothGradientCurvePreset.low.cubic.transform(t)
        #expect(high < medium)
        #expect(medium < low)
    }

    @Test
    func colorProgressLocksToLastColorAfterLastLocation() {
        let progress = SmoothGradientMath.colorProgress(
            at: 0.75,
            controlLocations: [0.0, 0.5]
        )
        #expect(progress != nil)
        #expect(progress?.leftIndex == 1)
        #expect(progress?.rightIndex == 1)
    }

    @Test
    func colorProgressUsesSegmentLocalTBeforeLastLocation() {
        let progress = SmoothGradientMath.colorProgress(
            at: 0.25,
            controlLocations: [0.0, 0.5]
        )
        #expect(progress != nil)
        #expect(progress?.leftIndex == 0)
        #expect(progress?.rightIndex == 1)
        assertNearlyEqual(progress?.t ?? -1, 0.5)
    }

    @Test
    func colorProgressRespectsSortedControlLocations() {
        let progress = SmoothGradientMath.colorProgress(
            at: 0.6,
            controlLocations: [0.0, 0.2, 1.0]
        )
        #expect(progress != nil)
        #expect(progress?.leftIndex == 1)
        #expect(progress?.rightIndex == 2)
    }
}

private func assertNearlyEqual(_ lhs: Double, _ rhs: Double, eps: Double = 0.000_001) {
    #expect(abs(lhs - rhs) < eps)
}

private func assertCurveApproximation(
    _ curve: SmoothGradientCubic,
    anchors: [(x: CGFloat, y: CGFloat)],
    maxError: CGFloat,
    rmseLimit: CGFloat
) {
    var sumSquares: CGFloat = 0
    var observedMaxError: CGFloat = 0

    for anchor in anchors {
        let value = curve.transform(anchor.x)
        let error = abs(value - anchor.y)
        sumSquares += error * error
        observedMaxError = max(observedMaxError, error)
    }

    let rmse = sqrt(sumSquares / CGFloat(anchors.count))
    #expect(observedMaxError <= maxError)
    #expect(rmse <= rmseLimit)
}
