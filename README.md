# SmoothGradientUIKit

A UIKit `UIView` component that reproduces smooth gradient overlays by sampling linear gradient stops.
Built for direct use in iOS apps and for easy code generation/consumption by AI tools.

## What This Library Is For

- Render soft, film-like gradient overlays in UIKit.
- Keep API small: colors + steps + smoothing tier + direction.
- Provide safe fallback to plain linear gradient when smoothing should not be used.

## Smoothing Tiers

![Smoothing Tiers](docs/images/smoothing-tiers.png)

## Features

- `SmoothGradientView: UIView`
- Configurable `steps` (default `10`), `smoothing` (`high`/`medium`/`low`), `colors`, `locations`, and direction
- Animated updates via `setConfiguration(_:animated:duration:timing:)`
- Automatic fallback to linear gradient when needed (`fallbackMode`)
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
        smoothing: .high,
        direction: .topLeftToBottomRight,
        fallbackMode: .automatic
    ),
    animated: true
)
```

## Color + Location Mode

- `colors[i]` pairs with `locations[i]`.
- Locations are clamped into `[0, 1]`.
- Input can be unordered; the renderer sorts by location.
- If lengths differ, only the minimum count is used for pairing.
- Area beyond the last location keeps the last color (e.g. `colors=[clear, white]`, `locations=[0, 0.5]` means `0.5...1` is pure white).

## Fallback Behavior

`fallbackMode = .automatic` will use plain linear gradient when:

- color count is less than 2
- steps resolve to 2 or less

Use `.linearOnly` to force plain linear gradient.

## Public API

- `SmoothGradientView`
- `SmoothGradientConfiguration`
- `SmoothGradientDirection`
- `SmoothGradientSmoothing`
- `SmoothGradientFallbackMode`
- `SmoothGradientMath`
