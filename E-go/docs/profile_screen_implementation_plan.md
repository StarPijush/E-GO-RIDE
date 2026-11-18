# E-GO Profile Screen — Implementation Plan

> **Agent 3 (Reasoner) output.** Based on research doc + source analysis.  
> Generated: 2026-11-16  
> **Target file:** `lib/features/account/presentation/profile_screen.dart`  
> **No other files need to change.**

---

## 1. Component Hierarchy

All private widgets stay in `profile_screen.dart`. No new files are needed.

```
ProfileScreen (StatelessWidget)
│
├── Scaffold
│   ├── AppBar → _ProfileAppBar (custom AppBar)
│   └── body: SingleChildScrollView
│       └── Column
│           ├── _ProfileHeroCard         ← yellow card, avatar, name, phone, edit btn
│           ├── SizedBox(height: 20)
│           ├── _SectionLabel("ACTIVITY")
│           ├── _MenuCard                ← Activity: My rides + Saved places
│           ├── SizedBox(height: 20)
│           ├── _SectionLabel("PAYMENTS")
│           ├── _MenuCard                ← Payment methods
│           ├── SizedBox(height: 20)
│           ├── _SectionLabel("PREFERENCES")
│           ├── _MenuCard                ← Notifications + App settings
│           ├── SizedBox(height: 20)
│           ├── _SectionLabel("SUPPORT")
│           ├── _MenuCard                ← Help & support + About E-GO
│           ├── SizedBox(height: 24)
│           ├── _LogoutButton            ← full-width, red border
│           ├── SizedBox(height: 28)
│           ├── _FooterLogo              ← EgoLogo.wordmark + tagline
│           └── SizedBox(height: 32)
│
├── _ProfileHeroCard (StatelessWidget)
├── _SectionLabel (StatelessWidget)
├── _MenuCard (StatelessWidget)        ← wraps list of _MenuRow
├── _MenuRow (StatelessWidget)         ← single tappable row (replaces old _MenuItem)
├── _LogoutButton (StatelessWidget)
├── _FooterLogo (StatelessWidget)
└── _MenuItem (data class)             ← icon, label, route — keep as-is or inline
```

> **Why rename `_MenuSection` → `_MenuCard` + `_SectionLabel`?**  
> The reference design separates the section header label (muted grey, 11px uppercase) from the white card body. The existing `_MenuSection` combines both. Splitting into two private widgets makes the new visual language explicit, but the old private class can be refactored in-place — the class name is not part of the public API.

---

## 2. Exact Widget Tree per Component

### 2.1 AppBar

```dart
AppBar(
  backgroundColor: EGoColors.brandBackground,  // #F5F7FA
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: EGoColors.brandNavy),
    onPressed: () => Navigator.pop(context),
    tooltip: 'Back',
  ),
  title: Text(
    'Account',
    style: EGoTypography.titleMedium.copyWith(
      fontFamily: EGoTypography.fontFamilyDisplay, // Poppins
      fontWeight: FontWeight.w600,
      color: EGoColors.brandNavy,
    ),
  ),
  // No trailing actions
)
```

> **Note:** The reference design has a back arrow on the left and NO edit button in the top-right. The edit action is now inside the hero card. Remove the existing `actions: [IconButton(Icons.edit_outlined)]`.

---

