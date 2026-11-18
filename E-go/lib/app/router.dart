import 'package:flutter/material.dart';
import 'package:e_go/features/auth/presentation/splash_screen.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_one.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_two.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_three.dart';
import 'package:e_go/features/auth/presentation/login_screen.dart';
import 'package:e_go/features/auth/presentation/otp_screen.dart';
import 'package:e_go/features/auth/presentation/profile_setup_screen.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/features/location/presentation/map_location_picker_screen.dart';
import 'package:e_go/features/location/presentation/saved_places_screen.dart';
import 'package:e_go/features/booking/presentation/vehicle_selection_screen.dart';
import 'package:e_go/features/booking/presentation/place_order_screen.dart';
import 'package:e_go/features/booking/presentation/fare_details_screen.dart';
import 'package:e_go/features/booking/presentation/booking_confirmation_screen.dart';
import 'package:e_go/features/booking/presentation/searching_driver_screen.dart';
import 'package:e_go/features/booking/presentation/driver_assigned_screen.dart';
import 'package:e_go/features/booking/presentation/ride_tracking_screen.dart';
import 'package:e_go/features/booking/presentation/trip_completed_screen.dart';
import 'package:e_go/features/booking/presentation/ride_rating_screen.dart';
import 'package:e_go/features/rides/presentation/ride_details_screen.dart';
import 'package:e_go/features/account/presentation/edit_profile_screen.dart';
import 'package:e_go/features/account/presentation/payment_methods_screen.dart';
import 'package:e_go/features/account/presentation/settings_screen.dart';
import 'package:e_go/features/account/presentation/about_screen.dart';
import 'package:e_go/features/notifications/presentation/notifications_screen.dart';
import 'package:e_go/features/support/presentation/help_support_screen.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';
import 'package:e_go/shared/shell/ego_main_shell.dart';

/// E-GO application router.
/// Defines all navigation routes for the complete customer application.
class EGoRouter {
  // Module A: Onboarding & Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String onboardingTwo = '/onboarding-2';
  static const String onboardingThree = '/onboarding-3';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';

  // Module B: Home & Location
  static const String home = '/home';
  static const String locationSelection = '/location-selection';
  static const String mapLocationPicker = '/map-location-picker';
  static const String pickupSelection = '/pickup-selection';
  static const String destinationSelection = '/destination-selection';
  static const String savedPlaces = '/saved-places';

  // Module C: Vehicle Selection & Booking Lifecycle
  static const String vehicleSelection = '/vehicle-selection';
  static const String placeOrder = '/place-order';
  static const String fareDetails = '/fare-details';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String searchingDriver = '/searching-driver';
  static const String driverAssigned = '/driver-assigned';
  static const String rideTracking = '/ride-tracking';
  static const String tripCompleted = '/trip-completed';
  static const String rideRating = '/ride-rating';

  // Module D: Customer Account & Support
  static const String myRides = '/my-rides';
  static const String rideDetails = '/ride-details';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String paymentMethods = '/payment-methods';
  static const String notifications = '/notifications';
  static const String helpSupport = '/help-support';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String safety = '/safety';

  /// Routes that require an authenticated customer session.
  static const Set<String> protectedRoutes = {
    home,
    locationSelection,
    mapLocationPicker,
    pickupSelection,
    destinationSelection,
    savedPlaces,
    vehicleSelection,
    placeOrder,
    fareDetails,
    bookingConfirmation,
    searchingDriver,
    driverAssigned,
    rideTracking,
    tripCompleted,
    rideRating,
    myRides,
    rideDetails,
    profile,
    editProfile,
    paymentMethods,
    notifications,
    settings,
    safety,
  };

  /// Builds a route for [settings].
  ///
  /// When [isAuthenticated] is supplied (the real app does this), protected
  /// customer routes redirect to Login for unauthenticated sessions. Tests and
  /// previews that omit it retain direct access to route widgets.
  static Route<dynamic> generateRoute(
    RouteSettings settings, {
    bool Function()? isAuthenticated,
  }) {
    if (isAuthenticated != null &&
        !isAuthenticated() &&
        protectedRoutes.contains(settings.name)) {
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: const RouteSettings(name: login),
      );
    }

