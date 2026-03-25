# SmoothGradientUIKit

A UIKit `UIView` component for smooth gradient overlays driven by cubic-bezier interpolation.
Built for direct use in iOS apps and for easy code generation/consumption by AI tools.

## What This Library Is For

- Render soft, film-like gradient overlays in UIKit.
- Keep API small: `colors + locations + steps + curve + direction`.
- Fail fast on invalid inputs during development.

## Curve Presets

| Preset | Cubic Parameters |
| --- | --- |
| `high` | `cubic-bezier(0.455, 0.030, 0.515, 0.955)` |
| `medium` | `cubic-bezier(0.645, 0.045, 0.355, 1.000)` |
| `low` | `cubic-bezier(0.830, 0.000, 0.170, 1.000)` |

## Features

- `SmoothGradientView: UIView`
- Configurable `steps` (default `10`), `curve`, `colors`, `locations`, and direction
- Named presets (`high`/`medium`/`low`) + custom cubic curve
- Animated updates via `setConfiguration(_:animated:duration:timing:)`
- iOS 13+ Swift Package

## Install

Add this package to your project with Swift Package Manager.

## Quick Start

```swift
import UIKit
import SmoothGradientUIKit

let gradientView = SmoothGradientView()
gradientView.setConfiguration(
    SmoothGradientConfiguration(
        colors: [.clear, .systemPink, .white],
        locations: [0.0, 0.28, 1.0],
        steps: 10,
        curve: SmoothGradientCurvePreset.high.cubic,
        direction: .topLeftToBottomRight
    ),
    animated: true
)
```

## Custom Cubic Curve

```swift
let custom = SmoothGradientCubic(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0)
gradientView.setCurve(custom, animated: true)
```

## Color + Location Mode

- `colors[i]` pairs with `locations[i]`.
- Locations are clamped into `[0, 1]`.
- Input can be unordered; the renderer sorts by location.
- If lengths differ, only the minimum count is used for pairing.
- Area beyond the last location keeps the last color (e.g. `colors=[clear, white]`, `locations=[0, 0.5]` means `0.5...1` is pure white).

## Input Validation (Fail Fast)

The renderer uses `precondition` checks for invalid configuration:

- `colors.count >= 2`
- `locations.count >= 2`
- `min(colors.count, locations.count) >= 2`
- `steps` in `[2, 64]`
- cubic `x1/x2` in `[0, 1]`

## Public API

- `SmoothGradientView`
- `SmoothGradientConfiguration`
- `SmoothGradientDirection`
- `SmoothGradientCubic`
- `SmoothGradientCurvePreset`
- `SmoothGradientMath`
