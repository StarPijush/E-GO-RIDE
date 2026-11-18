import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/features/home/presentation/widgets/home_destination_panel.dart';
import 'package:e_go/features/home/presentation/widgets/home_map_view.dart';
import 'package:e_go/features/location/data/popular_destinations.dart';
import 'package:e_go/features/location/domain/location_model.dart';

/// Stage 1: Map-first destination discovery.
///
/// Reference implementation according to master design specification:
/// - Muted geographical map viewport (~320px) with stylized Jhargram roads & terrain
/// - Current-location marker with floating navy tooltip pill
/// - NO floating GPS/recenter button
/// - NO floating brand logo overlay
/// - Bottom destination sheet with warm gradient (#FFF4CC -> #FFF8E8)
/// - 64px Destination Search Card opening Location Selection
/// - Data-driven conditional Recent Destination
/// - 2x2 grid of 4 Popular Destinations in Jhargram
/// - Full functional integration into shared E-GO booking state
class EGoHomeScreen extends StatefulWidget {
  const EGoHomeScreen({super.key, this.tileProvider});

  /// Injectable for tests so no network tiles are requested.
  final TileProvider? tileProvider;

  @override
  State<EGoHomeScreen> createState() => _EGoHomeScreenState();
}

class _EGoHomeScreenState extends State<EGoHomeScreen> {
  late final AppState _appState;
  late final List<SavedLocation> _popular;
  SavedLocation? _lastUsed;
  int _recentVersion = 0;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _popular = PopularDestinations.resolve();
    _recentVersion = _appState.recentDestinationsVersion;
    _appState.addListener(_handleAppStateChanged);
    _loadLastUsed();
  }

  @override
  void dispose() {
    _appState.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (_appState.recentDestinationsVersion == _recentVersion) return;
    _recentVersion = _appState.recentDestinationsVersion;
    _loadLastUsed();
  }

  Future<void> _loadLastUsed() async {
    try {
      final latest = await _appState.latestRecentDestination();
      if (!mounted) return;
      setState(() => _lastUsed = latest);
    } catch (_) {
      if (!mounted) return;
      setState(() => _lastUsed = null);
    }
  }

  Future<void> _openLocationSelection() async {
    _appState.beginLocationSelection();
    await Navigator.pushNamed(context, EGoRouter.locationSelection);
  }

  Future<void> _selectDestination(SavedLocation location) async {
    _appState.setDestinationLocation(location);

    if (_appState.hasConfirmedRoute) {
      await _appState.prepareVehicleSelection();
      if (!mounted) return;

      if (_appState.bookingStage == BookingStage.vehicleSelection) {
        await Navigator.pushNamed(context, EGoRouter.placeOrder);
        if (!mounted) return;
        // Direct Home -> Place Order has no Stage 2 below it.
        if (_appState.bookingStage == BookingStage.locationSelection) {
          _appState.returnHome();
        }
        return;
      }
    }

    _appState.beginLocationSelection();
    if (!mounted) return;
    await Navigator.pushNamed(context, EGoRouter.locationSelection);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: EGoColors.brandBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          // Map occupies upper viewport (~320px), sheet overlaps lower edge by 24px
          final mapHeight = (totalHeight * 0.42).clamp(280.0, 340.0);
          final sheetTop = mapHeight - 24.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mapHeight,
                child: HomeMapView(tileProvider: widget.tileProvider),
              ),
              Positioned(
                top: sheetTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: HomeDestinationPanel(
                  destination: appState.destinationLocation,
                  lastUsed: _lastUsed,
                  popular: _popular,
                  onDestinationTap: _openLocationSelection,
                  onLastUsedTap: _selectDestination,
                  onPopularTap: _selectDestination,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