### 2.2 Profile Hero Card (`_ProfileHeroCard`)

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),         // EGoSpacing.xl
    decoration: BoxDecoration(
      color: EGoColors.brandYellow,            // #FFC928
      borderRadius: BorderRadius.circular(16), // EGoSpacing.radiusXLarge
      boxShadow: [
        BoxShadow(
          color: EGoColors.shadow,             // Color(0x1A142B45)
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: EGoColors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: profile.name.isNotEmpty
                ? Text(
                    profile.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: EGoTypography.fontFamilyDisplay,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: EGoColors.brandNavy,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 44,
                    color: EGoColors.brandNavy,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        // Name + phone
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.name.isNotEmpty ? profile.name : 'Set up profile',
                style: const TextStyle(
                  fontFamily: EGoTypography.fontFamilyDisplay,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: EGoColors.brandNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                profile.phone.isNotEmpty ? profile.phone : '—',
                style: TextStyle(
                  fontFamily: EGoTypography.fontFamilyBody,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: EGoColors.brandNavy.withOpacity(0.80),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Circular edit button
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, EGoRouter.editProfile),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: EGoColors.brandNavy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: EGoColors.white,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  ),
)
```

**Layout note:** The hero card uses a horizontal `Row` (avatar | name+phone | edit button). This matches the reference design and is more compact than the current vertical `Column` layout.

---

### 2.3 Section Label (`_SectionLabel`)

```dart
// Usage: _SectionLabel('ACTIVITY')
Padding(
  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
  child: Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontFamily: EGoTypography.fontFamilyBody, // Inter
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.04 * 11, // ≈ 0.44 — or use a fixed 1.5
      color: Color(0xFF8490A0),  // muted grey — closest to EGoColors.grey500
    ),
  ),
)
```

> `EGoColors.grey500` resolves to `Color(0x80142B45)` (50% navy, translucent). The reference design uses an **opaque** `#8490A0`. Use the literal `Color(0xFF8490A0)` or `Color(0xFF778397)` for a solid muted grey. If the theme is later updated, replace with `EGoColors.grey500` once it is set to an opaque value.

---

### 2.4 Menu Card (`_MenuCard`)

```dart
// Usage: _MenuCard(items: [...])
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    decoration: BoxDecoration(
      color: EGoColors.white,
      borderRadius: BorderRadius.circular(16), // radiusXLarge
      border: Border.all(
        color: const Color(0xFFE7EAF0),        // border/divider token
        width: 1,
      ),
    ),
    child: Column(
      children: List.generate(items.length, (i) {
        return Column(
          children: [
            _MenuRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 68,     // 16 (hpad) + 36 (icon container) + 16 (gap)
                endIndent: 0,
                color: Color(0xFFE7EAF0),
              ),
          ],
        );
      }),
    ),
  ),
)
```

---

### 2.5 Menu Row (`_MenuRow`)

```dart
// _MenuRow replaces existing ListTile approach (keeps same anatomy)
SizedBox(
  height: 72,
  child: InkWell(
    onTap: item.onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Icon container — 36×36 grey100 bg, 8px radius
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: EGoColors.grey100,            // #F3F4F6
              borderRadius: BorderRadius.circular(8), // radiusMedium
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: EGoColors.grey700,            // 0xBF142B45 (strong navy)
            ),
          ),
          const SizedBox(width: 16),
          // Label — expands to push chevron right
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontFamily: EGoTypography.fontFamilyBody, // Inter
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: EGoColors.brandNavy,
              ),
            ),
          ),
          // Chevron
          const Icon(
            Icons.chevron_right,
            color: EGoColors.grey400,  // 0x66142B45
            size: 24,
          ),
        ],
      ),
    ),
  ),
)
```

> **Why `SizedBox(height:72)` instead of `ListTile`?** The reference design specifies exactly 72dp rows. Using an explicit `SizedBox` + `InkWell` gives reliable pixel-accurate heights. `ListTile` with `contentPadding: vertical(2)` also works but its minimum height is theme-dependent.  
> **Alternative (keep ListTile):** Keep the existing `ListTile` approach with `minVerticalPadding: 16` to reach ~72px, which is simpler and handles accessibility scaling correctly.

---

### 2.6 Logout Button (`_LogoutButton`)

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: SizedBox(
    width: double.infinity,
    height: 54,
    child: OutlinedButton.icon(
      onPressed: () => _showLogoutDialog(context),
      icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
      label: const Text(
        'Log out',
        style: TextStyle(
          fontFamily: EGoTypography.fontFamilyBody,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFDC2626),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: EGoColors.white,
        side: const BorderSide(color: Color(0xFFDC2626), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // between radiusLarge(12) and radiusXLarge(16)
        ),
      ),
    ),
  ),
)
```

> **Alternative:** Use `EGoSecondaryButton(label: 'Log out', icon: ..., height: 54)` and override border color via `style` prop if supported, or just use `OutlinedButton.icon` directly for full control.

---

### 2.7 Footer Logo (`_FooterLogo`)

```dart
Column(
  children: [
    Center(
      child: EgoLogo.wordmark(height: 18, color: EGoColors.grey400),
    ),
    const SizedBox(height: 4),
    Center(
      child: Text(
        'Move your way · Jhargram',
        style: EGoTypography.labelSmall.copyWith(
          color: EGoColors.grey400,
        ),
      ),
    ),
  ],
)
```

---

## 3. Accessing AuthUser from AppState

The app uses `Provider` with `ChangeNotifierProvider<AppState>` registered at the root in `app.dart`.

### Pattern used in existing `profile_screen.dart`

```dart
// In build():
final profile = context.watch<AppState>().profile;
```

`context.watch<AppState>()` subscribes to `AppState` and rebuilds when `notifyListeners()` is called (e.g., after `updateProfile()` or `logout()`).

### Field access

```dart
// AuthUser fields:
profile.name          // String — empty string if not set
profile.phone         // String — normalized '+91XXXXXXXXXX'; empty if not set
profile.email         // String? — nullable; null if not set
profile.isProfileComplete        // bool
profile.hasCompletedOnboarding   // bool
```

### Defensive display

```dart
// Name: show placeholder if empty
profile.name.isNotEmpty ? profile.name : 'Set up profile'

