import 'package:flutter/material.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';

/// Polished modal bottom sheet displaying the authentic fare breakdown
/// for a selected vehicle, directly derived from the existing pricing service.
///
/// Features:
/// - Exact fare components (Base fare, Distance charge, Platform fee)
/// - Total strictly equals the fare displayed on the vehicle card
/// - Clean Jugnoo/Rapido inspired information presentation
/// - Fully styled according to E-GO brand guidelines
class FareBreakdownSheet extends StatelessWidget {
  const FareBreakdownSheet({
    super.key,
    required this.vehicle,
  });

  final VehicleOption vehicle;

  static Future<void> show(BuildContext context, VehicleOption vehicle) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FareBreakdownSheet(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fare = vehicle.fareBreakdown;
    final isToto = vehicle.type == VehicleType.toto;
    final vehicleTitle = isToto ? 'E-Rickshaw' : 'Bike';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fare breakdown',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF142B45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$vehicleTitle · Estimated fare',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // 1. Base Fare
                  _BreakdownRow(
                    label: 'Base fare',
                    value: '₹${fare.baseFare.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),

                  // 2. Distance Charge
                  _BreakdownRow(
                    label:
                        'Distance charge (${fare.distanceKm.toStringAsFixed(1)} km)',
                    value: '₹${fare.distanceFare.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),

                  // 3. Platform Fee
                  _BreakdownRow(
                    label: 'Platform & safety fee',
                    value: '₹${fare.platformFee.toStringAsFixed(0)}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),

                  // 4. Total Fare
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total estimated fare',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF142B45),
                        ),
                      ),
                      Text(
                        '₹${fare.totalFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF142B45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Explanatory Note
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fares are calculated based on road route distance. Rates include applicable town taxes and fuel surcharges.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Confirm / Got It Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142B45),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF142B45),
          ),
        ),
      ],
    );
  }
}
