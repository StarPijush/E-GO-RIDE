import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/location/data/location_repository.dart';
import 'package:e_go/features/location/data/saved_places_store.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_search_delegate.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/features/location/presentation/map_location_picker_screen.dart';
import 'package:e_go/features/location/presentation/widgets/location_route_card.dart';
import 'package:e_go/features/location/presentation/widgets/pickup_timing_selector.dart';
import 'package:e_go/features/location/presentation/widgets/place_category_selector.dart';
import 'package:e_go/features/location/presentation/widgets/recent_places_content.dart';
import 'package:e_go/features/location/presentation/widgets/saved_places_content.dart';
import 'package:e_go/features/location/presentation/widgets/schedule_time_picker_dialog.dart';
import 'package:e_go/features/location/presentation/widgets/select_on_map_button.dart';
import 'package:e_go/mock_data/mock_data.dart';

/// Pixel-accurate Location Selection Screen reproducing Reference Sets A & B.
class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final LocationRepository _repository = LocationRepository();
  final SavedPlacesStore _savedPlacesStore = SavedPlacesStore();

  PickupTiming _selectedTiming = PickupTiming.now;
  PlaceCategory _selectedCategory = PlaceCategory.recent;

  DateTime? _scheduledDateTime;

  List<SavedLocation> _recent = const [];
  List<SavedPlace> _savedPlaces = const [];
  bool _loadingRecent = true;
  bool _isContinuing = false;
  String? _pickupError;
  String? _destinationError;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadSavedPlaces();
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

  Future<void> _loadSavedPlaces() async {
    try {
      final places = await _savedPlacesStore.load();
      if (!mounted) return;
      setState(() {
        _savedPlaces = places;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedPlaces = SavedPlacesStore.defaultSavedPlaces;
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

  void _selectSavedPlace(SavedPlace place) {
    final location = SavedLocation(
      id: place.id,
      label: place.label,
      subtitle: place.address,
      coordinate: place.coordinate ?? MockData.jhargramCenter,
      icon: place.icon,
      type: place.type == SavedPlaceType.home
          ? PlaceType.residential
          : (place.type == SavedPlaceType.work
              ? PlaceType.other
              : PlaceType.other),
    );
    _setLocation(LocationSelectionTarget.destination, location);
  }

  void _handleTimingChanged(PickupTiming timing) {
    setState(() {
      _selectedTiming = timing;
      if (timing == PickupTiming.later && _scheduledDateTime == null) {
        _scheduledDateTime = DateTime.now().add(const Duration(minutes: 30));
      } else if (timing == PickupTiming.now) {
        _scheduledDateTime = null;
      }
    });
  }

  String _formatScheduledTime(DateTime dt) {
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return 'Pickup at ${h12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickScheduleTime() async {
    final now = DateTime.now();
    final initial = _scheduledDateTime != null
        ? TimeOfDay.fromDateTime(_scheduledDateTime!)
        : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)));

    final pickedTime = await ScheduleTimePickerDialog.show(
      context: context,
      initialTime: initial,
    );

    if (!mounted || pickedTime == null) return;
    setState(() {
      _scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _handleCategoryChanged(PlaceCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Future<void> _addNewSavedLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController();
    final addressController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        title: const Text(
          'Add new location',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Color(0xFF142B45),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name (e.g. Gym, Library, Friend)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address in Jhargram',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC928),
              foregroundColor: const Color(0xFF142B45),
              elevation: 0,
            ),
            onPressed: () async {
              final label = titleController.text.trim();
              if (label.isEmpty) return;
              final address = addressController.text.trim().isEmpty
                  ? 'Jhargram area'
                  : addressController.text.trim();

              final newPlace = SavedPlace(
                id: 'saved-${DateTime.now().millisecondsSinceEpoch}',
                label: label,
                address: address,
                icon: Icons.place,
                type: SavedPlaceType.other,
                coordinate: MockData.jhargramCenter,
              );

              await _savedPlacesStore.addPlace(newPlace);
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _loadSavedPlaces();
              messenger.showSnackBar(
                const SnackBar(content: Text('Location saved successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editSavedLocation(SavedPlace place) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(text: place.label);
    final addressController = TextEditingController(text: place.address);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        title: Text(
          'Edit ${place.label}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Color(0xFF142B45),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC928),
              foregroundColor: const Color(0xFF142B45),
              elevation: 0,
            ),
            onPressed: () async {
              final label = titleController.text.trim();
              if (label.isEmpty) return;
              final address = addressController.text.trim();

              final updated = place.copyWith(
                label: label,
                address: address,
              );

              await _savedPlacesStore.updatePlace(updated);
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              _loadSavedPlaces();
              messenger.showSnackBar(
                const SnackBar(content: Text('Location updated successfully!')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
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
    final destination = appState.destinationLocation;
    final isContinueEnabled = destination != null && !_isContinuing;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) appState.returnHome();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        // ── A. Top App Bar ──
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F9FC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: Center(
            child: InkWell(
              onTap: () {
                appState.returnHome();
                Navigator.maybePop(context);
              },
              borderRadius: BorderRadius.circular(9999.0),
              child: Container(
                width: 44.0,
                height: 44.0,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF142B45),
                  size: 22.0,
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color(0x0A142B45),
              height: 1.0,
            ),
          ),
        ),

        // ── Main Body with Max Width & Scrolling ──
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560.0),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                      children: [
                        // ── B. Pickup Timing Segmented Selector ──
                        PickupTimingSelector(
                          selectedTiming: _selectedTiming,
                          onChanged: _handleTimingChanged,
                        ),
                        if (_selectedTiming == PickupTiming.later &&
                            _scheduledDateTime != null) ...[
                          const SizedBox(height: 8.0),
                          InkWell(
                            onTap: _pickScheduleTime,
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: const Color(0xFFECEEF1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 16.0,
                                    color: Color(0xFF142B45),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _formatScheduledTime(_scheduledDateTime!),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF142B45),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Change',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF765A00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16.0),

                        // ── C. Pickup & Destination Routing Card ──
                        LocationRouteCard(
                          pickupLocation: appState.pickupLocation,
                          destinationLocation: appState.destinationLocation,
                          pickupError: _pickupError,
                          destinationError: _destinationError,
                          onPickupTap: () =>
                              _search(LocationSelectionTarget.pickup),
                          onDestinationTap: () =>
                              _search(LocationSelectionTarget.destination),
                        ),

                        const SizedBox(height: 16.0),

                        // ── D. Select on Map Button ──
                        SelectOnMapButton(
                          onTap: () =>
                              _openMap(LocationSelectionTarget.destination),
                        ),

                        const SizedBox(height: 16.0),

                        // ── E. Recent / Saved Segmented Selector ──
                        PlaceCategorySelector(
                          selectedCategory: _selectedCategory,
                          onChanged: _handleCategoryChanged,
                        ),

                        const SizedBox(height: 16.0),

                        // ── F & G. Dynamic Category Content ──
                        if (_selectedCategory == PlaceCategory.recent)
                          RecentPlacesContent(
                            recentLocations: _recent,
                            isLoading: _loadingRecent,
                            onSelectLocation: _selectRecent,
                          )
                        else
                          SavedPlacesContent(
                            savedPlaces: _savedPlaces,
                            onSelectPlace: _selectSavedPlace,
                            onEditPlace: _editSavedLocation,
                            onAddNewLocation: _addNewSavedLocation,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 5. Fixed Bottom Continue Button ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xF2F7F9FC),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D142B45),
                      blurRadius: 20.0,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  20.0,
                  12.0,
                  20.0,
                  MediaQuery.paddingOf(context).bottom + 14.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560.0),
                    child: _ContinueButton(
                      isEnabled: isContinueEnabled,
                      isLoading: _isContinuing,
                      onTap: isContinueEnabled ? _continue : null,
                    ),
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

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onTap,
  });

  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFFC928);
    const disabledColor = Color(0xFFE6E8EB);
    const activeTextColor = Color(0xFF142B45);
    const disabledTextColor = Color(0xFF778397);

    return Container(
      width: double.infinity,
      height: 52.0,
      decoration: BoxDecoration(
        color: isEnabled ? activeColor : disabledColor,
        borderRadius: BorderRadius.circular(9999.0),
        boxShadow: isEnabled
            ? const [
                BoxShadow(
                  color: Color(0x1F142B45),
                  blurRadius: 24.0,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9999.0),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: activeTextColor,
                    ),
                  )
                : Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? activeTextColor : disabledTextColor,
                      letterSpacing: -0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
