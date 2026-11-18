import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/features/location/data/location_repository.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_search_delegate.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/mock_data/mock_data.dart';
import 'package:e_go/shared/widgets/buttons.dart';
import 'package:e_go/shared/widgets/location_components.dart';

/// Full-screen map picker for either the pickup or drop location.
///
/// The map never invents an address. A pin is described by its coordinates
/// unless the customer explicitly selected a known place from search.
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    super.key,
    required this.target,
    this.tileProvider,
  });

  final LocationSelectionTarget target;

  /// Injectable for tests so no network tiles are requested.
  final TileProvider? tileProvider;

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class MapLocationPickerResult {
  const MapLocationPickerResult({required this.target, required this.location});

  final LocationSelectionTarget target;
  final SavedLocation location;
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  final LocationRepository _repository = LocationRepository();

  late LocationSelectionTarget _target;
  SavedLocation? _candidate;
  LatLng _centerCoordinate = MockData.jhargramCenter;
  bool _isLocating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _target = widget.target;
    final appState = context.read<AppState>();
    _candidate = _savedFor(appState, _target);
    final other = _otherTarget(_target);
    _centerCoordinate =
        _candidate?.coordinate ??
        _savedFor(appState, other)?.coordinate ??
        MockData.jhargramCenter;
  }

  SavedLocation? _savedFor(AppState appState, LocationSelectionTarget target) {
    return target.isPickup
        ? appState.pickupLocation
        : appState.destinationLocation;
  }

  LocationSelectionTarget _otherTarget(LocationSelectionTarget target) =>
      target.isPickup
      ? LocationSelectionTarget.destination
      : LocationSelectionTarget.pickup;

  void _handleMapReady() {
    _mapReady = true;
  }

  void _moveMap(LatLng point) {
    if (!_mapReady) return;
    try {
      _mapController.move(point, 16);
    } catch (_) {
      // The map can be mid-disposal when a search result returns.
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture || !isValidCoordinate(camera.center)) return;
    setState(() => _candidate = _pinned(camera.center));
  }

  SavedLocation _pinned(LatLng coordinate) {
    final lat = coordinate.latitude.toStringAsFixed(5);
    final lng = coordinate.longitude.toStringAsFixed(5);
    return SavedLocation(
      id: 'map-${_target.name}-$lat-$lng',
      label: _target.pinnedLabel,
      subtitle: '$lat, $lng',
      coordinate: coordinate,
      icon: Icons.location_on,
      type: PlaceType.other,
    );
  }

  void _switchTarget(LocationSelectionTarget target) {
    if (target == _target) return;

    final appState = context.read<AppState>();
    final candidate = _savedFor(appState, target);
    final other = _otherTarget(target);
    final center =
        candidate?.coordinate ??
        _savedFor(appState, other)?.coordinate ??
        MockData.jhargramCenter;

    setState(() {
      _target = target;
      _candidate = candidate;
      _centerCoordinate = center;
    });
    _moveMap(center);
  }

  Future<void> _openSearch() async {
    final result = await showSearch<LocationSearchResult?>(
      context: context,
      delegate: EGoLocationSearchDelegate(repository: _repository),
    );
    if (!mounted || result == null) return;

    final location = SavedLocation(
      id: result.id,
      label: result.name,
      subtitle: result.address,
      coordinate: result.coordinate,
      icon: iconForPlaceType(result.type),
      type: result.type,
    );

    setState(() {
      _candidate = location;
      _centerCoordinate = location.coordinate;
    });
    _moveMap(location.coordinate);
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);
    final appState = context.read<AppState>();
    await appState.refreshCurrentLocation();
    if (!mounted) return;

    final current = appState.currentLocation;
    setState(() => _isLocating = false);

    final coordinate = current.coordinate;
    if (coordinate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(current.error ?? 'Current location is unavailable.'),
        ),
      );
      return;
    }

    final lat = coordinate.latitude.toStringAsFixed(5);
    final lng = coordinate.longitude.toStringAsFixed(5);
    setState(() {
      _candidate = SavedLocation(
        id: 'current-location-$lat-$lng',
        label: 'Current location',
        subtitle: '$lat, $lng',
        coordinate: coordinate,
        icon: Icons.my_location,
        type: PlaceType.other,
      );
      _centerCoordinate = coordinate;
    });
    _moveMap(coordinate);
  }

  void _confirm() {
    final candidate = _candidate;
    if (candidate == null || !isValidCoordinate(candidate.coordinate)) return;

    final appState = context.read<AppState>();
    if (_target.isPickup) {
      appState.setPickupLocation(candidate);
    } else {
      appState.setDestinationLocation(candidate);
    }

    Navigator.pop(
      context,
      MapLocationPickerResult(target: _target, location: candidate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCandidate = _candidate != null;

    return Scaffold(
      backgroundColor: EGoColors.brandBackground,
      appBar: AppBar(
        title: Text(_target.mapTitle),
        backgroundColor: EGoColors.surface,
        surfaceTintColor: EGoColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search for a place',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerCoordinate,
              initialZoom: 16,
              backgroundColor: EGoColors.surfaceVariant,
              onMapReady: _handleMapReady,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ego.customer',
                tileProvider: widget.tileProvider,
              ),
            ],
          ),

          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EGoSpacing.md,
                        vertical: EGoSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: EGoColors.brandNavy,
                        borderRadius: BorderRadius.circular(
                          EGoSpacing.radiusMedium,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: EGoColors.shadow,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _target.shortLabel,
                        style: EGoTypography.labelSmall.copyWith(
                          color: EGoColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: EGoSpacing.xs),
                    const Icon(
                      Icons.location_pin,
                      size: 42,
                      color: EGoColors.brandYellow,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: EGoSpacing.md,
            left: EGoSpacing.lg,
            right: EGoSpacing.lg,
            child: Material(
              color: EGoColors.surface,
              elevation: EGoSpacing.elevation2,
              borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
              child: Padding(
                padding: const EdgeInsets.all(EGoSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<LocationSelectionTarget>(
                      segments: const [
                        ButtonSegment(
                          value: LocationSelectionTarget.pickup,
                          label: Text('Pickup'),
                          icon: Icon(Icons.trip_origin),
                        ),
                        ButtonSegment(
                          value: LocationSelectionTarget.destination,
                          label: Text('Drop'),
                          icon: Icon(Icons.location_on_outlined),
                        ),
                      ],
                      selected: {_target},
                      onSelectionChanged: (selection) =>
                          _switchTarget(selection.first),
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          EGoTypography.labelLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: EGoSpacing.xs),
                    Text(
                      'Move the map to set your ${_target.shortLabel.toLowerCase()} point.',
                      style: EGoTypography.bodySmall.copyWith(
                        color: EGoColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: EGoSpacing.lg,
            bottom: 224,
            child: EGoCurrentLocationButton(
              onPressed: _useCurrentLocation,
              tooltip: 'Use current location',
              isActive: !_isLocating,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Material(
                color: EGoColors.surface,
                elevation: EGoSpacing.elevation4,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(EGoSpacing.radiusSheet),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EGoSpacing.lg,
                    EGoSpacing.lg,
                    EGoSpacing.lg,
                    EGoSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(EGoSpacing.sm),
                            decoration: BoxDecoration(
                              color: EGoColors.brandPrimaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasCandidate
                                  ? Icons.location_on
                                  : Icons.map_outlined,
                              color: EGoColors.brandNavy,
                              size: EGoSpacing.iconSmall,
                            ),
                          ),
                          const SizedBox(width: EGoSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _candidate?.label ??
                                      'Choose a point on the map',
                                  style: EGoTypography.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: EGoSpacing.xs / 2),
                                Text(
                                  _candidate?.subtitle ??
                                      'Move the map or search for a place.',
                                  style: EGoTypography.bodySmall.copyWith(
                                    color: EGoColors.onSurfaceMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EGoSpacing.lg),
                      EGoPrimaryButton(
                        onPressed: hasCandidate ? _confirm : null,
                        label: _target.confirmAction,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
