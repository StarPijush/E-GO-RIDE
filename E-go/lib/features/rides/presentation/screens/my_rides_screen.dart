import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';
import '../widgets/ride_filter_tabs.dart';
import '../widgets/rides_empty_state.dart';
import '../widgets/ride_card.dart';

const Color _kBackground = Color(0xFFF5F7FA);
const Color _kNavy = Color(0xFF142B45);
const Color _kDivider = Color(0xFFE7EAF0);
const String _kFontManrope = 'Manrope';

/// E-GO Your Rides screen.
/// Pixel-accurate recreation of the E-GO Your Rides reference specification.
class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  RideFilter _selectedFilter = RideFilter.all;

  void _onFilterSelected(RideFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onBookRide() {
    // Opens the customer ride booking flow
    Navigator.pushNamed(context, EGoRouter.locationSelection);
  }

  List<RideRecord> _getFilteredRides(List<RideRecord> allRides) {
    switch (_selectedFilter) {
      case RideFilter.all:
        return allRides;
      case RideFilter.electricTotos:
        return allRides
            .where((ride) => ride.vehicleType == VehicleType.toto)
            .toList();
      case RideFilter.bike:
        return allRides
            .where((ride) => ride.vehicleType == VehicleType.bike)
            .toList();
      case RideFilter.shared:
        return const <RideRecord>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    final allRides = context.watch<AppState>().allRides;
    final filteredRides = _getFilteredRides(allRides);

    return Scaffold(
      backgroundColor: _kBackground,
      // ── Top App Bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kNavy, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Go back',
          splashRadius: 20,
        ),
        title: const Text(
          'Your rides',
          style: TextStyle(
            fontFamily: _kFontManrope,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kNavy,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 48), // Balances leading button for exact centering
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, thickness: 1.0, color: _kDivider),
        ),
      ),
      // ── Main Content Area ────────────────────────────────────────────────
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Ride Category Tabs (All, Electric TOTOs, Bike)
          RideFilterTabs(
            selectedFilter: _selectedFilter,
            onFilterSelected: _onFilterSelected,
          ),

          // 2. Filtered Content: Empty State or Populated List
          Expanded(
            child: filteredRides.isEmpty
                ? RidesEmptyState(onBookPressed: _onBookRide)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: filteredRides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        RideCard(ride: filteredRides[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