    switch (settings.name) {
      // Module A
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreenOne(),
          settings: settings,
        );
      case onboardingTwo:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreenTwo(),
          settings: settings,
        );
      case onboardingThree:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreenThree(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case createAccount:
      case register:
        return MaterialPageRoute(
          builder: (_) => const CreateAccountScreen(),
          settings: settings,
        );
      case otp:
        final phone = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone),
          settings: settings,
        );
      case profileSetup:
        return MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
          settings: settings,
        );

      // Module B
      case home:
        return MaterialPageRoute(
          builder: (_) => const EGoMainShell(initialIndex: 0),
          settings: settings,
        );
      case locationSelection:
        return MaterialPageRoute(
          builder: (_) => const LocationSelectionScreen(),
          settings: settings,
        );
      case mapLocationPicker:
        final target = settings.arguments;
        return MaterialPageRoute<MapLocationPickerResult>(
          builder: (_) => MapLocationPickerScreen(
            target: target is LocationSelectionTarget
                ? target
                : LocationSelectionTarget.destination,
          ),
          settings: settings,
        );
      case pickupSelection:
        return MaterialPageRoute<MapLocationPickerResult>(
          builder: (_) => const MapLocationPickerScreen(
            target: LocationSelectionTarget.pickup,
          ),
          settings: settings,
        );
      case destinationSelection:
        return MaterialPageRoute(
          builder: (_) => const LocationSelectionScreen(),
          settings: settings,
        );
      case savedPlaces:
        return MaterialPageRoute(
          builder: (_) => const SavedPlacesScreen(),
          settings: settings,
        );

      // Module C
      case vehicleSelection:
        return MaterialPageRoute(
          builder: (_) => const VehicleSelectionScreen(),
          settings: settings,
        );
      case placeOrder:
        return MaterialPageRoute(
          builder: (_) => const PlaceOrderScreen(),
          settings: settings,
        );
      case fareDetails:
        return MaterialPageRoute(
          builder: (_) => const FareDetailsScreen(),
          settings: settings,
        );
      case bookingConfirmation:
        return MaterialPageRoute(
          builder: (_) => const BookingConfirmationScreen(),
          settings: settings,
        );
      case searchingDriver:
        return MaterialPageRoute(
          builder: (_) => const SearchingDriverScreen(),
          settings: settings,
        );
      case driverAssigned:
        return MaterialPageRoute(
          builder: (_) => const DriverAssignedScreen(),
          settings: settings,
        );
      case rideTracking:
        return MaterialPageRoute(
          builder: (_) => const RideTrackingScreen(),
          settings: settings,
        );
      case tripCompleted:
        return MaterialPageRoute(
          builder: (_) => const TripCompletedScreen(),
          settings: settings,
        );
      case rideRating:
        return MaterialPageRoute(
          builder: (_) => const RideRatingScreen(),
          settings: settings,
        );

      // Module D
      case myRides:
        return MaterialPageRoute(
          builder: (_) => const EGoMainShell(initialIndex: 1),
          settings: settings,
        );
      case rideDetails:
        final ride = settings.arguments as RideRecord;
        return MaterialPageRoute(
          builder: (_) => RideDetailsScreen(ride: ride),
          settings: settings,
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const EGoMainShell(initialIndex: 3),
          settings: settings,
        );
      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case paymentMethods:
        return MaterialPageRoute(
          builder: (_) => const PaymentMethodsScreen(),
          settings: settings,
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );
      case helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
          settings: settings,
        );
      case EGoRouter.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
          settings: settings,
        );
      case safety:
        return MaterialPageRoute(
          builder: (_) => const EGoMainShell(initialIndex: 2),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text(
                'No route defined for ${settings.name}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          settings: settings,
        );
    }
  }
}
