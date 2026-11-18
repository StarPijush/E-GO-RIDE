import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/booking/domain/place_order_result.dart';
import 'package:e_go/features/booking/presentation/widgets/fare_summary_panel.dart';
import 'package:e_go/features/booking/presentation/widgets/place_order_map_summary.dart';
import 'package:e_go/features/booking/presentation/widgets/vehicle_option_card.dart';
import 'package:e_go/features/location/domain/location_model.dart';

/// Step 3 of the booking flow: review route, choose a vehicle and place the
/// order exactly once.
class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key, this.tileProvider});

  /// Injectable for tests so no network tiles are requested.
  final TileProvider? tileProvider;

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.beginVehicleSelection();
      if (appState.fareState == FareCalculationState.idle &&
          appState.hasConfirmedRoute) {
        unawaited(appState.prepareVehicleSelection());
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    setState(() => _placing = true);

    final appState = context.read<AppState>();
    final result = await appState.placeOrder();
    if (!mounted) return;

    if (result.isSuccess ||
        (result.status == PlaceOrderStatus.inProgress &&
            appState.createdOrderId != null)) {
      Navigator.pushReplacementNamed(context, EGoRouter.searchingDriver);
      unawaited(appState.startDriverSearch());
      return;
    }

    setState(() => _placing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? 'Could not place order. Please try again.',
        ),
      ),
    );
  }

  void _changeLocations() {
    if (_placing || context.read<AppState>().isSubmitting) return;
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final pickup = appState.pickupLocation;
    final destination = appState.destinationLocation;
    final isPlacing = appState.isSubmitting || _placing;
    final selected = appState.selectedVehicle;
    final fare = appState.calculatedFare;
    final fareReady = appState.fareState == FareCalculationState.ready;
    final canPlace = !isPlacing && appState.bookingValidation.isValid;

    final vehicles = <VehicleOption>[
      ...appState.availableVehicles
          .where((vehicle) => vehicle.type == VehicleType.toto)
          .take(1),
      ...appState.availableVehicles
          .where((vehicle) => vehicle.type == VehicleType.bike)
          .take(1),
    ];

    return PopScope(
      canPop: !isPlacing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) appState.returnToLocationSelection();
      },
      child: Scaffold(
        backgroundColor: EGoColors.brandBackground,
        appBar: AppBar(
          title: const Text('Review your ride'),
          backgroundColor: EGoColors.surface,
          surfaceTintColor: EGoColors.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: isPlacing ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(EGoSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pickup != null && destination != null)
                        PlaceOrderMapSummary(
                          pickup: pickup,
                          destination: destination,
                          tileProvider: widget.tileProvider,
                        )
                      else
                        _MissingRouteCard(),
                      const SizedBox(height: EGoSpacing.md),
                      _LocationSummary(
                        pickup: pickup,
                        destination: destination,
                        onChange: _changeLocations,
                      ),
                      const SizedBox(height: EGoSpacing.xxl),
                      Text(
                        'Choose your ride',
                        style: EGoTypography.titleMedium,
                      ),
                      const SizedBox(height: EGoSpacing.sm),
                      if (vehicles.isEmpty &&
                          appState.fareState == FareCalculationState.loading)
                        _LoadingVehicles()
                      else
                        ...vehicles.map(
                          (vehicle) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: EGoSpacing.md,
                            ),
                            child: VehicleOptionCard(
                              vehicle: vehicle,
                              isSelected: selected?.type == vehicle.type,
                              fareReady: fareReady,
                              onTap: () => appState.selectVehicle(vehicle),
                            ),
                          ),
                        ),
                      const SizedBox(height: EGoSpacing.sm),
                      FareSummaryPanel(
                        fareState: appState.fareState,
                        fare: fare,
                        hasSelection: selected != null,
                        error: appState.fareError,
                        onRetry: () =>
                            unawaited(appState.prepareVehicleSelection()),
                      ),
                      const SizedBox(height: EGoSpacing.md),
                      const _DemoNotice(),
                    ],
                  ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected != null && fareReady && fare != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated total',
                              style: EGoTypography.bodyMedium.copyWith(
                                color: EGoColors.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              '₹${fare.totalFare.toStringAsFixed(0)}',
                              style: EGoTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: EGoSpacing.sm),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: canPlace ? _placeOrder : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              EGoSpacing.buttonHeight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                EGoSpacing.radiusPill,
                              ),
                            ),
                          ),
                          child: isPlacing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: EGoSpacing.iconSmall,
                                      height: EGoSpacing.iconSmall,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              EGoColors.onPrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: EGoSpacing.sm),
                                    Text(
                                      'Placing order...',
                                      style: EGoTypography.labelLarge.copyWith(
                                        color: EGoColors.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Place order',
                                  style: EGoTypography.labelLarge.copyWith(
                                    color: EGoColors.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({
    required this.pickup,
    required this.destination,
    required this.onChange,
  });

  final SavedLocation? pickup;
  final SavedLocation? destination;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EGoSpacing.lg),
      decoration: BoxDecoration(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
        border: Border.all(color: EGoColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your route', style: EGoTypography.titleSmall),
              const Spacer(),
              TextButton(onPressed: onChange, child: const Text('Change')),
            ],
          ),
          const SizedBox(height: EGoSpacing.sm),
          _LocationRow(
            icon: const Icon(
              Icons.trip_origin,
              size: EGoSpacing.iconSmall,
              color: EGoColors.brandNavy,
            ),
            label: 'Pickup',
            location: pickup,
          ),
          const SizedBox(height: EGoSpacing.md),
          _LocationRow(
            icon: const Icon(
              Icons.location_on,
              size: EGoSpacing.iconSmall,
              color: EGoColors.brandPrimaryDark,
            ),
            label: 'Drop',
            location: destination,
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.location,
  });

  final Widget icon;
  final String label;
  final SavedLocation? location;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: icon),
        const SizedBox(width: EGoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: EGoTypography.labelSmall.copyWith(
                  color: EGoColors.onSurfaceMuted,
                ),
              ),
              Text(
                location?.label ?? 'Not selected',
                style: EGoTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (location?.subtitle != null)
                Text(
                  location!.subtitle!,
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
    );
  }
}

class _MissingRouteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
        border: Border.all(color: EGoColors.outlineVariant),
      ),
      child: Center(
        child: Text(
          'Choose a pickup and drop location first.',
          style: EGoTypography.bodyMedium.copyWith(
            color: EGoColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _LoadingVehicles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EGoSpacing.lg),
      decoration: BoxDecoration(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
        border: Border.all(color: EGoColors.outlineVariant),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: EGoSpacing.iconSmall,
            height: EGoSpacing.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: EGoSpacing.md),
          Text(
            'Loading vehicle options...',
            style: EGoTypography.bodyMedium.copyWith(
              color: EGoColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EGoSpacing.md),
      decoration: BoxDecoration(
        color: EGoColors.warningLight,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: EGoColors.warning,
            size: EGoSpacing.iconSmall,
          ),
          const SizedBox(width: EGoSpacing.sm),
          Expanded(
            child: Text(
              'Demo mode: No real driver will be dispatched.',
              style: EGoTypography.bodySmall.copyWith(color: EGoColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
