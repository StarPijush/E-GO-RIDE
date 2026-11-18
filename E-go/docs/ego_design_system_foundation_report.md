# E-GO Design System Foundation Report

**Phase:** 1 — Design System Foundation  
**Date:** 15 November 2026  
**Scope:** Flutter web customer app only  
**Status:** Complete; stopped before Phase 2

---

## 1. Summary

Phase 1 consolidates the E-GO design system into a single token architecture, replaces the old yellow/black Material theme with the official yellow/background/navy palette, adds locally bundled Poppins and Inter typography, expands the Material 3 theme coverage, aligns the shared widget layer, updates the web/PWA shell, and adds regression tests for the foundation.

No screen migration was performed. Onboarding, authentication, home, booking, ride lifecycle, profile, safety, and support screens retain their existing layout and local styling until their approved phases.

A new foundation visual harness renders the token system at 393 × 852 and 375 × 667 for inspection. The full suite passes at 155 tests, the analyzer is clean, and the web build succeeds.

---

## 2. Scope and Guardrails Preserved

- No route, navigation, screen constructor, validation rule, or booking/auth behavior was changed.
- No onboarding geometry was changed. Hero, disk, ring, heading area, CTA size, and CTA radius remain intact.
- Manrope remains bundled and declared because onboarding and authentication still use it locally.
- No Android or iOS configuration was added or changed.
- No screen-local palette was migrated in this phase.
- The official logo assets were not redrawn or color-edited.
- Existing tests were not weakened or removed.
- Pre-existing worktree changes in auth, onboarding, docs, and tests were left intact.

---

## 3. Token Architecture

### 3.1 Single source of truth

| Layer | File | Responsibility |
|---|---|---|
| Raw official palette | `lib/core/branding/ego_brand_colors.dart` | Official brand values, derived neutral tones, semantic status colors |
| Semantic roles | `lib/app/theme/colors.dart` | `EGoColors` roles referencing the raw palette; compatibility aliases |
| Typography | `lib/app/theme/typography.dart` | Font families and all text styles |
| Spacing, shape, elevation | `lib/app/theme/spacing.dart` | 4 px spacing scale, control sizes, radii, border widths, elevation |
| Material theme | `lib/app/theme/theme.dart` | The only `ThemeData` used by the app |
| Public barrel | `lib/app/theme/index.dart` | Canonical theme import |
| Compatibility barrel | `lib/core/theme/index.dart` | Re-exports the canonical theme and branding barrel |

`lib/core/branding/ego_brand_theme.dart` was removed. It contained a second, unused button/card style system and had no production or test callers. `lib/core/branding/ego_brand.dart` no longer exports it.

`EGoColors` no longer defines independent brand hex values. It aliases the raw palette and maps compatibility names to the new system.

---

## 4. Palette Tokens

### 4.1 Official colors

| Token | Value | Role |
|---|---|---|
| `EgoBrandColors.yellow` | `#FFC928` | Primary CTA, active navigation, selection, brand accents, map markers |
| `EgoBrandColors.background` | `#F5F7FA` | Scaffold and page canvas |
| `EgoBrandColors.navy` | `#142B45` | Text, icons, outlines, dark surfaces, secondary actions |
| `EgoBrandColors.white` | `#FFFFFF` | Cards, sheets, inputs, app bars |

### 4.2 Derived brand tones

| Token | Value | Use |
|---|---|---|
| `yellowLight` | `#FFF7DF` | Selected/container fill, light yellow surface |
| `yellowMuted` | `#FFFBEE` | Subtle brand surface |
| `yellowDark` | `#E8B92B` | Pressed/dark yellow accent |
| `navyTint` | `#EAEDF1` | Secondary container / navigation tint |
| `surfaceVariant` | `#F3F4F6` | Muted neutral surface |
| `surfaceStrong` | `#E3E8EE` | Disabled fill |
| `navyBorder` | `#29142B45` (16% navy) | Outlines |
| `navyDivider` | `#1F142B45` (12% navy) | Dividers and subtle borders |
| `navySecondaryText` | `#A6142B45` (65% navy) | Secondary text |
| `navyStrongText` | `#BF142B45` (75% navy) | Strong secondary text |
| `navyMutedText` | `#80142B45` (50% navy) | Hints and inactive labels |
| `navyDisabledText` | `#66142B45` (40% navy) | Disabled foreground |
| `shadow` | `#1A142B45` (10% navy) | Soft navy-tinted shadows |

`EgoBrandColors.logoInk` remains true black for the logo artwork. UI text and `EGoColors.brandBlack` now resolve to navy.