// Phone: show em-dash if empty
profile.phone.isNotEmpty ? profile.phone : '—'

// First initial for avatar
profile.name.isNotEmpty ? profile.name[0].toUpperCase() : null
// If null → show Icons.person instead of text initial

// Email (not shown in reference design, skip unless confirmed by designer)
```

### Read-only (no need for `context.read` in build)

```dart
// context.read is used ONLY in callbacks (not in build):
onPressed: () async {
  await context.read<AppState>().logout();
  ...
}
```

---

## 4. Exact Route Names per Menu Item

All routes are confirmed in `lib/app/router.dart`. Use the `EGoRouter` constants directly — never string literals.

| Screen label       | `Navigator.pushNamed` call                              | Constant value       |
|--------------------|--------------------------------------------------------|----------------------|
| Edit profile (hero btn) | `Navigator.pushNamed(context, EGoRouter.editProfile)` | `'/edit-profile'`  |
| My rides           | `Navigator.pushNamed(context, EGoRouter.myRides)`      | `'/my-rides'`        |
| Saved places       | `Navigator.pushNamed(context, EGoRouter.savedPlaces)`  | `'/saved-places'`    |
| Payment methods    | `Navigator.pushNamed(context, EGoRouter.paymentMethods)` | `'/payment-methods'` |
| Notifications      | `Navigator.pushNamed(context, EGoRouter.notifications)` | `'/notifications'`  |
| App settings       | `Navigator.pushNamed(context, EGoRouter.settings)`     | `'/settings'`        |
| Help & support     | `Navigator.pushNamed(context, EGoRouter.helpSupport)`  | `'/help-support'`    |
| About E-GO         | `Navigator.pushNamed(context, EGoRouter.about)`        | `'/about'`           |
| Logout → Login     | See §5 below                                           | `'/login'`           |

> **Route name disambiguation:** Inside `router.dart`, `EGoRouter.settings` is used as `case EGoRouter.settings:` to avoid shadowing the `RouteSettings settings` parameter. In `profile_screen.dart` there is no ambiguity — use `EGoRouter.settings` directly.

---

## 5. Logout — Exact Code Pattern

Reuse the existing `_showLogoutDialog` method from the current file verbatim. No changes needed:

```dart
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);                        // close dialog first
            await context.read<AppState>().logout();       // clear session
            if (context.mounted) {                         // ← REQUIRED mounted check
              Navigator.pushNamedAndRemoveUntil(
                context,
                EGoRouter.login,
                (_) => false,                              // remove all routes
              );
            }
          },
          child: Text(
            'Log out',
            style: TextStyle(color: EGoColors.error),     // Color(0xFFDC2626)
          ),
        ),
      ],
    ),
  );
}
```

**What `AppState.logout()` does (confirmed):**
1. `await _customerRepo.logout()` — clears persisted session
2. `_profile = AuthUser.empty` — resets user
3. `_isAuthenticated = false`
4. `_error = null`
5. `_resetBooking()` — clears all booking state
6. `notifyListeners()` — rebuilds listeners

---

## 6. All Color Values as Flutter `Color` Literals

| Role | Token | Flutter literal | Hex |
|------|-------|-----------------|-----|
| Scaffold/AppBar background | `EGoColors.brandBackground` | `Color(0xFFF5F7FA)` | `#F5F7FA` |
| Hero card background | `EGoColors.brandYellow` | `Color(0xFFFFC928)` | `#FFC928` |
| Navy text / icons | `EGoColors.brandNavy` | `Color(0xFF142B45)` | `#142B45` |
| White card bg | `EGoColors.white` | `Color(0xFFFFFFFF)` | `#FFFFFF` |
| Icon container bg | `EGoColors.grey100` | `Color(0xFFF3F4F6)` | `#F3F4F6` |
| Icon color (in container) | `EGoColors.grey700` | `Color(0xBF142B45)` | 75% navy |
| Chevron color | `EGoColors.grey400` | `Color(0x66142B45)` | 40% navy |
| Section header text | *(no token — use literal)* | `Color(0xFF8490A0)` | `#8490A0` |
| Card border / divider | *(use literal or `EGoColors.outlineVariant`)* | `Color(0xFFE7EAF0)` | `#E7EAF0` |
| Phone text (80% navy) | inline `.withOpacity(0.80)` | `EGoColors.brandNavy.withOpacity(0.80)` | — |
| Logout red | `EGoColors.error` | `Color(0xFFDC2626)` | `#DC2626` |
| Shadow | `EGoColors.shadow` | `Color(0x1A142B45)` | 10% navy |

