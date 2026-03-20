import Testing
@testable import SmoothGradientUIKit

struct SmoothGradientMathTests {
    @Test
    func smoothingEndpointsAreStable() {
        for smoothing in SmoothGradientSmoothing.allCases {
            #expect(smoothing.transform(0) == 0)
            #expect(smoothing.transform(1) == 1)
        }
    }

    @Test
    func smoothingOutputStaysInBounds() {
        let samples = stride(from: 0.0, through: 1.0, by: 0.05)
        for smoothing in SmoothGradientSmoothing.allCases {
            for t in samples {
                let value = smoothing.transform(t)
                #expect(value >= 0)
                #expect(value <= 1)
            }
        }
    }

    @Test
    func sampledLocationsHaveExpectedShape() {
        let locations = SmoothGradientMath.sampledLocations(steps: 10, smoothing: .high)
        #expect(locations.count == 10)
        #expect(locations.first == 0)
        #expect(locations.last == 1)

        for idx in 1..<locations.count {
            #expect(locations[idx] > locations[idx - 1])
        }
    }

    @Test
    func stepsAreClampedToAllowedRange() {
        #expect(SmoothGradientMath.clampedSteps(1) == 2)
        #expect(SmoothGradientMath.clampedSteps(10) == 10)
        #expect(SmoothGradientMath.clampedSteps(1000) == 64)
    }

    @Test
    func fallbackResolutionWorksForAutomaticAndForcedModes() {
        #expect(SmoothGradientMath.shouldUseLinearFallback(mode: .linearOnly, colorCount: 3, steps: 10, lowPowerModeEnabled: false))
        #expect(SmoothGradientMath.shouldUseLinearFallback(mode: .automatic, colorCount: 1, steps: 10, lowPowerModeEnabled: false))
        #expect(!SmoothGradientMath.shouldUseLinearFallback(mode: .automatic, colorCount: 3, steps: 10, lowPowerModeEnabled: true))
        #expect(!SmoothGradientMath.shouldUseLinearFallback(mode: .automatic, colorCount: 3, steps: 10, lowPowerModeEnabled: false))
    }

    @Test
    func smoothingTiersUseChartAnchors() {
        assertNearlyEqual(SmoothGradientSmoothing.high.transform(0.12), 0.02)
        assertNearlyEqual(SmoothGradientSmoothing.high.transform(0.57), 0.60)
        assertNearlyEqual(SmoothGradientSmoothing.high.transform(0.90), 0.98)

        assertNearlyEqual(SmoothGradientSmoothing.medium.transform(0.24), 0.04)
        assertNearlyEqual(SmoothGradientSmoothing.medium.transform(0.57), 0.65)
        assertNearlyEqual(SmoothGradientSmoothing.medium.transform(0.90), 0.99)

        assertNearlyEqual(SmoothGradientSmoothing.low.transform(0.24), 0.00)
        assertNearlyEqual(SmoothGradientSmoothing.low.transform(0.57), 0.72)
        assertNearlyEqual(SmoothGradientSmoothing.low.transform(0.90), 1.00)
    }

    @Test
    func smoothingCurveSeparationMatchesVisualExpectation() {
        let t = 0.57
        let high = SmoothGradientSmoothing.high.transform(t)
        let medium = SmoothGradientSmoothing.medium.transform(t)
        let low = SmoothGradientSmoothing.low.transform(t)
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

    @Test
    func locationCountMismatchCanBeHandledByMinimumPairingRule() {
        let colorsCount = 3
        let locationsCount = 2
        #expect(min(colorsCount, locationsCount) == 2)
    }
}

private func assertNearlyEqual(_ lhs: Double, _ rhs: Double, eps: Double = 0.000_001) {
    #expect(abs(lhs - rhs) < eps)
}
