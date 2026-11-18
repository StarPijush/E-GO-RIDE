# E-GO Onboarding Consistency & Visual Alignment Report

**Date:** 2026-11-08  
**Target Viewports:** 393 × 852 logical pixels (canonical) & 375 × 667 logical pixels (compact)  
**Status:** Complete — Final Visual Alignment & Coordinate Parity Achieved. Zero analyzer errors/warnings, 97/97 tests passing.

---

## 1. Executive Summary

Following a final visual alignment pass, **Screen 3's vertical offset has been eliminated**, the **description region has been standardized** across all three screens, and **Screen 1's hero geometry has been explicitly aligned** with Screens 2 and 3:

1. **Screen 3 Vertical Alignment Resolved**:
   - **Root Cause**: Screen 3's description naturally wraps into 3 lines (72 px) while Screens 1 & 2 wrap into 2 lines (48 px). In a flex-centered column without a fixed description region, a 24 px height delta caused Screen 3's content to center at a different baseline, placing the hero and heading 12–24 px higher.
   - **Fix**: Standardized the description area to a reserved 3-line box (`supportingAreaHeight = 72.0 px`, `supportingMaxWidth = 280.0 px`) across all three screens. Because the entire central block now has identical total height (`460.0 px`) on every screen, **Hero Top, Hero Center, Heading Top, Description Top, Progress Indicator, and CTA Button coordinates are 100% identical across all three screens**.
2. **Standardized Description Region**:
   - Reserved `72.0 px` height (3 lines × 24 px line height at 16 px font size).
   - Text aligns to top, preventing any text length difference from shifting the hero, heading, or footer.
   - Allows 3 lines without clipping or font shrinking.
3. **Hero Geometry Parity**:
   - All three screens now explicitly feature the concentric **216 px ambient ring** (`heroRingSize`) with **1 px border** (`ringBorder`), centered on top of the **236 px background disk** (`heroDiskSize`) inside the **272 × 272 px hero container** (`heroAreaSize`).
4. **Shared Layout Architecture (`OnboardingScreenLayout`)**:
   - Extracted shared layout structure into [`OnboardingScreenLayout`](lib/features/onboarding/presentation/widgets/onboarding_screen_layout.dart) so Screens 1, 2, and 3 cannot diverge in padding, spacing, or layout hierarchy.

---

## 2. Measured Coordinate & Dimension Parity (Canonical Viewport 393 × 852)

Actual coordinates extracted directly via automated Flutter widget render-tree testing:

| Component Metric | Screen 1 | Screen 2 | Screen 3 | Delta |
|---|---|---|---|---|
| **Hero Container Size** | 272.0 × 272.0 | 272.0 × 272.0 | 272.0 × 272.0 | **0.0 px** |
| **Hero Top (dy)** | 155.0 px | 155.0 px | 155.0 px | **0.0 px** |
| **Hero Center (dx, dy)** | (196.5, 291.0) | (196.5, 291.0) | (196.5, 291.0) | **0.0 px** |
| **Background Disk Diameter** | 236.0 px | 236.0 px | 236.0 px | **0.0 px** |
| **Ambient Ring Diameter** | 216.0 px | 216.0 px | 216.0 px | **0.0 px** |
| **Ambient Ring Border** | 1.0 px | 1.0 px | 1.0 px | **0.0 px** |
| **Hero-to-Heading Gap** | 32.0 px | 32.0 px | 32.0 px | **0.0 px** |
| **Heading Top (dy)** | 459.0 px | 459.0 px | 459.0 px | **0.0 px** |
| **Heading Reserved Height** | 72.0 px | 72.0 px | 72.0 px | **0.0 px** |
| **Heading-to-Description Gap** | 12.0 px | 12.0 px | 12.0 px | **0.0 px** |
| **Description Top (dy)** | 543.0 px | 543.0 px | 543.0 px | **0.0 px** |
| **Description Reserved Area** | 280.0 × 72.0 | 280.0 × 72.0 | 280.0 × 72.0 | **0.0 px** |
| **Progress Indicator Top (dy)** | 674.0 px | 674.0 px | 674.0 px | **0.0 px** |
| **Progress-to-CTA Gap** | 28.0 px | 28.0 px | 28.0 px | **0.0 px** |
| **CTA Button Top (dy)** | 710.0 px | 710.0 px | 710.0 px | **0.0 px** |
| **CTA Button Dimensions** | 345.0 × 58.0 | 345.0 × 58.0 | 345.0 × 58.0 | **0.0 px** |
| **CTA Border Radius** | 16.0 px | 16.0 px | 16.0 px | **0.0 px** |
| **CTA Arrow Icon** | None (text-only) | None (text-only) | None (text-only) | Identical |
| **Header Skip Top (dy)** | 48.0 px | 48.0 px | 48.0 px | **0.0 px** |