> **Caveat on `EGoColors.grey500`:** It resolves to `Color(0x80142B45)` — a 50%-opacity navy, which appears as a washed-out muted blue-grey over white. The reference design's `#8490A0` is an **opaque** muted blue-grey. Use `const Color(0xFF8490A0)` for section headers to match the reference exactly. Consider adding an `EGoColors.sectionHeader = Color(0xFF8490A0)` token in a follow-up ticket.

> **Caveat on card border `#E7EAF0`:** `EGoColors.outlineVariant` → `navyDivider` → `Color(0x1F142B45)` ≈ 12% navy which renders as a faint grey. The reference uses an opaque `#E7EAF0`. Use `const Color(0xFFE7EAF0)` for now, or the closest opaque token `EGoColors.grey100` = `#F3F4F6` as a fallback.

---

## 7. All Spacing & Sizing Values (dp)

| Element | Value | Source token |
|---------|-------|-------------|
| Scaffold horizontal outer padding | 16 | `EGoSpacing.lg` |
| Hero card internal padding | 20 all sides | `EGoSpacing.xl` |
| Hero card border radius | 16 | `EGoSpacing.radiusXLarge` |
| Hero card shadow blur | 12 | — |
| Hero card shadow offset | (0, 4) | — |
| Avatar size | 80×80 | hardcoded |
| Avatar initial font size | 32 | — |
| Space between avatar and text | 16 | `EGoSpacing.lg` |
| Space between name and phone | 4 | `EGoSpacing.xs` |
| Space between text and edit button | 12 | `EGoSpacing.md` |
| Edit button circle size | 40×40 | — |
| Edit button icon size | 20 | — |
| Section gap (card to next section header) | 20 | `EGoSpacing.xl` |
| Section label bottom margin | 8 | `EGoSpacing.sm` |
| Menu card border radius | 16 | `EGoSpacing.radiusXLarge` |
| Menu card border width | 1 | `EGoSpacing.borderWidth` |
| Menu row height | 72 | — |
| Menu row horizontal padding | 16 | `EGoSpacing.lg` |
| Icon container size | 36×36 | — |
| Icon container border radius | 8 | `EGoSpacing.radiusMedium` |
| Icon size inside container | 20 | — |
| Gap: icon container → label | 16 | `EGoSpacing.lg` |
| Inset divider start indent | 68 | 16+36+16 |
| Logout button height | 54 | — |
| Logout button border radius | 14 | between radiusLarge(12) and radiusXLarge(16) |
| Logout button border width | 1 | — |
| Logout button top margin | 24 | `EGoSpacing.xxl` |
| Footer logo height | 18 | — |
| Footer tagline top margin | 4 | `EGoSpacing.xs` |
| Footer bottom margin | 32 | `EGoSpacing.xxxl` |

---

## 8. Font Usage — Poppins vs Inter

Both fonts are declared in `EGoTypography`:
- `EGoTypography.fontFamilyDisplay = 'Poppins'`
- `EGoTypography.fontFamilyBody = 'Inter'`

