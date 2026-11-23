// E-GO application state.
// Central ChangeNotifier for booking lifecycle and app-level state.
// Implements the booking state machine with validated transitions.
//
// AUTH_MODE selects the auth repository (see lib/core/config/auth_config.dart).
// Mock mode is development-only; release builds refuse to start with it.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/booking_state.dart';
import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/auth/data/auth_repository_factory.dart';
import 'package:e_go/features/auth/domain/entities/auth_exception.dart';
import 'package:e_go/features/auth/domain/entities/auth_user.dart';
import 'package:e_go/features/auth/domain/repositories/auth_repository.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/booking/data/driver_repository.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';
import 'package:e_go/features/booking/domain/place_order_result.dart';
import 'package:e_go/features/location/data/current_location_service.dart';
import 'package:e_go/features/location/data/recent_destinations_store.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/notifications/data/notification_repository.dart';
import 'package:e_go/features/routing/domain/models/route_result.dart';
import 'package:e_go/features/routing/domain/services/route_service.dart';
import 'package:e_go/features/routing/data/services/caching_route_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    AuthRepository? authRepository,
    VehicleRepository? vehicleRepository,
    DriverRepository? driverRepository,
    MockBookingRepository? bookingRepository,
    CurrentLocationService? currentLocationService,
    RecentDestinationsStore? recentDestinationsStore,
    RouteService? routeService,
    this.driverSearchDelay = const Duration(seconds: 4),
  }) : _customerRepo = authRepository ?? createAuthRepository(),
       _vehicleRepo = vehicleRepository ?? MockVehicleRepository(),
       _driverRepo = driverRepository ?? MockDriverRepository(),
       _bookingRepo = bookingRepository ?? MockBookingRepository(),
       _currentLocationService =
           currentLocationService ?? const UnavailableCurrentLocationService(),
       _recentDestinationsStore =
           recentDestinationsStore ?? RecentDestinationsStore(),
       _routeService = routeService ?? CompositeRouteService() {
    _init();
  }

  // Repositories
  final AuthRepository _customerRepo;
  final VehicleRepository _vehicleRepo;
  final DriverRepository _driverRepo;
  final MockBookingRepository _bookingRepo;
  final CurrentLocationService _currentLocationService;
  final RecentDestinationsStore _recentDestinationsStore;
  final RouteService _routeService;
  final MockNotificationRepository _notificationRepo =
      MockNotificationRepository();

  /// Demo search duration, injectable so tests do not wait seconds.
  final Duration driverSearchDelay;

  // ── Auth state ──────────────────────────────────────────────────────────
  AuthUser _profile = AuthUser.empty;
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;
  bool _isAuthInitialized = false;
  bool _isLoading = false;
  String? _error;

  AuthUser get profile => _profile;
  bool get isAuthInitialized => _isAuthInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isAuthenticated && _profile.isProfileComplete;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  // ── Booking state machine ───────────────────────────────────────────────
  BookingStatus _bookingStatus = BookingStatus.idle;
  BookingStage _bookingStage = BookingStage.home;
  LocationConfirmationStatus _pickupConfirmation =
      LocationConfirmationStatus.unconfirmed;
  LocationConfirmationStatus _destinationConfirmation =
      LocationConfirmationStatus.unconfirmed;
  SavedLocation? _pickupLocation;
  SavedLocation? _destinationLocation;
  VehicleOption? _selectedVehicle;
  VehicleType? _preferredVehicleType;
  List<VehicleOption> _availableVehicles = [];
  FareCalculationState _fareState = FareCalculationState.idle;
  String? _fareError;
  OrderSubmissionState _submissionState = OrderSubmissionState.idle;
  String? _createdOrderId;
  MockDriver? _assignedDriver;
  RideRecord? _currentRide;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  int _routeSignature = 0;
  int _vehicleRequestId = 0;
  int _searchGeneration = 0;
  int _locationRequestId = 0;
  int _routeCalculationId = 0;
  Future<void>? _activeSearch;

  RouteResult? _currentRoute;
  bool _isRouteLoading = false;
  String? _routeError;

  CurrentLocationState _currentLocation = const CurrentLocationState();
  int _recentDestinationsVersion = 0;

  BookingStatus get bookingStatus => _bookingStatus;
  BookingStage get bookingStage => _bookingStage;
  LocationConfirmationStatus get pickupConfirmation => _pickupConfirmation;
  LocationConfirmationStatus get destinationConfirmation =>
      _destinationConfirmation;
  SavedLocation? get pickupLocation => _pickupLocation;
  SavedLocation? get destinationLocation => _destinationLocation;
  VehicleOption? get selectedVehicle => _selectedVehicle;
  List<VehicleOption> get availableVehicles =>
      List<VehicleOption>.unmodifiable(_availableVehicles);
  MockDriver? get assignedDriver => _assignedDriver;
  RideRecord? get currentRide => _currentRide;
  PaymentMethod get paymentMethod => _paymentMethod;
  bool get vehiclesLoading => _fareState == FareCalculationState.loading;
  FareCalculationState get fareState => _fareState;
  String? get fareError => _fareError;
  OrderSubmissionState get submissionState => _submissionState;
  String? get createdOrderId => _createdOrderId;
  bool get isSubmitting => _submissionState == OrderSubmissionState.submitting;
  FareBreakdown? get calculatedFare => _fareState == FareCalculationState.ready
      ? _selectedVehicle?.fareBreakdown
      : null;
  RouteResult? get currentRoute => _currentRoute;
  bool get isRouteLoading => _isRouteLoading;
  String? get routeError => _routeError;
  bool get hasConfirmedRoute =>
      _pickupLocation != null &&
      _destinationLocation != null &&
      _pickupConfirmation == LocationConfirmationStatus.confirmed &&
      _destinationConfirmation == LocationConfirmationStatus.confirmed;

  BookingValidationResult get bookingValidation => validateBooking(
    pickup: _pickupConfirmation == LocationConfirmationStatus.confirmed
        ? _pickupLocation
        : null,
    destination:
        _destinationConfirmation == LocationConfirmationStatus.confirmed
        ? _destinationLocation
        : null,
    fareState: _fareState,
    vehiclesLoading: vehiclesLoading,
    availableVehicleCount: _availableVehicles.length,
    hasSelectedVehicle: _selectedVehicle != null,
    isSubmitting: isSubmitting,
  );

  CurrentLocationState get currentLocation => _currentLocation;

  /// Resolves the current location for map controls.
  ///
  /// This never writes a pickup automatically and never substitutes a fake
  /// coordinate when location is unavailable.
  Future<void> refreshCurrentLocation() async {
    final requestId = ++_locationRequestId;
    _currentLocation = const CurrentLocationState(isLoading: true);
    notifyListeners();

    try {
      final result = await _currentLocationService.getCurrentLocation();
      if (requestId != _locationRequestId) return;

      if (result.isAvailable) {
        _currentLocation = CurrentLocationState(
          coordinate: result.coordinate,
          accuracy: result.accuracy,
          lastUpdated: DateTime.now(),
        );
      } else {
        _currentLocation = CurrentLocationState(
          error: result.message ?? 'Current location is unavailable.',
        );
      }
    } catch (_) {
      if (requestId != _locationRequestId) return;
      _currentLocation = const CurrentLocationState(
        error: 'Could not get your current location. Try again.',
      );
    } finally {
      if (requestId == _locationRequestId) notifyListeners();
    }
  }

  RecentDestinationsStore get recentDestinationsStore =>
      _recentDestinationsStore;

  /// Increments after a successful recent-destination write so Home can
  /// refresh its conditional "Last used" row without polling.
  int get recentDestinationsVersion => _recentDestinationsVersion;

  Future<List<SavedLocation>> loadRecentDestinations() =>
      _recentDestinationsStore.load();

  Future<SavedLocation?> latestRecentDestination() =>
      _recentDestinationsStore.latest();

  // ── Rides ───────────────────────────────────────────────────────────────
  MockBookingRepository get bookingRepository => _bookingRepo;
  List<RideRecord> get allRides => _bookingRepo.getAllRides();
  List<RideRecord> get completedRides => _bookingRepo.getCompletedRides();

  // ── Notifications ───────────────────────────────────────────────────────
  List<AppNotification> get notifications => _notificationRepo.getAll();
  int get unreadNotificationCount => _notificationRepo.unreadCount;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    try {
      _profile = await _customerRepo.restoreSession() ?? AuthUser.empty;
      _isAuthenticated =
          _profile.phone.isNotEmpty && _profile.isProfileComplete;
      _hasCompletedOnboarding = await _customerRepo.hasCompletedOnboarding();
    } catch (_) {
      _profile = AuthUser.empty;
      _isAuthenticated = false;
    } finally {
      _isAuthInitialized = true;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  Future<bool> registerAccount({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _profile = await _customerRepo.register(
        name: name,
        phone: phone,
        password: password,
        email: email,
      );
      // Registration is not a signed-in session; OTP verification completes it.
      _isAuthenticated = false;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Registration failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _profile = await _customerRepo.loginWithPassword(
        phone: phone,
        password: password,
      );
      _isAuthenticated = true;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Validates the fixed development OTP. Mock mode only — no SMS.
  Future<bool> verifyOtp({required String phone, required String code}) async {
    _setLoading(true);
    _error = null;
    try {
      final valid = await _customerRepo.verifyOtp(phone: phone, code: code);
      if (valid) {
        final session = await _customerRepo.restoreSession();
        if (session != null) {
          _profile = session;
          _isAuthenticated = session.isProfileComplete;
        }
      }
      return valid;
    } catch (_) {
      _error = 'OTP verification failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> requestOtp(String phone) async {
    _error = null;
    try {
      await _customerRepo.requestOtp(phone);
      return true;
    } catch (_) {
      _error = 'Could not resend OTP. Please try again.';
      return false;
    }
  }

  Future<bool> completeProfileSetup({
    required String name,
    String? email,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _profile = await _customerRepo.updateProfile(
        _profile.copyWith(
          name: name,
          email: email,
          isProfileComplete: true,
          hasCompletedOnboarding: true,
        ),
      );
      _isAuthenticated = true;
      await _customerRepo.markOnboardingComplete();
      _hasCompletedOnboarding = true;
      return true;
    } catch (_) {
      _error = 'Could not complete your profile. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({required String name, String? email}) async {
    _setLoading(true);
    _error = null;
    try {
      _profile = await _customerRepo.updateProfile(
        _profile.copyWith(name: name, email: email),
      );
    } catch (_) {
      _error = 'Could not update your profile. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markOnboardingComplete() async {
    _hasCompletedOnboarding = true;
    await _customerRepo.markOnboardingComplete();
    notifyListeners();
  }

  Future<void> logout() async {
    await _customerRepo.logout();
    _profile = AuthUser.empty;
    _isAuthenticated = false;
    _error = null;
    _resetBooking();
    notifyListeners();
  }

  // ── Booking flow ─────────────────────────────────────────────────────────
  bool _transition(BookingStatus to) {
    if (!isValidTransition(_bookingStatus, to)) {
      debugPrint('Invalid transition: $_bookingStatus → $to');
      return false;
    }
    _bookingStatus = to;
    notifyListeners();
    return true;
  }

  void _setStage(BookingStage stage) {
    if (_bookingStage == stage) return;
    if (!isValidBookingStageTransition(_bookingStage, stage)) return;
    _bookingStage = stage;
  }

  void beginLocationSelection() {
    _setStage(BookingStage.locationSelection);
    if (_bookingStatus == BookingStatus.idle ||
        _bookingStatus == BookingStatus.selectingPickup) {
      _transition(BookingStatus.selectingDestination);
    }
    notifyListeners();
  }

  void beginLocationConfirmation() {
    _setStage(BookingStage.locationConfirmation);
    if (_bookingStatus == BookingStatus.idle ||
        _bookingStatus == BookingStatus.selectingPickup) {
      _transition(BookingStatus.selectingDestination);
    }
    notifyListeners();
  }

  void returnToLocationSelection() {
    _setStage(BookingStage.locationSelection);
    if (_bookingStatus == BookingStatus.selectingVehicle) {
      _transition(BookingStatus.selectingDestination);
    }
    notifyListeners();
  }

  void beginVehicleSelection() {
    _setStage(BookingStage.vehicleSelection);
    if (_bookingStatus == BookingStatus.idle ||
        _bookingStatus == BookingStatus.selectingPickup ||
        _bookingStatus == BookingStatus.selectingDestination) {
      _transition(BookingStatus.selectingVehicle);
    }
    notifyListeners();
  }

  void beginOrderSubmission() {
    _setStage(BookingStage.orderSubmission);
    notifyListeners();
  }

  /// Returns to Home while keeping the current pickup/drop selections.
  void returnHome() {
    _bookingStage = BookingStage.home;
    if (_bookingStatus == BookingStatus.selectingPickup ||
        _bookingStatus == BookingStatus.selectingDestination ||
        _bookingStatus == BookingStatus.selectingVehicle ||
        _bookingStatus == BookingStatus.reviewingFare ||
        _bookingStatus == BookingStatus.confirmingBooking) {
      _transition(BookingStatus.idle);
    }
    notifyListeners();
  }

  bool _sameLocation(SavedLocation? previous, SavedLocation next) {
    if (previous == null) return false;
    return previous.id == next.id &&
        previous.coordinate.latitude == next.coordinate.latitude &&
        previous.coordinate.longitude == next.coordinate.longitude;
  }

  void _invalidateDerivedFare() {
    _routeSignature++;
    _vehicleRequestId++;
    _routeCalculationId++;
    _currentRoute = null;
    _routeError = null;
    _availableVehicles = [];
    _selectedVehicle = null;
    _fareState = FareCalculationState.idle;
    _fareError = null;
  }

  void setPickupLocation(SavedLocation location) {
    final changed = !_sameLocation(_pickupLocation, location);
    _pickupLocation = location;
    _pickupConfirmation = LocationConfirmationStatus.confirmed;
    if (changed) _invalidateDerivedFare();
    notifyListeners();
  }

  void setDestinationLocation(SavedLocation location) {
    final changed = !_sameLocation(_destinationLocation, location);
    _destinationLocation = location;
    _destinationConfirmation = LocationConfirmationStatus.confirmed;
    if (changed) _invalidateDerivedFare();
    notifyListeners();
  }

  VehicleOption? _optionForType(VehicleType type) {
    for (final option in _availableVehicles) {
      if (option.type == type) return option;
    }
    return null;
  }

  /// Calculates a real road-network route between the confirmed pickup and drop.
  Future<RouteResult?> calculateRoute({bool force = false}) async {
    if (!hasConfirmedRoute) return null;
    final pickup = _pickupLocation!.coordinate;
    final destination = _destinationLocation!.coordinate;

    final calculationId = ++_routeCalculationId;
    _isRouteLoading = true;
    _routeError = null;
    notifyListeners();

    try {
      final result = await _routeService.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: _selectedVehicle?.type ?? _preferredVehicleType,
      );
      if (calculationId != _routeCalculationId) return null;
      _currentRoute = result;
      _routeError = result.isSuccess ? null : result.errorMessage;
      return result;
    } catch (_) {
      if (calculationId != _routeCalculationId) return null;
      _routeError = 'Route calculation failed. Please retry.';
      return null;
    } finally {
      if (calculationId == _routeCalculationId) {
        _isRouteLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads vehicle options and fare estimates for the confirmed route.
  ///
  /// Returns true only when options are available for the same route that was
  /// requested. Any location change while loading discards the result.
  Future<bool> prepareVehicleSelection() async {
    if (!hasConfirmedRoute) return false;

    // Trigger road route calculation alongside vehicle selection
    unawaited(calculateRoute());

    final pickup = _pickupLocation!;
    final destination = _destinationLocation!;
    if (!isValidCoordinate(pickup.coordinate) ||
        !isValidCoordinate(destination.coordinate) ||
        MockPricingService.distanceKm(
              pickup.coordinate,
              destination.coordinate,
            ) <
            0.05) {
      return false;
    }
    if (!isValidBookingStageTransition(
      _bookingStage,
      BookingStage.vehicleSelection,
    )) {
      return false;
    }

    _bookingStage = BookingStage.vehicleSelection;
    if (_bookingStatus != BookingStatus.selectingVehicle) {
      _transition(BookingStatus.selectingVehicle);
    }

    final signature = _routeSignature;
    final requestId = ++_vehicleRequestId;
    _fareState = FareCalculationState.loading;
    _fareError = null;
    _availableVehicles = [];
    _selectedVehicle = null;
    notifyListeners();

    try {
      final options = await _vehicleRepo.getAvailableVehicles(
        from: pickup.coordinate,
        to: destination.coordinate,
      );
      if (requestId != _vehicleRequestId || signature != _routeSignature) {
        return false;
      }

      _availableVehicles = options;
      if (options.isEmpty) {
        _fareState = FareCalculationState.unavailable;
        _selectedVehicle = null;
        return false;
      }

      _fareState = FareCalculationState.ready;
      final preferred = _preferredVehicleType;
      if (preferred != null) {
        _selectedVehicle = _optionForType(preferred);
      }
      return true;
    } catch (_) {
      if (requestId != _vehicleRequestId || signature != _routeSignature) {
        return false;
      }
      _availableVehicles = [];
      _selectedVehicle = null;
      _fareState = FareCalculationState.error;
      _fareError = 'Could not calculate fare. Please try again.';
      return false;
    } finally {
      if (requestId == _vehicleRequestId && signature == _routeSignature) {
        notifyListeners();
      }
    }
  }

  /// Legacy loader kept for existing screens/tests.
  Future<void> loadVehicles() async {
    await prepareVehicleSelection();
  }

  void selectVehicle(VehicleOption vehicle) {
    final option = _optionForType(vehicle.type);
    if (option == null) return;
    _selectedVehicle = option;
    _preferredVehicleType = option.type;
    _fareState = FareCalculationState.ready;
    _fareError = null;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void startSelectingPickup() => _transition(BookingStatus.selectingPickup);
  void startSelectingDestination() =>
      _transition(BookingStatus.selectingDestination);

  Future<void> proceedToVehicleSelection() async {
    await prepareVehicleSelection();
  }

  void proceedToFareReview() => _transition(BookingStatus.reviewingFare);
  void proceedToConfirmation() => _transition(BookingStatus.confirmingBooking);

  /// Creates the pending order exactly once.
  Future<PlaceOrderResult> placeOrder() async => _placeOrder();

  PlaceOrderResult _placeOrder() {
    if (_createdOrderId != null) {
      return PlaceOrderResult.success(_createdOrderId!);
    }
    if (_submissionState == OrderSubmissionState.submitting) {
      return PlaceOrderResult.inProgress(_createdOrderId);
    }

    final validation = bookingValidation;
    if (!validation.isValid) {
      return PlaceOrderResult.invalid(validation.message);
    }

    final pickup = _pickupLocation!;
    final destination = _destinationLocation!;
    final vehicle = _selectedVehicle!;
    final orderId = MockBookingRepository.generateId();
    final ride = RideRecord(
      id: orderId,
      pickupLocation: pickup,
      destinationLocation: destination,
      vehicleType: vehicle.type,
      fareBreakdown: vehicle.fareBreakdown,
      driver: null,
      status: RideStatus.upcoming,
      bookedAt: DateTime.now(),
      paymentMethod: _paymentMethod,
      tripId: orderId,
    );

    _submissionState = OrderSubmissionState.submitting;
    _bookingStage = BookingStage.orderSubmission;
    if (_bookingStatus != BookingStatus.confirmingBooking) {
      if (!_transition(BookingStatus.confirmingBooking)) {
        _bookingStatus = BookingStatus.confirmingBooking;
        notifyListeners();
      }
    }
    notifyListeners();

    try {
      _bookingRepo.addRide(ride);
      _currentRide = ride;
      _createdOrderId = orderId;
      _submissionState = OrderSubmissionState.succeeded;
      notifyListeners();
      unawaited(_recordRecentDestination(destination));
      return PlaceOrderResult.success(orderId);
    } catch (_) {
      _submissionState = OrderSubmissionState.failed;
      notifyListeners();
      return const PlaceOrderResult.failure(
        'Could not place order. Please try again.',
      );
    }
  }

  Future<void> _recordRecentDestination(SavedLocation destination) async {
    try {
      await _recentDestinationsStore.record(destination);
      _recentDestinationsVersion++;
      notifyListeners();
    } catch (_) {
      // Recent history is best-effort; never fail an already-created order.
    }
  }

  /// Starts the demo driver search once. Safe to call repeatedly.
  Future<void> startDriverSearch() async {
    if (_createdOrderId == null) {
      final result = await placeOrder();
      if (!result.isSuccess) return;
    }
    if (_bookingStatus == BookingStatus.searchingDriver) {
      return _activeSearch ?? Future<void>.value();
    }
    if (_bookingStatus == BookingStatus.driverAssigned ||
        _bookingStatus == BookingStatus.driverArriving ||
        _bookingStatus == BookingStatus.driverArrived ||
        _bookingStatus == BookingStatus.tripInProgress ||
        _bookingStatus == BookingStatus.tripCompleted ||
        _bookingStatus == BookingStatus.awaitingRating ||
        _bookingStatus == BookingStatus.rated ||
        _bookingStatus == BookingStatus.cancelled) {
      return Future<void>.value();
    }
    if (_bookingStatus == BookingStatus.reviewingFare) {
      _transition(BookingStatus.confirmingBooking);
    }
    if (!_transition(BookingStatus.searchingDriver)) {
      return Future<void>.value();
    }

    final generation = ++_searchGeneration;
    final future = _runDriverSearch(generation);
    _activeSearch = future;
    return future;
  }

  Future<void> _runDriverSearch(int generation) async {
    try {
      await Future<void>.delayed(driverSearchDelay);
      if (generation != _searchGeneration ||
          _bookingStatus != BookingStatus.searchingDriver) {
        return;
      }

      final vehicle = _selectedVehicle;
      if (vehicle == null) {
        handleSearchFailure();
        return;
      }

      final driver = vehicle.type == VehicleType.bike
          ? await _driverRepo.getAssignedDriver()
          : await _driverRepo.getAssignedTotoDriver();
      if (generation != _searchGeneration ||
          _bookingStatus != BookingStatus.searchingDriver) {
        return;
      }

      _assignedDriver = driver;
      final ride = _currentRide;
      if (ride != null) {
        final updated = ride.copyWith(
          driver: driver,
          status: RideStatus.active,
        );
        _bookingRepo.updateRide(updated);
        _currentRide = updated;
      } else {
        // The pending order is always created before search starts. If it is
        // missing, fail honestly instead of inventing a ride from partial
        // state.
        handleSearchFailure();
        return;
      }

      _transition(BookingStatus.driverAssigned);
    } catch (_) {
      if (generation == _searchGeneration) handleSearchFailure();
    } finally {
      if (generation == _searchGeneration) _activeSearch = null;
    }
  }

  /// Legacy entry point used by BookingConfirmationScreen.
  Future<void> confirmBooking() async {
    if (_createdOrderId == null) {
      final result = _placeOrder();
      if (!result.isSuccess) return;
    }
    await startDriverSearch();
  }

  Future<void> driverStartsArriving() async {
    _transition(BookingStatus.driverArriving);
  }

  Future<void> driverArrived() async {
    _transition(BookingStatus.driverArrived);
  }

  Future<void> startTrip() async {
    _transition(BookingStatus.tripInProgress);
  }

  Future<void> completeTrip() async {
    if (_currentRide != null) {
      final completed = _currentRide!.copyWith(
        status: RideStatus.completed,
        completedAt: DateTime.now(),
      );
      _bookingRepo.updateRide(completed);
      _currentRide = completed;
    }
    _transition(BookingStatus.tripCompleted);
    await Future.delayed(const Duration(milliseconds: 500));
    _transition(BookingStatus.awaitingRating);
  }

  Future<void> submitRating({required int rating, String? comment}) async {
    if (_currentRide != null) {
      final rated = _currentRide!.copyWith(
        rating: rating,
        ratingComment: comment,
      );
      _bookingRepo.updateRide(rated);
      _currentRide = rated;
    }
    _transition(BookingStatus.rated);
  }

  void skipRating() => _transition(BookingStatus.idle);

  Future<void> cancelRide({String? reason}) async {
    const cancellable = {
      BookingStatus.confirmingBooking,
      BookingStatus.searchingDriver,
      BookingStatus.driverAssigned,
      BookingStatus.driverArriving,
      BookingStatus.driverArrived,
    };
    if (!cancellable.contains(_bookingStatus)) return;

    _searchGeneration++;
    _activeSearch = null;

    if (_currentRide != null) {
      final cancelled = _currentRide!.copyWith(
        status: RideStatus.cancelled,
        completedAt: DateTime.now(),
      );
      _bookingRepo.updateRide(cancelled);
      _currentRide = cancelled;
    }

    if (isValidTransition(_bookingStatus, BookingStatus.cancelled)) {
      _transition(BookingStatus.cancelled);
    } else {
      _bookingStatus = BookingStatus.cancelled;
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _transition(BookingStatus.idle);
    _resetBooking();
  }

  void handleSearchFailure() {
    if (_bookingStatus == BookingStatus.searchingDriver) {
      _transition(BookingStatus.failed);
    }
  }

  void retrySearch() {
    unawaited(startDriverSearch());
  }

  void resetToIdle() {
    _searchGeneration++;
    _activeSearch = null;
    _resetBooking();
    _bookingStatus = BookingStatus.idle;
    notifyListeners();
  }

  void _resetBooking() {
    _searchGeneration++;
    _activeSearch = null;
    _pickupLocation = null;
    _destinationLocation = null;
    _pickupConfirmation = LocationConfirmationStatus.unconfirmed;
    _destinationConfirmation = LocationConfirmationStatus.unconfirmed;
    _selectedVehicle = null;
    _preferredVehicleType = null;
    _availableVehicles = [];
    _assignedDriver = null;
    _currentRide = null;
    _bookingStage = BookingStage.home;
    _fareState = FareCalculationState.idle;
    _fareError = null;
    _submissionState = OrderSubmissionState.idle;
    _createdOrderId = null;
    _currentRoute = null;
    _routeError = null;
    _routeCalculationId++;
    _routeSignature++;
    _vehicleRequestId++;
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  void markNotificationRead(String id) {
    _notificationRepo.markRead(id);
    notifyListeners();
  }

  void markAllNotificationsRead() {
    _notificationRepo.markAllRead();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
