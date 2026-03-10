---
name: compare-ui
description: Generate two SwiftUI implementations of a feature — one using ShipSwift (SWPackage) components and one vanilla SwiftUI — for side-by-side comparison. Use when the user wants to compare ShipSwift vs plain SwiftUI approaches.
argument-hint: <feature description>
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# Compare UI: ShipSwift vs Vanilla SwiftUI

Generate two complete SwiftUI view implementations for a given feature — one leveraging ShipSwift components and one using only vanilla SwiftUI — so the user can compare and pick the better approach.

## Available ShipSwift Components

Before generating, review what's available in the SWPackage:

### Animations (`SWPackage/SWAnimation/`)
- `SWAnimatedMeshGradient` — Animated mesh gradient backgrounds
- `SWBeforeAfterSlider` — Before/after image comparison slider
- `SWGlowSweep` / `SWLightSweep` — Glow and light sweep effects
- `SWScanningOverlay` — Scanning overlay animation
- `SWShakingIcon` — Shaking icon animation
- `SWShimmer` — Shimmer loading placeholders
- `SWTypewriterText` — Typewriter text reveal
- `SWOrbitingLogos` — Orbiting logo animation

### Charts (`SWPackage/SWChart/`)
- `SWActivityHeatmap` — GitHub-style activity heatmap
- `SWAreaChart` / `SWBarChart` / `SWLineChart` — Standard data charts
- `SWDonutChart` / `SWRingChart` — Circular charts
- `SWRadarChart` — Radar/spider chart
- `SWScatterChart` — Scatter plot

### Display (`SWPackage/SWComponent/Display/`)
- `SWFloatingLabels` — Floating label animations
- `SWMarkdownText` — Markdown renderer
- `SWScrollingFAQ` — Scrolling FAQ (iOS)
- `SWRotatingQuote` — Rotating quotes
- `SWBulletPointText` — Bullet point lists
- `SWGradientDivider` — Gradient dividers
- `SWLabel` — Styled labels
- `SWOnboardingView` — Onboarding screens
- `SWOrderView` — Order display
- `SWRootTabView` — Tab navigation

### Feedback (`SWPackage/SWComponent/Feedback/`)
- `SWAlert` — Alert system (`.swAlert()`)
- `SWLoading` — Loading indicators (`.swPageLoading()`)
- `SWThinkingIndicator` — Thinking/processing indicator

### Input (`SWPackage/SWComponent/Input/`)
- `SWTabButton` — Tab buttons
- `SWStepper` — Stepper control
- `SWAddSheet` — Add/input sheets

### Modules (`SWPackage/SWModule/`)
- `SWAuth` — Authentication flow
- `SWCamera` — Camera (iOS)
- `SWPaywall` — Paywall & store management
- `SWChat` — Chat UI (iOS)
- `SWSetting` — Settings screens
- `SWSubjectLifting` — Subject lifting (iOS)

### Utilities (`SWPackage/SWUtil/`)
- `SWDebugLog` — Debug logging
- `SWViewExtension` — View modifiers (`.swPrimary`, etc.)
- `SWStringExtension` / `SWDateExtension` — String & date helpers
- `SWLocationManager` — Location services

## Instructions

1. **Parse the feature request** from `$ARGUMENTS`. If no arguments, ask the user what feature/screen to build.

2. **Read relevant SWPackage source files** to understand the actual APIs, initializers, and view modifiers available. Do NOT guess APIs — read the Swift files first.

3. **Generate Version A: ShipSwift** — Write a complete SwiftUI view that uses as many relevant ShipSwift components as naturally fit. Save to `CompareUI/VersionA_ShipSwift.swift`.

4. **Generate Version B: Vanilla** — Write the same feature using only stock SwiftUI (no SWPackage imports). Save to `CompareUI/VersionB_Vanilla.swift`.

5. **Output a comparison summary** as a markdown table:

| Aspect | ShipSwift | Vanilla |
|--------|-----------|---------|
| Lines of code | — | — |
| Components used | — | — |
| Custom code needed | — | — |
| Animation support | — | — |
| Key tradeoff | — | — |

6. **Recommendation** — State which version you'd pick and why, considering:
   - Code brevity and readability
   - Built-in features (animations, theming, accessibility)
   - Flexibility and customization
   - Maintenance burden

## Output Files

Write both versions to a `CompareUI/` directory in the project root so they're easy to find and delete after comparison:

```
CompareUI/
  VersionA_ShipSwift.swift
  VersionB_Vanilla.swift
```

## Rules

- Both versions must compile independently
- Both must implement the SAME feature with equivalent functionality
- ShipSwift version should use SW-prefixed types and `.sw` modifiers where available
- Vanilla version should use only `import SwiftUI` (and `import Charts` if charting)
- Keep both versions realistic — no padding one to look worse
- All comments in English
