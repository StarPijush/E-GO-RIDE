# E-GO Profile / Account Screen — Research Document

> **Agent 2 research output.** Read-only analysis — no source files were modified.
> Generated: 2026-11-16

---

## 1. Relevant Existing Flutter Files & Their Purpose

| File | Purpose |
|------|---------|
| `lib/app/router.dart` | Centralised `EGoRouter` — all named route constants + `generateRoute()` |
| `lib/app/app_state.dart` | `AppState extends ChangeNotifier` — holds `AuthUser profile`, `logout()`, `updateProfile()`, booking state, notifications |
| `lib/app/app.dart` | App root; wraps `ChangeNotifierProvider<AppState>` around `MaterialApp` |
| `lib/app/theme/colors.dart` | `EGoColors` semantic tokens (aliases to `EgoBrandColors`) |
| `lib/app/theme/typography.dart` | `EGoTypography` — Poppins (display) + Inter (body) text styles |
| `lib/app/theme/spacing.dart` | `EGoSpacing` — 4px base scale, component sizes, border radii |
| `lib/app/theme/theme.dart` | `EGoTheme.light` — full `ThemeData` (Material 3) |
| `lib/app/theme/index.dart` | Re-exports all theme + branding (import this in screens) |
| `lib/core/branding/ego_brand_colors.dart` | Raw `EgoBrandColors` hex values |
| `lib/core/branding/widgets/ego_logo.dart` | `EgoLogo` widget — `.primary`, `.icon`, `.wordmark` factory constructors |
| `lib/core/branding/ego_brand_assets.dart` | Asset paths for logo variants |
| `lib/core/widgets/widgets.dart` | Thin barrel: `export 'package:e_go/shared/widgets/index.dart'` |
| `lib/shared/widgets/index.dart` | Barrel exporting buttons, inputs, common, bottom_nav_bar, location_components |
| `lib/shared/widgets/buttons.dart` | `EGoPrimaryButton`, `EGoSecondaryButton`, `EGoTextButton`, `EGoIconButton`, `EGoFloatingActionButton` |
| `lib/shared/widgets/common.dart` | `EGoSectionHeader`, `EGoLabeledDivider`, `EGoEmptyState`, `EGoLoadingOverlay`, `EGoBanner` |
| `lib/shared/widgets/bottom_nav_bar.dart` | `EGoBottomNavBar` — 4-tab nav (Home/Rides/Safety/Profile) |
| `lib/shared/widgets/inputs.dart` | Input field helpers |
| `lib/shared/widgets/location_components.dart` | Location chips / place rows |
| `lib/features/account/presentation/profile_screen.dart` | **Target screen** — current profile + menu list |
| `lib/features/account/presentation/edit_profile_screen.dart` | Edit name + email, calls `AppState.updateProfile()` |
| `lib/features/account/presentation/payment_methods_screen.dart` | Cash / UPI selector |
| `lib/features/account/presentation/settings_screen.dart` | Language, notifications, privacy + logout |
| `lib/features/account/presentation/about_screen.dart` | Brand identity, mission, regions |
| `lib/features/auth/domain/entities/auth_user.dart` | `AuthUser` value object |
| `lib/features/auth/data/models/mock_user_model.dart` | Dev-only in-memory account wrapper |
| `lib/features/auth/data/repositories/mock_auth_repository.dart` | Full mock implementation; seeds demo account |
| `lib/features/auth/domain/repositories/auth_repository.dart` | `AuthRepository` interface |
| `lib/features/home/presentation/home_screen.dart` | Home screen; owns bottom nav routing (tab 3 → `/profile`) |
| `lib/mock_data/mock_data.dart` | Static mock destinations, saved places, FAQ items |

---

## 2. Routing Architecture

### Route Constants (`EGoRouter`)

```dart
// Module D — Account & Support
static const String myRides       = '/my-rides';
static const String rideDetails   = '/ride-details';
static const String profile        = '/profile';          // ← ProfileScreen
static const String editProfile    = '/edit-profile';     // ← EditProfileScreen
static const String paymentMethods = '/payment-methods';  // ← PaymentMethodsScreen
static const String notifications  = '/notifications';    // ← NotificationsScreen
static const String helpSupport    = '/help-support';     // ← HelpSupportScreen
static const String settings       = '/settings';         // ← SettingsScreen
static const String about          = '/about';            // ← AboutScreen
```

