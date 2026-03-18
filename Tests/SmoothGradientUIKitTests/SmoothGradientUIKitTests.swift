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
        #expect(SmoothGradientMath.shouldUseLinearFallback(mode: .automatic, colorCount: 3, steps: 10, lowPowerModeEnabled: true))
        #expect(!SmoothGradientMath.shouldUseLinearFallback(mode: .automatic, colorCount: 3, steps: 10, lowPowerModeEnabled: false))
    }

    @Test
    func smoothingTierMappingMatchesRequestedWebsiteCurves() {
        let t = 0.25
        #expect(SmoothGradientSmoothing.high.transform(t) == 0.125)
        #expect(SmoothGradientSmoothing.medium.transform(t) == 0.0625)
        #expect(SmoothGradientSmoothing.low.transform(t) == 0.015625)
    }

    @Test
    func legacyEasingMapsToSmoothingTiers() {
        #expect(SmoothEasing.easeInOutQuad.smoothing == .high)
        #expect(SmoothEasing.easeInOutCubic.smoothing == .medium)
        #expect(SmoothEasing.easeInOutQuint.smoothing == .low)
    }
}