### 4.3 Semantic colors preserved

| Semantic | Value |
|---|---|
| Success | `#059669` |
| Success light | `#D1FAE5` |
| Warning | `#D97706` |
| Warning light | `#FEF3C7` |
| Error | `#DC2626` |
| Error light | `#FEE2E2` |
| Information | `#0284C7` |
| Information light | `#E0F2FE` |

Compatibility aliases keep existing consumers compiling. `EGoColors.grey50` now equals the official background; `grey900` equals navy. `surfaceGreen`, `outlineGreen`, and related legacy names delegate to the new palette rather than holding old green values.

---

## 5. Typography and Font Assets

### 5.1 Families

| Role | Family | Weights bundled |
|---|---|---|
| Display and headings | Poppins | 400, 500, 600, 700, 800 |
| Body, inputs, buttons, navigation, labels, numerals | Inter | 400, 500, 600, 700 |

Exported family tokens:

- `EGoTypography.fontFamilyDisplay = 'Poppins'`
- `EGoTypography.fontFamilyBody = 'Inter'`
- `EGoTypography.fontFamilyNumbers = 'Inter'`
- `EGoTypography.fontFamilyPrimary = 'Inter'` (compatibility alias)

### 5.2 Applied styles

| Tokens | Family |
|---|---|
| `displayLarge`, `displayMedium`, `displaySmall` | Poppins |
| `headlineLarge`, `headlineMedium`, `headlineSmall` | Poppins |
| `titleLarge` | Poppins |
| `brandTitle` | Poppins |
| `titleMedium`, `titleSmall` | Inter |
| `bodyLarge`, `bodyMedium`, `bodySmall` | Inter |
| `labelLarge`, `labelMedium`, `labelSmall` | Inter |
| `navigationLabel` | Inter |
| `brandTagline` | Inter |

Existing font sizes and line heights were retained. Display styles moved from weight 400 to 600 and `titleLarge` from 500 to 600 to use the approved Poppins heading range. A navigation label token was added so the shared bottom bar no longer declares Manrope directly.

### 5.3 Local font files and licenses

Added under `assets/fonts/`:

- `Poppins-Regular.ttf`
- `Poppins-Medium.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`
- `Poppins-ExtraBold.ttf`
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`
- `OFL-Poppins.txt`
- `OFL-Inter.txt`

Manrope and its existing `OFL.txt` remain. `pubspec.yaml` declares all three families. No remote font dependency is used.

The built `FontManifest.json` contains Poppins, Inter, Manrope, and MaterialIcons, confirming that Flutter serves the bundled families.

---

## 6. Shape, Spacing, and Elevation

The existing 4 px scale was retained. Added semantic radius and border aliases:

| Token | Value |
|---|---|
| `radiusButton` | 24 |
| `radiusCard` | 16 |
| `radiusInput` | 16 |
| `radiusSheet` | 24 |
| `borderWidth` | 1 |
| `focusBorderWidth` | 2 |

Existing control heights, icon sizes, spacing, and elevation scale remain unchanged.

---

## 7. Material Theme Coverage

`EGoTheme.light` now defines:

- **ColorScheme:** yellow primary with navy `onPrimary`; navy secondary; white surface; navy `onSurface`; official background scaffold; inherited semantic error, outline, shadow, inverse colors.
- **TextTheme:** all display, headline, title, body, and label styles bound to `EGoTypography`.
- **AppBar:** white surface, navy title/icons, zero resting elevation, one-level scrolled elevation.
- **Card:** white surface, 16 px radius, subtle navy-derived border, soft shadow.
- **Buttons:** yellow/navy filled and elevated buttons; navy outlined/text buttons; derived disabled fills and labels; Inter labels.
- **Inputs:** white fill, 16 px radius, navy 2 px focus border, semantic error borders, navy-derived hints, labels, and icons.
- **Dialogs:** white surface, 16 px radius, navy title/body styles, soft elevation.
- **Bottom sheets:** white surface, 24 px top radius, navy drag handle.
- **Snackbars:** navy surface, white content, yellow action text.
- **Navigation bar:** white surface, yellow indicator, navy active icon/label, muted inactive state.
- **Chips:** neutral unselected surface, yellow selected fill, navy selected label/checkmark, semantic status colors available to consumers.
- **Supporting themes:** divider, list tile, progress indicator, tooltip, and floating action button.

---

## 8. Shared Component Updates

| Component | Change |
|---|---|
| `EGoPrimaryButton` | Consumes theme fill/disabled styles; loading and label colors use navy-on-yellow; no duplicate palette constants |
| `EGoSecondaryButton` | Consumes theme outline and text colors |
| `EGoTextButton` | Consumes theme navy text style |
| `EGoIconButton` / FAB | Use semantic surface and theme foreground values |
| `EGoLocationInput` | Navy/neutral hint and value colors |
| `EGoSearchInput` | Muted navy hint and icon colors |
| `EGoRecentDestinationChip` | Selected text/icon now navy on the light-yellow surface; yellow remains the border/selection cue |
| `EGoSectionHeader` / dividers / empty state / loading / banner | Migrated to semantic text/surface/status tokens |
| `EGoBottomNavBar` | Inter navigation labels, yellow active capsule, navy active icon/text, muted inactive state, tokenized divider/shadow/gesture indicator |
| Location controls | Muted navy disabled icons; yellow active location control preserved |

Public constructors, callback signatures, test keys, labels, and navigation behavior were not changed.

---

## 9. Web Shell, PWA Metadata, and Brand Assets

### 9.1 Web metadata

`web/index.html` now provides:

- Title: `E-GO | Move your way`
- Description: `E-GO customer ride-booking application. Move your way.`
- Theme color: `#FFC928`
- Apple web app title: `E-GO`
- `lang="en"` and a mobile viewport declaration
- No Google Fonts preconnect or remote stylesheet