### Navigation patterns in profile

| Destination | Pattern |
|------------|---------|
| Edit profile | `Navigator.pushNamed(context, EGoRouter.editProfile)` |
| My rides | `Navigator.pushNamed(context, EGoRouter.myRides)` |
| Saved places | `Navigator.pushNamed(context, EGoRouter.savedPlaces)` |
| Payment methods | `Navigator.pushNamed(context, EGoRouter.paymentMethods)` |
| Help & Support | `Navigator.pushNamed(context, EGoRouter.helpSupport)` |
| Notifications | `Navigator.pushNamed(context, EGoRouter.notifications)` |
| Settings | `Navigator.pushNamed(context, EGoRouter.settings)` |
| About | `Navigator.pushNamed(context, EGoRouter.about)` |
| Logout → Login | `Navigator.pushNamedAndRemoveUntil(context, EGoRouter.login, (_) => false)` |

### Bottom Navigation (home_screen.dart)
- 4 tabs: Home (0), Rides (1), Safety/Help (2), Account (3)
- Tab 3 pushes `/profile` and resets index to 0 on pop
- `EGoBottomNavBar` shared component also available but home_screen uses its own inlined nav

### Auth Guard
Routes in `EGoRouter.protectedRoutes` (includes `/profile`, `/edit-profile`, `/payment-methods`, `/notifications`, `/settings`) redirect to `/login` if `AppState.isLoggedIn == false`.

---

## 3. User Model Fields (`AuthUser`)

```dart
class AuthUser {
  final String id;                   // unique identifier
  final String name;                 // full name (editable)
  final String phone;                // normalized: '+91XXXXXXXXXX'
  final String? email;               // optional (editable)
  final bool isProfileComplete;      // gates isLoggedIn
  final bool hasCompletedOnboarding; // SharedPreferences persisted

  static const AuthUser empty = AuthUser(id: '', name: '', phone: '');
}
```

**Demo account seeded in MockAuthRepository:**
- Phone: `9000000001` / normalized `+919000000001`
- Password: `EgoDemo@123`
- Name: `E-GO Demo User`
- Email: `demo@ego.local`

**What can be updated:** Only `name` and `email` via `AppState.updateProfile()`.  
`phone` is immutable (login credential). `id` never changes.

---

## 4. Logout Implementation

### Flow
1. **Profile screen:** Shows `AlertDialog` via `_showLogoutDialog()`.
2. User confirms → `context.read<AppState>().logout()` is awaited.
3. `AppState.logout()` calls `_customerRepo.logout()` (sets `_session = null`), then:
   - `_profile = AuthUser.empty`
   - `_isAuthenticated = false`
   - `_error = null`
   - `_resetBooking()` — clears all booking state
   - `notifyListeners()`
4. Screen then calls `Navigator.pushNamedAndRemoveUntil(context, EGoRouter.login, (_) => false)`.

### Duplicate Implementation
`SettingsScreen` also has an identical logout flow (same pattern). The new profile screen should **not** create a third implementation — it should call the existing `AppState.logout()` and clear the navigation stack the same way.

---

## 5. Fonts & Icons

### Fonts (from `pubspec.yaml`)

| Family | Weights | Usage |
|--------|---------|-------|
| **Poppins** | 400, 500, 600, 700, 800 | Display (`fontFamilyDisplay`) — headings, brand title |
| **Inter** | 400, 500, 600, 700 | Body (`fontFamilyBody`) — labels, body, navigation |
| **Manrope** | 400, 700, 800 | Available but not used in `EGoTypography` |

### Icons
- **Material Icons** (bundled via `uses-material-design: true`) — the full icon set.
- **No icon packages** (lucide, font_awesome, etc.) are installed.
- Current profile screen uses: `Icons.edit_outlined`, `Icons.history`, `Icons.bookmark_border`, `Icons.payments_outlined`, `Icons.help_outline`, `Icons.notifications_outlined`, `Icons.settings_outlined`, `Icons.info_outline`, `Icons.logout`, `Icons.chevron_right`, `Icons.person`.