---

## 3. Files Modified

| File | Purpose |
|---|---|
| `lib/features/onboarding/presentation/theme/onboarding_constants.dart` | Added `headingAreaHeight: 72.0` (2 lines × 36px) and `supportingAreaHeight: 72.0` (3 lines × 24px). |
| `lib/features/onboarding/presentation/widgets/onboarding_hero.dart` | Explicitly added the 216 px concentric ambient ring (`ringBorder`) to Screen 1. Unified disk and ring rendering across all 3 variants. |
| `lib/features/onboarding/presentation/widgets/onboarding_screen_layout.dart` | **New shared layout component**: eliminates code duplication across screens and guarantees exact vertical coordinate matching for hero, heading, description, progress, and CTA. |
| `lib/features/onboarding/presentation/screens/onboarding_screen_one.dart` | Refactored to delegate layout to `OnboardingScreenLayout`. |
| `lib/features/onboarding/presentation/screens/onboarding_screen_two.dart` | Refactored to delegate layout to `OnboardingScreenLayout`. |
| `lib/features/onboarding/presentation/screens/onboarding_screen_three.dart` | Refactored to delegate layout to `OnboardingScreenLayout`. |
| `test/widget/onboarding_screenshot_test.dart` | Extended to capture high-fidelity screenshots for both 393 × 852 (canonical) and 375 × 667 (compact) viewports using real local Manrope fonts. |
| `test/widget/onboarding_consistency_test.dart` | Added rigorous tests asserting exact coordinate equality (`getTopLeft`, `getCenter`), 216 px ring presence on Screen 1, description region isolation, and 6-viewport responsive tests. |

---

## 4. Screenshot Locations

Screenshots captured using local bundled Manrope fonts:

### Canonical Viewport: 393 × 852
- **Screen 1**: [`test/screenshots/onboarding_screen_one_393x852.png`](file:///D:/E-RICKSHAW%20RIDE/E-go/test/screenshots/onboarding_screen_one_393x852.png)
- **Screen 2**: [`test/screenshots/onboarding_screen_two_393x852.png`](file:///D:/E-RICKSHAW%20RIDE/E-go/test/screenshots/onboarding_screen_two_393x852.png)
- **Screen 3**: [`test/screenshots/onboarding_screen_three_393x852.png`](file:///D:/E-RICKSHAW%20RIDE/E-go/test/screenshots/onboarding_screen_three_393x852.png)

### Compact Viewport: 375 × 667 (iPhone SE)
- **Screen 1**: [`test/screenshots/onboarding_screen_one_375x667.png`](file:///D:/E-RICKSHAW%20RIDE/E-go/test/screenshots/onboarding_screen_one_375x667.png)
- **Screen 2**: [`test/screenshots/onboarding_screen_two_375x667.png`](file:///D:/E-RICKSHAW%20RIDE/E-go/test/screenshots/onboarding_screen_two_375x667.png)
- **Screen 3**: [`test/screenshots/onboarding_screen_three_375x667.png`](file:///D:/E-RICKSHAW%20RIDE/E-go/test/screenshots/onboarding_screen_three_375x667.png)

---

## 5. Verification Checklist

- [x] **Screen 3 vertical alignment**: Resolved. Hero top is at 155.0 px on Screens 1, 2, and 3.
- [x] **Standardize description region**: Reserved 72.0 px height. Supports up to 3 lines without clipping or font resizing.
- [x] **Hero geometry**: All three screens share 272 × 272 container, 236 px disk, 216 px ring with 1 px border, and centered artwork. Screen 1 explicitly verified.
- [x] **Preserve existing correct elements**:
  - Screen 1: "Get started", text centered, no arrow icon.
  - Screen 2: "Next", text centered, no arrow icon.
  - Screen 3: "Next", text centered, no arrow icon.
  - Branding, colors, and illustrations completely intact.
- [x] **Responsive validation across 6 viewports**:
  - 375 × 667 (Compact / SE)
  - 360 × 800 (Standard Android)
  - 375 × 812 (iPhone X/11/12 mini)
  - 393 × 852 (Canonical)
  - 412 × 915 (Large Android / Pixel 7)
  - 430 × 932 (Plus / Pro Max)
- [x] **Static analysis**: `flutter analyze` reports **0 errors, 0 warnings, 0 infos**.
- [x] **Test suite**: `flutter test` reports **97/97 tests passed** (zero regressions, zero deleted tests).
