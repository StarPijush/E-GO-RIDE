# E-GO Global Navigation — Architecture Specification

> **Agent:** REASONER  
> **Date:** 2026-11-17  
> **Objective:** Design the smallest, most reliable architecture that supports a single shared bottom navigation on all four primary destinations and hides it on all child screens.

---

## 1. Architectural Overview

The application architecture separates **Primary Destinations** from **Secondary / Child Routes**:

```
MaterialApp
 └─ Navigator
     ├─ Route('/'): SplashScreen
     ├─ Route('/login'): LoginScreen (Child — No Bottom Nav)
     ├─ Route('/destination-selection'): DestinationSelectionScreen (Child — No Bottom Nav)
     ├─ Route('/payment-methods'): PaymentMethodsScreen (Child — No Bottom Nav)
     │
     └─ Primary Shell Route (EGoMainShell)  <-- Owns EgoGooeyBottomNavigation
         ├─ Tab 0: EGoHomeScreen
         ├─ Tab 1: MyRidesScreen
         ├─ Tab 2: SafetyScreen
         └─ Tab 3: ProfileScreen
```

---

## 2. Shared Shell Design (`EGoMainShell`)

The shell is implemented in `lib/shared/shell/ego_main_shell.dart`.

### Responsibilities:
1. **Single Bottom Navigation Owner:**
   Houses the single instance of `EgoGooeyBottomNavigation` inside its `bottomNavigationBar` slot.
2. **Tab State & Preservation:**
   Uses Flutter's native `IndexedStack` to preserve the state of all four tabs (map position, booking sheet inputs, ride filters, safety scroll offsets, and profile details).
3. **Fluid Tab Switching:**
   When a user taps any of the 4 tabs, `EgoGooeyBottomNavigation` animates the yellow active pill, and the shell switches the active child widget smoothly without route recreation.
4. **Hardware & App Bar Back-Navigation:**
   Wraps the body in a `PopScope`:
   - If the user is on a non-Home primary tab (Rides, Safety, Account) and taps Back (or the top app bar back button), `PopScope` intercepts the pop and returns to the Home tab (index 0).
   - If the user is on the Home tab (index 0), `PopScope` allows the system pop (exiting or minimizing the application).

---

## 3. Route Engine Integration (`EGoRouter`)

In `lib/app/router.dart`, the four primary route entries are updated to target `EGoMainShell` with their respective destination indices:

```dart
case home:
  return MaterialPageRoute(
    builder: (_) => const EGoMainShell(initialIndex: 0),
    settings: settings,
  );
case myRides:
  return MaterialPageRoute(
    builder: (_) => const EGoMainShell(initialIndex: 1),
    settings: settings,
  );
case safety:
  return MaterialPageRoute(
    builder: (_) => const EGoMainShell(initialIndex: 2),
    settings: settings,
  );
case profile:
  return MaterialPageRoute(
    builder: (_) => const EGoMainShell(initialIndex: 3),
    settings: settings,
  );
```

All 26 secondary routes remain mapped to their respective screens as standard `MaterialPageRoute`s on the top-level Navigator.

---

## 4. Child Screen Push & Pop Dynamics

- When a primary screen triggers navigation to a child route (e.g. tapping "Payment methods" in `ProfileScreen` or "Choose your destination" in `EGoHomeScreen`):
  `Navigator.pushNamed(context, EGoRouter.paymentMethods)` pushes `PaymentMethodsScreen` on top of `EGoMainShell`.
- The child screen renders its own full-screen `Scaffold`.
- The bottom navigation is **completely hidden** by virtue of being beneath the pushed route.
- No visibility flags, no layout hacks, and no artificial white bottom padding exist on child screens.
- When the child screen pops (`Navigator.pop(context)`), `EGoMainShell` is restored with its previous active tab and bottom navigation intact.

---

## 5. Screen Decoupling

- `EGoHomeScreen` no longer renders a bottom navigation bar directly when hosted inside `EGoMainShell`.
- `MyRidesScreen`, `SafetyScreen`, and `ProfileScreen` remain completely untouched in their internal business logic and layouts.