### Logo Assets
`EgoLogo` widget uses SVG/PNG assets from `assets/branding/`:
- `.primary` → `EgoBrandAssets.logoPrimary`
- `.icon` → `EgoBrandAssets.logoIcon`  
- `.wordmark` → `EgoBrandAssets.logoWordmark`

---

## 6. Existing Reusable Components (core/shared/widgets)

### Buttons (`shared/widgets/buttons.dart`)

| Widget | Description |
|--------|-------------|
| `EGoPrimaryButton` | Filled yellow pill; supports `icon`, `isLoading`, `height`, `isFullWidth` |
| `EGoSecondaryButton` | Outlined navy border pill; same props minus `isLoading` |
| `EGoTextButton` | Minimal text button with optional leading icon |
| `EGoIconButton` | Circular icon button with shadow + background |
| `EGoFloatingActionButton` | FAB; supports `extended` + `label` |

### Common (`shared/widgets/common.dart`)

| Widget | Description |
|--------|-------------|
| `EGoSectionHeader` | Row with title + optional action TextButton |
| `EGoLabeledDivider` | Horizontal divider with optional centered label |
| `EGoEmptyState` | Centered icon + title + subtitle + optional CTA |
| `EGoLoadingOverlay` | Semi-transparent navy overlay with circular progress |
| `EGoBanner` | Colored info banner with icon, text, action, dismiss |

### Bottom Nav (`shared/widgets/bottom_nav_bar.dart`)

| Widget | Description |
|--------|-------------|
| `EGoBottomNavBar` | 4-tab animated nav bar; `selectedIndex`, `onTap`, `profileLabel`, `showGestureIndicator` |

### Branding (`core/branding/widgets/ego_logo.dart`)

| Widget | Variants |
|--------|---------|
| `EgoLogo` | `.primary`, `.icon`, `.wordmark`; `height`, `width`, `color`, `fit` |

---

## 7. Current `profile_screen.dart` — What It Does Now

### Structure
```
Scaffold (backgroundColor: brandBackground)
  AppBar
    title: 'Account'
    actions: [IconButton(Icons.edit_outlined → /edit-profile)]
  body: SingleChildScrollView
    Column
      1. Profile Header (white card, all(24) padding)
         - 80×80 circle avatar (yellow-light bg, initials or person icon)
         - name (titleLarge)
         - phone (bodyMedium, grey500)
         - email? (bodySmall, grey500) [conditional]
      2. SizedBox(16)
      3. _MenuSection("Rides")
         - My rides → /my-rides
         - Saved places → /saved-places
      4. SizedBox(12)
      5. _MenuSection("Payments")
         - Payment methods → /payment-methods
      6. SizedBox(12)
      7. _MenuSection("Help")
         - Help & Support → /help-support
         - Notifications → /notifications
      8. SizedBox(12)
      9. _MenuSection("App")
         - Settings → /settings
         - About E-GO → /about
      10. SizedBox(20)
      11. Logout button (EGoSecondaryButton, horizontal(16) padding)
      12. SizedBox(24)
      13. EgoLogo.wordmark(height:18, grey400)
      14. Text('Move your way · Jhargram', labelSmall, grey400)
      15. SizedBox(32)
```

### Private Classes
- `_MenuSection` — Column of section-title label + white `Container` of `ListTile`s with dividers
- `_MenuItem` — simple data class (icon, label, onTap)

### ListTile anatomy (in `_MenuSection`):
- **leading:** 36×36 `Container` (grey100 bg, radiusMedium), 20px icon (grey700)
- **title:** `bodyMedium` text
- **trailing:** `Icons.chevron_right` (grey400)
- **contentPadding:** symmetric(horizontal: 16, vertical: 2)
- Divider at `height:1, indent:68` between items (not after last)

---

## 8. Component Inventory (HTML Reference Design)

Based on the brief and standard Rapido/Uber-style profile screens, the full component inventory expected in the redesigned screen (in visual order, top to bottom):

