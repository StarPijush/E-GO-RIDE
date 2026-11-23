import 'package:flutter/material.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';

/// Dedicated fixed bottom action footer for the Review Your Ride bottom sheet.
///
/// Features:
/// 1. Row 1:
///    - Left: Payment method selector with cash icon, method name ('Cash'),
///      and matching right-facing chevron_right.
///    - Vertical subtle divider line.
///    - Right: Offers & Coupons action with yellow '%' badge, label,
///      and matching right-facing chevron_right.
/// 2. Row 2:
///    - Prominent full-width yellow primary CTA button ('Book Bike', 'Book Toto', 'Book your ride').
///    - Pill-like rounded corners (28px radius) with subtle shadow.
/// 3. Bottom safe area handling.
class ReviewBookingFooter extends StatelessWidget {
  const ReviewBookingFooter({
    super.key,
    required this.paymentMethod,
    required this.onSelectPayment,
    required this.onOffersCoupons,
    required this.onBookRide,
    required this.canBook,
    required this.isSubmitting,
    this.ctaLabel = 'Book your ride',
  });

  final PaymentMethod paymentMethod;
  final VoidCallback onSelectPayment;
  final VoidCallback onOffersCoupons;
  final VoidCallback? onBookRide;
  final bool canBook;
  final bool isSubmitting;
  final String ctaLabel;

  String get _paymentName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B45).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final horizontalPadding = isCompact ? 12.0 : 16.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Payment Method (Left) & Offers & Coupons (Right)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Left: Payment Method Selector
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                            child: InkWell(
                              onTap: isSubmitting ? null : onSelectPayment,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(14),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 8 : 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.payments_outlined,
                                      size: 20,
                                      color: Color(0xFF142B45),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _paymentName,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF142B45),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Subtle Vertical Divider
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFE2E8F0),
                        ),

                        // Right: Offers & Coupons
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(14),
                            ),
                            child: InkWell(
                              onTap: isSubmitting ? null : onOffersCoupons,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(14),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 8 : 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFFC928,
                                        ).withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '%',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF142B45),
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Offers & Coupons',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF142B45),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Full-Width Prominent Primary CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: canBook && !isSubmitting ? onBookRide : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC928), // E-GO Yellow
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        foregroundColor: const Color(0xFF142B45), // Deep Navy
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: canBook && !isSubmitting ? 2 : 0,
                        shadowColor: const Color(
                          0xFF142B45,
                        ).withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF142B45),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Connecting Drivers...',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF142B45),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              ctaLabel,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF142B45),
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