### Where to use each in the profile screen

| Element | Font | Weight | Size | Style token or literal |
|---------|------|--------|------|------------------------|
| AppBar title "Account" | Poppins | 600 | 16px | `EGoTypography.titleMedium.copyWith(fontFamily: 'Poppins', fontWeight: w600)` |
| Profile name | Poppins | 700 | 20px | `TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: w700)` |
| Phone number | Inter | 500 | 14px | `TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: w500)` |
| Section headers | Inter | 700 | 11px | `TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: w700, letterSpacing: ...)` |
| Menu row labels | Inter | 500 | 16px | `EGoTypography.titleMedium` *(already Inter 16 w500)* |
| Logout button label | Inter | 600 | 14px | `TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: w600)` |
| Footer tagline | Inter | 500 | 11px | `EGoTypography.labelSmall` *(already Inter 11 w500)* |

> **Convenience:** Existing `EGoTypography` tokens that match directly:
> - `EGoTypography.titleMedium` → Inter 16 w500 — perfect for menu row labels
> - `EGoTypography.titleSmall` → Inter 14 w500 — close to phone text
> - `EGoTypography.labelSmall` → Inter 11 w500 — footer tagline
>
> **Custom overrides needed:**
> - Profile name: `copyWith(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: EGoColors.brandNavy)`
> - Section headers: custom `TextStyle` (no token at 11px w700 uppercase)

---

## 9. Inset Divider Implementation

The `Divider` between rows inside a `_MenuCard` uses `indent` to skip the icon column:

```dart
const Divider(
  height: 1,         // total vertical space the widget occupies
  thickness: 1,      // visible line thickness
  indent: 68,        // 16 (card h-pad) + 36 (icon container) + 16 (gap)
  endIndent: 0,      // extends to card's right edge
  color: Color(0xFFE7EAF0),
)
```

**Why 68dp indent:**
```
16 (card left padding) + 36 (icon container width) + 16 (space between icon and label) = 68
```

The existing `profile_screen.dart` already uses `indent: 68` — keep this exact value.

**Placement:** Insert the `Divider` *between* rows (not after the last row), controlled by index:

```dart
for (int i = 0; i < items.length; i++) ...[
  _MenuRow(item: items[i]),
  if (i < items.length - 1)
    const Divider(height: 1, thickness: 1, indent: 68, color: Color(0xFFE7EAF0)),
],
```

---

## 10. Scrollable Layout Structure

Use **`SingleChildScrollView`** wrapping a `Column`. This is the simplest approach and matches the existing screen. `CustomScrollView` / `Slivers` are not needed here because:
- No collapsing AppBar is required (the AppBar stays fixed)
- No lazy-loading lists (all menu items are static)
- Total content height fits comfortably on most screens

```dart
body: SingleChildScrollView(
  physics: const BouncingScrollPhysics(),  // matches iOS feel; optional
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),          // top gap below AppBar
      _ProfileHeroCard(profile: profile),
      const SizedBox(height: 20),
      const _SectionLabel('ACTIVITY'),
      _MenuCard(items: activityItems),
      const SizedBox(height: 20),
      const _SectionLabel('PAYMENTS'),
      _MenuCard(items: paymentItems),
      const SizedBox(height: 20),
      const _SectionLabel('PREFERENCES'),
      _MenuCard(items: preferenceItems),
      const SizedBox(height: 20),
      const _SectionLabel('SUPPORT'),
      _MenuCard(items: supportItems),
      const SizedBox(height: 24),
      const _LogoutButton(),
      const SizedBox(height: 28),
      const _FooterLogo(),
      const SizedBox(height: 32),
    ],
  ),
),
```

> **Note on horizontal padding:** Each component (`_ProfileHeroCard`, `_MenuCard`, `_LogoutButton`) handles its own `Padding(horizontal: 16)` internally, so the `Column` does not need outer padding. `crossAxisAlignment: CrossAxisAlignment.stretch` ensures full-width containers fill available space.

---

## 11. Edge Cases

### E1 — Long name (overflow)
- Profile name in hero card: `maxLines: 1, overflow: TextOverflow.ellipsis`
- If name is > ~18 chars (e.g. "Rabindranath Tagore"), it truncates cleanly.
- **Demo user:** "E-GO Demo User" — 14 chars, safe.

