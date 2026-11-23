import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/booking/domain/place_order_result.dart';
import 'package:e_go/features/booking/presentation/widgets/fare_breakdown_sheet.dart';
import 'package:e_go/features/booking/presentation/widgets/place_order_map_summary.dart';
import 'package:e_go/features/booking/presentation/widgets/review_booking_footer.dart';
import 'package:e_go/features/booking/presentation/widgets/vehicle_option_card.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/routing/domain/models/route_result.dart';

/// E-GO Review Your Ride / Place Order Screen.
///
/// Refined, clean Map-First Experience (combining Rapido, Jugnoo and E-GO):
/// - Clean full-screen map background without any title pills
/// - Floating circular deep navy back button respecting system safe area
/// - Duplicate "YOUR ROUTE" summary section removed (map markers & route line communicate locations)
/// - Simplified "Choose your ride" list: single prominent fare per vehicle card
/// - Small info icon (i) on each card opening an authentic fare breakdown bottom sheet
/// - Large estimated-fare panel removed from main vehicle list
/// - Optimized map layer: isolated from vehicle selection and payment updates to prevent repainting lag
/// - Dedicated fixed footer with Cash & Offers and dynamic yellow booking button
/// - 100% preservation of existing booking state, OSRM routing, pricing model and idempotency
class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key, this.tileProvider});

  /// Injectable tile provider so widget tests do not request network tiles.
  final TileProvider? tileProvider;

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final MapController _mapController = MapController();
  bool _placing = false;
  bool _isSheetExpanded = false;

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
      } else if (appState.currentRoute == null && appState.hasConfirmedRoute) {
        unawaited(appState.calculateRoute());
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

  Future<void> _onLocatePressed() async {
    final appState = context.read<AppState>();
    await appState.refreshCurrentLocation();
    if (!mounted) return;

    final current = appState.currentLocation;
    if (current.coordinate != null) {
      _mapController.move(current.coordinate!, 16);
    } else if (current.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(current.error!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location is unavailable. Using route pickup.'),
        ),
      );
    }
  }

  void _showPaymentSelection(BuildContext context) {
    final appState = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF142B45),
                  ),
                ),
                const SizedBox(height: 16),
                _PaymentOptionTile(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF059669),
                  title: 'Cash',
                  subtitle: 'Pay directly to driver upon drop-off',
                  isSelected: appState.paymentMethod == PaymentMethod.cash,
                  onTap: () {
                    appState.setPaymentMethod(PaymentMethod.cash);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _PaymentOptionTile(
                  icon: Icons.qr_code_2_rounded,
                  iconColor: const Color(0xFF142B45),
                  title: 'UPI (GPay, PhonePe, Paytm)',
                  subtitle: 'Scan driver QR code after arrival (Demo)',
                  isSelected: appState.paymentMethod == PaymentMethod.upi,
                  onTap: () {
                    appState.setPaymentMethod(PaymentMethod.upi);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOffersCoupons(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC928).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF142B45),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Available Offers',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF142B45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: Color(0xFFFFC928)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WELCOME50 — ₹10 Flat Off',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF142B45),
                              ),
                            ),
                            Text(
                              'Applied on your first Jhargram ride',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coupon WELCOME50 applied!'),
                            ),
                          );
                        },
                        child: const Text('APPLY'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveCtaLabel(VehicleOption? selected) {
    if (selected == null) return 'Book your ride';
    switch (selected.type) {
      case VehicleType.bike:
        return 'Book Bike';
      case VehicleType.toto:
        return 'Book Toto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPlacing = appState.isSubmitting || _placing;
    final selected = appState.selectedVehicle;
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

    final ctaLabel = _resolveCtaLabel(selected);

    return PopScope(
      canPop: !isPlacing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) appState.returnToLocationSelection();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;

            // Streamlined responsive sheet heights (compact since redundant sections are removed)
            final collapsedSheetHeight =
                (totalHeight * 0.44).clamp(340.0, 390.0);
            final expandedSheetHeight =
                (totalHeight * 0.74).clamp(480.0, 640.0);
            final currentSheetHeight =
                _isSheetExpanded ? expandedSheetHeight : collapsedSheetHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── LAYER 1: ISOLATED FULL-SCREEN INTERACTIVE MAP ──────────────
                Positioned.fill(
                  child: _IsolatedMapBackground(
                    tileProvider: widget.tileProvider,
                    bottomPadding: collapsedSheetHeight,
                    mapController: _mapController,
                  ),
                ),

                // ── LAYER 2: FLOATING TOP BACK BUTTON ONLY (NO TITLE PILL) ─────
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor:
                            const Color(0xFF142B45).withValues(alpha: 0.18),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isPlacing
                              ? null
                              : () => Navigator.maybePop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF142B45),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── LAYER 3: FLOATING MAP CONTROLS (LOCATE BUTTON) ─────────────
                Positioned(
                  right: 16,
                  bottom: currentSheetHeight + 14,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor:
                        const Color(0xFF142B45).withValues(alpha: 0.20),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _onLocatePressed,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF142B45),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── LAYER 4: STREAMLINED FLOATING BOTTOM SHEET ─────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: currentSheetHeight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF142B45).withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 1. Drag Handle
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              if (details.primaryVelocity! < -150) {
                                setState(() => _isSheetExpanded = true);
                              } else if (details.primaryVelocity! > 150) {
                                setState(() => _isSheetExpanded = false);
                              }
                            }
                          },
                          onTap: () {
                            setState(() => _isSheetExpanded = !_isSheetExpanded);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Scrollable Vehicle Options (No redundant Route Summary, No large fare panel)
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                const Text(
                                  'Choose your ride',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF142B45),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Vehicle loading state
                                if (vehicles.isEmpty &&
                                    appState.fareState ==
                                        FareCalculationState.loading)
                                  const _LoadingVehicles()
                                // Empty state
                                else if (vehicles.isEmpty &&
                                    appState.fareState ==
                                        FareCalculationState.unavailable)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                      horizontal: 8,
                                    ),
                                    child: Center(
                                      child: Text(
                                        appState.fareError ??
                                            'No vehicles available for this route.',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                // Error state with retry
                                else if (vehicles.isEmpty &&
                                    appState.fareState ==
                                        FareCalculationState.error)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 8,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            appState.fareError ??
                                                'Could not calculate fare. Please try again.',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFFDC2626),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () => unawaited(
                                              appState.prepareVehicleSelection(),
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                // Simplified, high-performance vehicle cards
                                else ...[
                                  ...vehicles.map(
                                    (vehicle) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: VehicleOptionCard(
                                        vehicle: vehicle,
                                        isSelected:
                                            selected?.type == vehicle.type,
                                        fareReady: fareReady,
                                        onTap: () =>
                                            appState.selectVehicle(vehicle),
                                        onInfoTap: () => FareBreakdownSheet.show(
                                          context,
                                          vehicle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Demo notice banner
                                const SizedBox(height: 6),
                                const _DemoNotice(),

                                // Generous breathing room
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),

                        // 3. Dedicated Fixed Booking Footer
                        ReviewBookingFooter(
                          paymentMethod: appState.paymentMethod,
                          onSelectPayment: () => _showPaymentSelection(context),
                          onOffersCoupons: () => _showOffersCoupons(context),
                          onBookRide: canPlace ? _placeOrder : null,
                          canBook: canPlace,
                          isSubmitting: isPlacing,
                          ctaLabel: ctaLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Isolated Map Background Widget: Only rebuilds when geographic/route state changes.
/// This prevents unnecessary FlutterMap repaints during vehicle selection and payment modal toggles.
class _IsolatedMapBackground extends StatelessWidget {
  const _IsolatedMapBackground({
    required this.tileProvider,
    required this.bottomPadding,
    required this.mapController,
  });

  final TileProvider? tileProvider;
  final double bottomPadding;
  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    // Only listen to the 4 routing/map properties
    final pickup = context.select<AppState, SavedLocation?>(
      (s) => s.pickupLocation,
    );
    final destination = context.select<AppState, SavedLocation?>(
      (s) => s.destinationLocation,
    );
    final route = context.select<AppState, RouteResult?>(
      (s) => s.currentRoute,
    );
    final isRouteLoading = context.select<AppState, bool>(
      (s) => s.isRouteLoading,
    );

    if (pickup != null && destination != null) {
      return PlaceOrderMapSummary(
        pickup: pickup,
        destination: destination,
        route: route,
        isRouteLoading: isRouteLoading,
        onRetryRoute: () => unawaited(
          context.read<AppState>().calculateRoute(force: true),
        ),
        tileProvider: tileProvider,
        bottomPadding: bottomPadding,
        mapController: mapController,
      );
    }
    return const _MissingRouteCard();
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFFF9E6) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFC928)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF142B45),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF142B45),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingRouteCard extends StatelessWidget {
  const _MissingRouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEAF0F6),
      child: const Center(
        child: Text(
          'Choose a pickup and drop location first.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _LoadingVehicles extends StatelessWidget {
  const _LoadingVehicles();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF142B45)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Estimating fare...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF92400E),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo mode: Deterministic road routing and preview fares.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
