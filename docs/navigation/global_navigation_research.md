# E-GO Global Navigation — Research Report

> **Agent:** RESEARCHER  
> **Date:** 2026-11-17  
> **Objective:** Inspect the existing navigation architecture and identify the root cause of why the bottom navigation currently appears only on Home.

---

## 1. Application Entry Point & Navigation Architecture

- **Main Entry Point:** `lib/main.dart`
  - Calls `runApp(const EGoApp())`.
- **Root Application Widget:** `lib/app/app.dart` (`EGoApp` / `_EGoMaterialApp`)
  - Provides `AppState` via `ChangeNotifierProvider`.
  - Configures `MaterialApp` with:
    - `initialRoute: EGoRouter.splash`
    - `onGenerateRoute: (settings) => EGoRouter.generateRoute(settings, ...)`
- **Routing Engine:** `lib/app/router.dart` (`EGoRouter`)
  - Pure Flutter `Navigator 1.0` with `MaterialPageRoute` in a centralized `switch(settings.name)`.
  - No third-party routing packages (no GoRouter, no auto_route, no Beamer).

---

## 2. Route Inventory & Classification

### A. Primary Application Destinations (Should Show Bottom Navigation)
1. **Home:** `EGoRouter.home = '/home'` -> `EGoHomeScreen` (`lib/features/home/presentation/home_screen.dart`)
2. **Rides:** `EGoRouter.myRides = '/my-rides'` -> `MyRidesScreen` (`lib/features/rides/presentation/screens/my_rides_screen.dart`)
3. **Safety:** `EGoRouter.safety = '/safety'` -> `SafetyScreen` (`lib/features/safety/presentation/screens/safety_screen.dart`)
4. **Account:** `EGoRouter.profile = '/profile'` -> `ProfileScreen` (`lib/features/account/presentation/profile_screen.dart`)

### B. Secondary / Child Screens (Must Hide Bottom Navigation)
- **Module A: Onboarding & Authentication**
  - `EGoRouter.splash = '/'` -> `SplashScreen`
  - `EGoRouter.onboarding = '/onboarding'` -> `OnboardingScreenOne`
  - `EGoRouter.onboardingTwo = '/onboarding-2'` -> `OnboardingScreenTwo`
  - `EGoRouter.onboardingThree = '/onboarding-3'` -> `OnboardingScreenThree`
  - `EGoRouter.login = '/login'` -> `LoginScreen`
  - `EGoRouter.createAccount = '/create-account'` -> `CreateAccountScreen`
  - `EGoRouter.register = '/register'` -> `CreateAccountScreen`
  - `EGoRouter.otp = '/otp'` -> `OtpScreen`
  - `EGoRouter.profileSetup = '/profile-setup'` -> `ProfileSetupScreen`
- **Module B: Location & Waypoints**
  - `EGoRouter.pickupSelection = '/pickup-selection'` -> `PickupSelectionScreen`
  - `EGoRouter.destinationSelection = '/destination-selection'` -> `DestinationSelectionScreen`
  - `EGoRouter.savedPlaces = '/saved-places'` -> `SavedPlacesScreen`
- **Module C: Booking & Trip Lifecycle**
  - `EGoRouter.vehicleSelection = '/vehicle-selection'` -> `VehicleSelectionScreen`
  - `EGoRouter.fareDetails = '/fare-details'` -> `FareDetailsScreen`
  - `EGoRouter.bookingConfirmation = '/booking-confirmation'` -> `BookingConfirmationScreen`
  - `EGoRouter.searchingDriver = '/searching-driver'` -> `SearchingDriverScreen`
  - `EGoRouter.driverAssigned = '/driver-assigned'` -> `DriverAssignedScreen`
  - `EGoRouter.rideTracking = '/ride-tracking'` -> `RideTrackingScreen`
  - `EGoRouter.tripCompleted = '/trip-completed'` -> `TripCompletedScreen`
  - `EGoRouter.rideRating = '/ride-rating'` -> `RideRatingScreen`
- **Module D: Account Details & Support**
  - `EGoRouter.rideDetails = '/ride-details'` -> `RideDetailsScreen`
  - `EGoRouter.editProfile = '/edit-profile'` -> `EditProfileScreen`
  - `EGoRouter.paymentMethods = '/payment-methods'` -> `PaymentMethodsScreen`
  - `EGoRouter.notifications = '/notifications'` -> `NotificationsScreen`
  - `EGoRouter.helpSupport = '/help-support'` -> `HelpSupportScreen`
  - `EGoRouter.settings = '/settings'` -> `SettingsScreen`
  - `EGoRouter.about = '/about'` -> `AboutScreen`

---

## 3. Current Widget Hierarchy & Navigation State

Currently, the widget hierarchy is structured as:
```
MaterialApp
 └─ Navigator
     ├─ Route('/'): SplashScreen
     ├─ Route('/home'): EGoHomeScreen
     │   └─ Scaffold
     │       ├─ body: Column(MapSection, BookingPanel)
     │       └─ bottomNavigationBar: EgoGooeyBottomNavigation  <-- Placed directly here!
     ├─ Route('/my-rides'): MyRidesScreen
     │   └─ Scaffold(appBar, body)                             <-- No bottom nav
     ├─ Route('/safety'): SafetyScreen
     │   └─ Scaffold(appBar, body)                             <-- No bottom nav
     └─ Route('/profile'): ProfileScreen
         └─ Scaffold(appBar, body)                             <-- No bottom nav
```

---

## 4. Root Cause Analysis

1. **Local Widget Ownership instead of Shell Ownership:**
   `EgoGooeyBottomNavigation` was attached directly to `EGoHomeScreen`'s `Scaffold.bottomNavigationBar`.
2. **Push Navigation Between Primary Tabs:**
   When a user on `EGoHomeScreen` tapped Rides, Safety, or Account, `_onBottomNavTap` executed `Navigator.pushNamed(context, EGoRouter.myRides)`.
   This pushed `MyRidesScreen` (or `SafetyScreen`, `ProfileScreen`) as a separate full-screen route on top of `EGoHomeScreen`. Because those screens are standalone Scaffolds without `bottomNavigationBar`, the bottom navigation bar vanished completely.
3. **Absence of a Shared Main Shell:**
   There is currently no shared application shell hosting the four primary destinations together.
4. **Conclusion:**
   The bottom navigation bar must be removed from `EGoHomeScreen` and elevated to a dedicated shared `EGoMainShell` widget. All four primary destinations must live inside this shell, while child screens must be pushed on the Navigator stack outside the shell.