### E2 — Empty / missing name
```dart
profile.name.isNotEmpty ? profile.name : 'Set up profile'
// Avatar: show Icons.person instead of initial
```

### E3 — Empty / missing phone
```dart
profile.phone.isNotEmpty ? profile.phone : '—'
```
Phone is normalized `+91XXXXXXXXXX` from login — will be non-empty for authenticated users.

### E4 — Null email
Email is `String?`. The reference design does not display email in the hero card, so no null-check needed there. If added in a future iteration: `if (profile.email != null && profile.email!.isNotEmpty) ...`

### E5 — Very long phone number
Phone is always `+91` + 10 digits = 13 chars. Fits on one line at 14px.

### E6 — `context.mounted` after async logout
```dart
await context.read<AppState>().logout();
if (context.mounted) {   // ← always check before navigation
  Navigator.pushNamedAndRemoveUntil(...);
}
```
Both existing screens (`profile_screen.dart`, `settings_screen.dart`) already do this.

### E7 — Saved places route exists but feature may be incomplete
`EGoRouter.savedPlaces = '/saved-places'` is defined and maps to `SavedPlacesScreen`. Navigation will work, but if the screen is a stub, that's acceptable for MVP.

### E8 — `EGoRouter.settings` name collision (router.dart only)
Inside `router.dart`, the `settings` parameter clashes with `EGoRouter.settings`. Handled by `case EGoRouter.settings:`. In `profile_screen.dart` this is not an issue — `EGoRouter.settings` resolves normally.

### E9 — Scaffold resize on keyboard
Profile screen has no text fields — `resizeToAvoidBottomInset` does not need to be set (defaults `true`, harmless here).

### E10 — `AuthUser.phone` immutability in `updateProfile`
The `phone` field cannot be changed via `AppState.updateProfile()`. The hero card correctly shows it as read-only display text with no edit affordance for the phone number specifically. Only the edit button navigates to `EditProfileScreen` (which only allows changing name and email).

---

## 12. Testing Strategy

### 12.1 Widget Tests (priority)

Write these tests in `test/features/account/presentation/profile_screen_test.dart`:

```
// ── Rendering ────────────────────────────────────────────────────────────
T1. ProfileScreen renders without error given a valid AuthUser
T2. Hero card shows correct user name from AppState.profile.name
T3. Hero card shows first letter initial in avatar circle
T4. Hero card shows '—' when profile.phone is empty
T5. Hero card shows Icons.person when profile.name is empty
T6. All 7 menu rows render (My rides, Saved places, Payment methods,
    Notifications, App settings, Help & support, About E-GO)
T7. All 4 section labels render (ACTIVITY, PAYMENTS, PREFERENCES, SUPPORT)
T8. Logout button renders with red text/border

// ── Navigation ───────────────────────────────────────────────────────────
T9.  Tapping hero edit button calls Navigator.pushNamed('/edit-profile')
T10. Tapping "My rides" row pushes '/my-rides'
T11. Tapping "Payment methods" row pushes '/payment-methods'
T12. Tapping "Notifications" row pushes '/notifications'
T13. Tapping "App settings" row pushes '/settings'
T14. Tapping "Help & support" row pushes '/help-support'
T15. Tapping "About E-GO" row pushes '/about'

// ── Logout dialog ─────────────────────────────────────────────────────────
T16. Tapping logout button shows AlertDialog with 'Log out?' title
T17. Tapping 'Cancel' in dialog closes dialog without calling AppState.logout
T18. Tapping 'Log out' in dialog calls AppState.logout()
T19. After logout, Navigator.pushNamedAndRemoveUntil to '/login' is called
T20. ProfileScreen does not navigate after logout if context is not mounted

// ── Edge cases ────────────────────────────────────────────────────────────
T21. Long name (30+ chars) is truncated with ellipsis and doesn't overflow
T22. Screen renders correctly with AuthUser.empty (no crash, placeholders shown)
```

### 12.2 Test Setup

```dart
// Minimal test harness
Widget buildTestApp({required AuthUser user}) {
  final appState = AppState();
  // Inject user via test-visible setter or mock AppState
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(
      onGenerateRoute: EGoRouter.generateRoute,
      home: const ProfileScreen(),
    ),
  );
}
```