`web/manifest.json` now provides:

- Name: `E-GO | Move your way`
- Short name: `E-GO`
- Background: `#F5F7FA`
- Theme: `#FFC928`
- Official description

### 9.2 Icons

The default Flutter favicon and PWA icons were replaced using the official `assets/branding/ego_logo_icon.png` artwork on the official yellow background:

- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

Maskable variants keep the mark inside the central safe area. The source logo was not redrawn.

### 9.3 Brand asset audit

- `ego_logo_primary.png`, `ego_logo_icon.png`, and `ego_logo_wordmark.png` contain black artwork on transparency.
- Used logo assets do not need color replacement.
- `ego_brand_background.jpg` contains a baked-in gold background close to the legacy yellow. It is unused by the app theme; its eventual replacement can be handled with brand marketing assets later.
- PWA icons were the only default Flutter-branded assets replaced.

---

## 10. Tests and Verification

### 10.1 Commands run

```powershell
cd "D:\E-RICKSHAW RIDE\E-go"
dart format lib test
flutter analyze
flutter test
flutter build web
```

### 10.2 Results

| Check | Result |
|---|---|
| Baseline test suite | 143 tests passing |
| Current analyzer | No issues |
| Current test suite | 155 tests passing |
| Web build | Succeeded |
| Wasm dry run | Succeeded |
| New token tests | 10 |
| New foundation screenshot tests | 2 |

The web build emitted a non-blocking warning that `CupertinoIcons` fonts were expected but not bundled. No Phase 1 code references Cupertino icons; this is not caused by the font additions and no package was added merely to silence it.

### 10.3 New tests

`test/unit/design_tokens_test.dart` verifies:

- Official yellow, background, navy, and white values
- Palette role aliases
- Semantic success, warning, error, and information values
- Poppins display/heading bindings and Inter UI bindings
- ColorScheme, scaffold, text theme, app bar, and typography bindings
- Primary/disabled button styles
- Input focus and error borders
- Card radius, dialog, sheet, snackbar, navigation, and chip styling
- Shape token relationships

`test/widget/design_system_screenshot_test.dart` renders and captures the foundation gallery at 393 × 852 and 375 × 667 with Poppins and Inter loaded.

New screenshot artifacts:

- `test/screenshots/design_system_foundation_393x852.png`
- `test/screenshots/design_system_foundation_375x667.png`

### 10.4 Visual inspection

The foundation gallery was inspected at both viewports. It shows:

- Poppins headings and Inter body/UI text rendering correctly
- Yellow primary button with navy label
- Navy outlined secondary button
- White card with subtle border and shadow
- Official light canvas and navy text
- White input with correct radius
- Success, warning, error, and information status pills
- No clipping or overflow at either viewport

Existing onboarding, login, and registration screenshots were regenerated by the full suite and inspected. They intentionally remain in their pre-migration Manrope/local-color state because those screens are Phase 2–3 work. The auth/onboarding screenshot harnesses still have their pre-existing MaterialIcons loading gap, so their icon glyphs can appear as squares in test artifacts; the production icon set was not changed.

---

## 11. Remaining Local Styles and Deferred Work

Phase 1 intentionally did not migrate screen-local styles. Remaining work is concentrated in:

- `features/onboarding/presentation/theme/onboarding_constants.dart` — 18 local color literals and Manrope family
- Auth screens and fields — Manrope and local border/focus/hint/error colors, including phone login, create account, OTP, profile setup, and auth field widgets
- Home — local `_k*` colors, marker colors, and functional map painter palette
- Safety — legacy local palette and Manrope
- Rides — Manrope in ride cards, headers, filters, empty state, and booking button
- Booking — a few local semantic/rating accents
- Onboarding illustration colors that are artwork-level rather than interface-level

Measured remaining old values in `lib/`:

- `#F5C928`: 8 occurrences in 5 files
- `#FCD030`: 9 occurrences in 7 files
- `#FAF9F5`: 3 occurrences in 3 files
- `#171717`: 22 occurrences in 8 files
- `Manrope` references: 35 occurrences in 13 files

These are expected at the end of Phase 1. No banned-token grep test was added yet because the failure set is still large by design; add it after the screen migrations remove those references.

---

## 12. Attention Items

1. **Showcase reference is still absent.** No pixel-fidelity claim is made for screen work. Phase 2 should begin only after the reference image is available or the team explicitly accepts a token-driven approximation.
2. **`EgoBrandTheme` removal.** It had zero production or test callers. Any external consumer outside this repository would need to use the Material theme or shared buttons instead.
3. **Navy-derived text tokens with alpha.** Secondary/muted text and borders use translucent navy by design. Later screen phases should verify them over non-white surfaces, especially yellow and navy panels.
4. **Manrope remains active.** It is still required by onboarding and auth. Do not remove it until those screens and their screenshot tests are migrated and visually verified.
5. **Auth screenshot icon glyphs.** The pre-existing screenshot harness does not load MaterialIcons for login/register tests. The Phase 3 auth migration should load the icon font portably and replace the hardcoded SDK path.
6. **No mobile platform work.** Android/iOS remain out of scope.

---

## 13. Recommended Next Phase

1. Obtain and inspect the official UI showcase reference; complete Gate R.
2. Phase 2: migrate splash and onboarding to the new tokens and typography while preserving all fixed geometry and test keys.
3. Regenerate and inspect onboarding screenshots at all required viewports; verify line wrapping after the Manrope-to-Poppins/Inter transition.
4. Update the onboarding screenshot harness to load Poppins/Inter and MaterialIcons portably.
5. Then proceed to Phase 3 auth, where local Manrope and local error/focus colors can be removed without changing validation or request logic.
6. Add a stable banned-token test only after the migrated screens no longer require the legacy values.

---

## 14. Changed File Inventory

### Created

- `assets/fonts/Poppins-Regular.ttf`
- `assets/fonts/Poppins-Medium.ttf`
- `assets/fonts/Poppins-SemiBold.ttf`
- `assets/fonts/Poppins-Bold.ttf`
- `assets/fonts/Poppins-ExtraBold.ttf`
- `assets/fonts/Inter-Regular.ttf`
- `assets/fonts/Inter-Medium.ttf`
- `assets/fonts/Inter-SemiBold.ttf`
- `assets/fonts/Inter-Bold.ttf`
- `assets/fonts/OFL-Poppins.txt`
- `assets/fonts/OFL-Inter.txt`
- `test/unit/design_tokens_test.dart`
- `test/widget/design_system_screenshot_test.dart`
- `test/screenshots/design_system_foundation_393x852.png`
- `test/screenshots/design_system_foundation_375x667.png`
- `docs/ego_design_system_foundation_report.md`

### Modified

- `pubspec.yaml`
- `lib/core/branding/ego_brand_colors.dart`
- `lib/core/branding/ego_brand.dart`
- `lib/app/theme/colors.dart`
- `lib/app/theme/typography.dart`
- `lib/app/theme/spacing.dart`
- `lib/app/theme/theme.dart`
- `lib/shared/widgets/buttons.dart`
- `lib/shared/widgets/inputs.dart`
- `lib/shared/widgets/common.dart`
- `lib/shared/widgets/bottom_nav_bar.dart`
- `lib/shared/widgets/location_components.dart`
- `web/index.html`
- `web/manifest.json`
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

### Removed

- `lib/core/branding/ego_brand_theme.dart` — unused duplicate style helper

### Regenerated test artifacts

The full test run regenerated the existing onboarding, login, and registration screenshot artifacts. No screen source or test assertions were changed.

### Unchanged by Phase 1

All screens, routes, app state, auth repositories, booking services, onboarding layout, Android configuration, and iOS configuration. The pre-existing worktree modifications in those areas were preserved.