### Header Section
1. **Back / Close button** (top-left, AppBar or custom)
2. **Screen title** ("Account" or "Profile") — Poppins SemiBold
3. **Edit button** (top-right, `Icons.edit_outlined`)
4. **Avatar circle** — 72–80px diameter, yellow-light bg, initials or person icon
5. **User name** — `titleLarge` (Poppins 22 w600)
6. **Phone number** — `bodyMedium` (Inter 14, grey500)
7. **Email** (conditional) — `bodySmall` (Inter 12, grey500)
8. **"Edit Profile" text link or button** (optional secondary CTA)

### Section: Rides
9. Section label "Rides" — `labelMedium`, grey500, uppercase tracking
10. Row: **My Rides** — `Icons.history` / `Icons.electric_rickshaw_outlined`, chevron right
11. Row: **Saved Places** — `Icons.bookmark_border`, chevron right

### Section: Payments
12. Section label "Payments"
13. Row: **Payment Methods** — `Icons.payments_outlined`, chevron right

### Section: Help & Support
14. Section label "Help"
15. Row: **Help & Support** — `Icons.help_outline`, chevron right
16. Row: **Notifications** — `Icons.notifications_outlined`, chevron right

### Section: App
17. Section label "App"
18. Row: **Settings** — `Icons.settings_outlined`, chevron right
19. Row: **About E-GO** — `Icons.info_outline`, chevron right

### Footer
20. **Log Out** button — `EGoSecondaryButton` or destructive outlined button, `Icons.logout`
21. **EgoLogo wordmark** (muted grey, h=18) + tagline "Move your way · Jhargram"

---

## 9. Important Dimensions & Design Tokens

### Spacing (from `EGoSpacing`)
| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Micro gaps |
| `sm` | 8px | Small gaps |
| `md` | 12px | Padding, divider indent base |
| `lg` | 16px | Standard horizontal padding |
| `xl` | 20px | Card internal padding (reference design) |
| `xxl` | 24px | Header section padding |
| `xxxl` | 32px | Large vertical gaps |
| `huge` | 48px | Oversized sections |

### Component Sizes
| Component | Size | Source |
|-----------|------|--------|
| Avatar (profile) | 80×80px | `profile_screen.dart` |
| Avatar (edit profile) | 90×90px | `edit_profile_screen.dart` |
| Icon container (menu row) | 36×36px | `profile_screen.dart` |
| Icon inside container | 20px | `profile_screen.dart` |
| ListTile vertical padding | 2px | `contentPadding` |
| Standard row height | ~72px | ListTile default + 2px vert padding |
| Standard button height | 48px | `EGoSpacing.buttonHeight` |
| Large button height | 56px | `EGoSpacing.buttonHeightLarge` |
| CTA button in home | 54px | `home_screen.dart` |
| Logout button (reference) | 54px | `home_screen.dart` CTA pattern |

### Border Radii
| Token | Value | Usage |
|-------|-------|-------|
| `radiusSmall` | 4px | Badge corners |
| `radiusMedium` | 8px | Icon container in menu rows |
| `radiusLarge` | 12px | Cards in settings/payment |
| `radiusXLarge` | 16px | Card radius (reference: 16px) |
| `radiusPill` | 24px | Buttons |
| `radiusRound` | 9999px | Circular elements |
| `radiusCard` | 16px | `radiusXLarge` alias |
| `radiusInput` | 16px | Text fields |
| `radiusSheet` | 24px | Bottom sheets |

### Colors (key tokens)
| Token | Hex | Usage |
|-------|-----|-------|
| `brandPrimary` / `brandYellow` | `#FFC928` | Primary CTA, active nav |
| `brandNavy` / `onPrimary` | `#142B45` | Text on yellow, appbar icons |
| `brandBackground` | `#F5F7FA` | Scaffold background |
| `surface` / `white` | `#FFFFFF` | Card/section backgrounds |
| `surfaceVariant` | `#F3F4F6` | Input fills, icon bg |
| `grey100` | `#F3F4F6` | Icon container bg in menu |
| `grey400` | `0x66142B45` | Chevrons, muted text |
| `grey500` | `0x80142B45` | Section labels, placeholder text |
| `grey700` | `0xBF142B45` | Icon color in menu containers |
| `outlineVariant` / `divider` | `0x1F142B45` | Dividers, card borders |
| `error` | `#DC2626` | Logout button destructive |
| `success` | `#059669` | Cash payment active badge |