> Since `AppState` uses `AuthRepository` internally, mock it with a `MockAuthRepository` pre-seeded with the desired `AuthUser`. Or create a minimal `FakeAppState extends AppState` that overrides `profile` getter.

### 12.3 Golden Tests (optional)

Take golden snapshots of:
- Hero card with long name (overflow check)
- Full screen on iPhone SE (375px) for compact layout
- Full screen on a large device (428px) for spacious layout

### 12.4 Accessibility Checks

- All `InkWell` / `GestureDetector` elements should have `Semantics` labels or use `Tooltip`.
- Avatar should have `Semantics(label: 'Profile avatar for $name')`.
- Logout button: `Semantics(label: 'Log out', button: true)`.

---

## 13. Full Section Data (Items List)

For the implementer — exact icon, label, and route for each menu row:

```dart
// ACTIVITY section
final activityItems = [
  _MenuItem(
    icon: Icons.history,
    label: 'My rides',
    onTap: () => Navigator.pushNamed(context, EGoRouter.myRides),
  ),
  _MenuItem(
    icon: Icons.bookmark_border,
    label: 'Saved places',
    onTap: () => Navigator.pushNamed(context, EGoRouter.savedPlaces),
  ),
];

// PAYMENTS section
final paymentItems = [
  _MenuItem(
    icon: Icons.account_balance_wallet_outlined,  // reference: account_balance_wallet
    label: 'Payment methods',
    onTap: () => Navigator.pushNamed(context, EGoRouter.paymentMethods),
  ),
];

// PREFERENCES section
final preferenceItems = [
  _MenuItem(
    icon: Icons.notifications_outlined,
    label: 'Notifications',
    onTap: () => Navigator.pushNamed(context, EGoRouter.notifications),
  ),
  _MenuItem(
    icon: Icons.settings_outlined,
    label: 'App settings',
    onTap: () => Navigator.pushNamed(context, EGoRouter.settings),
  ),
];

// SUPPORT section
final supportItems = [
  _MenuItem(
    icon: Icons.help_outline,
    label: 'Help & support',
    onTap: () => Navigator.pushNamed(context, EGoRouter.helpSupport),
  ),
  _MenuItem(
    icon: Icons.info_outline,
    label: 'About E-GO',
    onTap: () => Navigator.pushNamed(context, EGoRouter.about),
  ),
];
```

> **Icon changes from current screen:**
> - Payment methods: `Icons.payments_outlined` → `Icons.account_balance_wallet_outlined` (reference design)
> - App settings label: `'Settings'` → `'App settings'` (reference design)
> - Help & Support label: `'Help & Support'` → `'Help & support'` (consistent casing)

---

## 14. Diff Summary vs Current `profile_screen.dart`

| What changes | Current | New |
|---|---|---|
| AppBar edit action (top-right) | ✅ `IconButton(Icons.edit_outlined)` | ❌ removed (edit is now in hero card) |
| AppBar leading | default back button | explicit `IconButton(Icons.arrow_back)` with `EGoColors.brandNavy` |
| AppBar centerTitle | depends on theme | `centerTitle: true` explicit |
| Profile card bg | white (`EGoColors.surface`) | yellow (`EGoColors.brandYellow`) |
| Profile card layout | vertical Column | horizontal Row |
| Profile card padding | 24 all | 20 all |
| Edit button | removed from AppBar | circular navy button in hero card |
| Section headers | styled via `labelMedium` (12px, grey500) | 11px, opaque grey, uppercase, `fontWeight.w700` |
| Section card bg | flat `color: EGoColors.surface` | `Container` with border `Color(0xFFE7EAF0)`, radius 16 |
| Divider color | default theme divider | explicit `Color(0xFFE7EAF0)` |
| Logout button | `EGoSecondaryButton` (navy outline) | `OutlinedButton` with red border + red label |
| Logout button height | 48 (default) | 54 (explicit `SizedBox`) |
| Payment icon | `Icons.payments_outlined` | `Icons.account_balance_wallet_outlined` |
| Settings label | `'Settings'` | `'App settings'` |

---

## 15. Import Template

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';    // EGoColors, EGoTypography, EGoSpacing, EgoLogo
// No additional imports needed
```

> `EgoLogo` is re-exported from `lib/app/theme/index.dart` via the branding barrel, so no separate import is needed for it.

---

*End of implementation plan.*
