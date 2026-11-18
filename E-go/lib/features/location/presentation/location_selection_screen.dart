import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/location/data/location_repository.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_search_delegate.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/features/location/presentation/map_location_picker_screen.dart';
import 'package:e_go/features/location/presentation/widgets/location_selection_field.dart';
import 'package:e_go/features/location/presentation/widgets/location_tile.dart';
import 'package:e_go/shared/widgets/buttons.dart';

/// Step 2 of the booking flow: confirm pickup and drop locations.
class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final LocationRepository _repository = LocationRepository();

  List<SavedLocation> _recent = const [];
  bool _loadingRecent = true;
  bool _isContinuing = false;
  String? _pickupError;
  String? _destinationError;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().beginLocationSelection();
    });
  }

  Future<void> _loadRecent() async {
    try {
      final recent = await context.read<AppState>().loadRecentDestinations();
      if (!mounted) return;
      setState(() {
        _recent = recent;
        _loadingRecent = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recent = const [];
        _loadingRecent = false;
      });
    }
  }

  void _setLocation(LocationSelectionTarget target, SavedLocation location) {
    final appState = context.read<AppState>();
    if (target.isPickup) {
      appState.setPickupLocation(location);
    } else {
      appState.setDestinationLocation(location);
    }

    setState(() {
      if (target.isPickup) {
        _pickupError = null;
      } else {
        _destinationError = null;
      }
    });
  }

  Future<void> _search(LocationSelectionTarget target) async {
    final result = await showSearch<LocationSearchResult?>(
      context: context,
      delegate: EGoLocationSearchDelegate(repository: _repository),
    );
    if (!mounted || result == null) return;

    _setLocation(
      target,
      SavedLocation(
        id: result.id,
        label: result.name,
        subtitle: result.address,
        coordinate: result.coordinate,
        icon: iconForPlaceType(result.type),
        type: result.type,
      ),
    );
  }

  Future<void> _openMap(LocationSelectionTarget target) async {
    final appState = context.read<AppState>();
    appState.beginLocationConfirmation();

    final result = await Navigator.pushNamed<MapLocationPickerResult>(
      context,
      EGoRouter.mapLocationPicker,
      arguments: target,
    );
    if (!mounted) return;

    appState.returnToLocationSelection();
    if (result == null) return;

    setState(() {
      if (result.target.isPickup) {
        _pickupError = null;
      } else {
        _destinationError = null;
      }
    });
  }

  void _selectRecent(SavedLocation recent) {
    _setLocation(LocationSelectionTarget.destination, recent);
  }

  String? _validateRoute(AppState appState) {
    final pickup = appState.pickupLocation;
    final destination = appState.destinationLocation;

    if (pickup == null || !isValidCoordinate(pickup.coordinate)) {
      return 'Choose a pickup location.';
    }
    if (destination == null || !isValidCoordinate(destination.coordinate)) {
      return 'Choose a drop location.';
    }

    final sameId = pickup.id == destination.id;
    final distance = MockPricingService.distanceKm(
      pickup.coordinate,
      destination.coordinate,
    );
    if (sameId || distance < 0.05) {
      return 'Pickup and drop cannot be the same location.';
    }

    return null;
  }

  Future<void> _continue() async {
    if (_isContinuing) return;

    final appState = context.read<AppState>();
    final error = _validateRoute(appState);
    final pickup = appState.pickupLocation;
    final destination = appState.destinationLocation;

    setState(() {
      _pickupError = pickup == null || !isValidCoordinate(pickup.coordinate)
          ? 'Choose a pickup location.'
          : null;
      if (error == null) {
        _destinationError = null;
      } else if (destination == null ||
          !isValidCoordinate(destination.coordinate)) {
        _destinationError = 'Choose a drop location.';
      } else {
        _destinationError = error;
      }
    });

    if (error != null) return;

    setState(() => _isContinuing = true);
    final ready = await appState.prepareVehicleSelection();
    if (!mounted) return;
    setState(() => _isContinuing = false);

    if (appState.bookingStage == BookingStage.vehicleSelection) {
      await Navigator.pushNamed(context, EGoRouter.placeOrder);
      return;
    }

    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.fareError ?? 'Could not continue. Check your locations.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) appState.returnHome();
      },
      child: Scaffold(
        backgroundColor: EGoColors.brandBackground,
        appBar: AppBar(
          title: const Text('Select your locations'),
          backgroundColor: EGoColors.surface,
          surfaceTintColor: EGoColors.surface,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(EGoSpacing.lg),
                  children: [
                    LocationSelectionField(
                      target: LocationSelectionTarget.pickup,
                      location: appState.pickupLocation,
                      errorText: _pickupError,
                      onTap: () => _search(LocationSelectionTarget.pickup),
                      onMapTap: () => _openMap(LocationSelectionTarget.pickup),
                    ),
                    const SizedBox(height: EGoSpacing.md),
                    LocationSelectionField(
                      target: LocationSelectionTarget.destination,
                      location: appState.destinationLocation,
                      errorText: _destinationError,
                      onTap: () => _search(LocationSelectionTarget.destination),
                      onMapTap: () =>
                          _openMap(LocationSelectionTarget.destination),
                    ),
                    const SizedBox(height: EGoSpacing.md),
                    EGoSecondaryButton(
                      onPressed: () =>
                          _openMap(LocationSelectionTarget.destination),
                      label: 'Select on map',
                      icon: const Icon(Icons.map_outlined, size: 18),
                    ),
                    const SizedBox(height: EGoSpacing.xxl),
                    Text('Recent locations', style: EGoTypography.titleMedium),
                    const SizedBox(height: EGoSpacing.sm),
                    if (_loadingRecent)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: EGoSpacing.lg),
                        child: Center(
                          child: SizedBox(
                            width: EGoSpacing.iconMedium,
                            height: EGoSpacing.iconMedium,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_recent.isEmpty)
                      _RecentEmptyState()
                    else
                      ..._recent.map(
                        (location) => Padding(
                          padding: const EdgeInsets.only(bottom: EGoSpacing.sm),
                          child: LocationTile(
                            location: location,
                            onTap: () => _selectRecent(location),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  EGoSpacing.lg,
                  EGoSpacing.md,
                  EGoSpacing.lg,
                  EGoSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: EGoColors.surface,
                  border: Border(
                    top: BorderSide(color: EGoColors.outlineVariant),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: EGoPrimaryButton(
                    onPressed: _isContinuing ? null : _continue,
                    label: 'Continue',
                    isLoading: _isContinuing,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EGoSpacing.lg),
      decoration: BoxDecoration(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusLarge),
        border: Border.all(color: EGoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history,
            color: EGoColors.onSurfaceMuted,
            size: EGoSpacing.iconMedium,
          ),
          const SizedBox(width: EGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent locations yet',
                  style: EGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: EGoSpacing.xs / 2),
                Text(
                  'Your ordered destinations will appear here.',
                  style: EGoTypography.bodySmall.copyWith(
                    color: EGoColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