---

## 10. Potential Implementation Risks

### R1 — `EgoLogo` import path confusion
`profile_screen.dart` already uses `EgoLogo.wordmark(...)` which comes through `lib/app/theme/index.dart` → `lib/core/branding/ego_brand.dart`. This is the correct barrel import. Any new screen must `import 'package:e_go/app/theme/index.dart'` to get both theme tokens and branding.

### R2 — Duplicate logout logic
Logout is duplicated across `profile_screen.dart` and `settings_screen.dart`. The coordinator may want this extracted into a shared helper (e.g. `EGoLogoutHelper.showDialog(context)`). Adding a third copy increases technical debt.

### R3 — `AuthUser.phone` is immutable
The `updateProfile` path in `MockAuthRepository` only updates `name`, `email`, `isProfileComplete`, and `hasCompletedOnboarding`. Phone cannot be changed. Any UI that suggests editing phone will silently not persist.

### R4 — Avatar is initials-only, no image upload
No `image_picker` or photo storage is in `pubspec.yaml`. Avatar remains a text-initial circle. If the reference HTML shows a camera icon for photo upload, that would require a new package.

### R5 — `EGoSecondaryButton` default height is 48px
Reference design shows a 54px logout button (matching home CTA). To hit 54px, pass `height: 54` to `EGoSecondaryButton`.

### R6 — No `EgoBottomNavBar` in profile screen
Profile is currently a standalone `Scaffold` pushed from home. The bottom nav is not shown. If the redesign requires a persistent bottom nav on profile, the routing strategy needs to change to a shell/tab structure (significant refactor).

### R7 — Provider context mounting check on logout
Both existing logout handlers check `if (context.mounted)` before navigating. Any new implementation must do the same to avoid `setState() called after dispose` crashes.

### R8 — `_MenuSection` is private
The current `_MenuSection` / `_MenuItem` are private classes in `profile_screen.dart`. If they need to be shared with a redesigned screen in a new file, they should be promoted to `lib/shared/widgets/` or `lib/features/account/presentation/widgets/`.

### R9 — Route name collision for `settings`
`EGoRouter.settings` conflicts with the `RouteSettings settings` parameter name inside `generateRoute()`. The router handles this with `EGoRouter.settings` disambiguation. Any new code referencing the settings route should use the full `EGoRouter.settings` qualifier.

---

## 11. Recommended Files to Create / Modify

### Modify (replace implementation)
| File | Change |
|------|--------|
| `lib/features/account/presentation/profile_screen.dart` | Full widget rebuild with new design; keep `ProfileScreen` class name and import paths |

### Optionally Extract (refactor, not required for MVP)
| File | Rationale |
|------|-----------|
| `lib/features/account/presentation/widgets/profile_menu_section.dart` | Extract `_MenuSection` as a public widget for reuse |
| `lib/features/account/presentation/widgets/profile_menu_item.dart` | Extract `_MenuItem` model |
| `lib/shared/utils/logout_helper.dart` | Shared `showLogoutDialog(context)` to eliminate duplication |

### No Changes Required
| File | Why |
|------|-----|
| `lib/app/router.dart` | All routes already defined |
| `lib/app/app_state.dart` | `logout()`, `updateProfile()` are complete |
| `lib/features/auth/**` | No auth changes needed |
| `lib/app/theme/**` | All design tokens are in place |
| `lib/shared/widgets/**` | All reusable components exist |
| `pubspec.yaml` | No new packages needed for the profile screen redesign |
| `edit_profile_screen.dart` | Already handles name + email editing |
| Other account screens | Untouched |

---

## 12. Import Template for New/Modified Screens

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';          // EGoColors, EGoTypography, EGoSpacing, EgoLogo
import 'package:e_go/shared/widgets/buttons.dart';   // EGoPrimaryButton, EGoSecondaryButton
import 'package:e_go/shared/widgets/common.dart';    // EGoSectionHeader, EGoEmptyState, etc.
```

---

*End of research document.*
