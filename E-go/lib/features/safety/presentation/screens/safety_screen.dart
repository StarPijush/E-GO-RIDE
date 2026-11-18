import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens & palette (DESIGN.md & Safety Reference Specification)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBackground = Color(0xFFF5F7FA);
const Color _kNavy = Color(0xFF142B45);
const Color _kYellow = Color(0xFFFFC928);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kCardBorder = Color(0xFFE7EAF0);
const Color _kSectionLabel = Color(0xFF8490A0);
const Color _kIconBg = Color(0xFFF0F3F7);
const Color _kEmergencyRed = Color(0xFFDC4545);
const Color _kDivider = Color(0xFFE7EAF0);

const String _kFontInter = 'Inter';
const String _kFontManrope = 'Manrope';

/// E-GO Safety Screen.
/// Pixel-accurate recreation of the E-GO Safety Center reference specification.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({
    super.key,
    this.showBottomNav = false,
    this.onBottomNavTap,
  });

  /// Preserved for backwards compatibility with existing caller interfaces.
  /// Bottom navigation is explicitly not rendered inside this screen.
  final bool showBottomNav;
  final ValueChanged<int>? onBottomNavTap;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: _kBackground,
      // ── Top App Bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kWhite,
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
          'Safety',
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
          SizedBox(width: 48), // Balances leading button for precise centering
        ],
      ),
      // ── Main Scrollable Body ─────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A — Branded Safety Hero Banner (#FFC928)
            const _SafetyHeroBanner(),
            const SizedBox(height: 24),

            // B — Emergency Assistance Section
            _EmergencyAssistanceSection(
              onTriggerSos: () => _showSosDialog(context),
            ),
            const SizedBox(height: 24),

            // C — During Your Ride Section (4 action rows)
            _DuringRideSection(
              onShareTrip: () => _handleShareTrip(context, appState),
              onDriverDetails: () => _handleDriverDetails(context, appState),
              onContactDriver: () => _handleContactDriver(context, appState),
              onReportIssue: () => _handleReportIssue(context),
            ),
            const SizedBox(height: 24),

            // D — Travel Safely Section (3 numbered recommendations)
            const _TravelSafelySection(),
            const SizedBox(height: 24),

            // E — Passenger Support Access Row
            _SafetySupportCard(
              onTap: () => Navigator.pushNamed(context, EGoRouter.helpSupport),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── SOS Confirmation Dialog ────────────────────────────────────────────────
  void _showSosDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: _kEmergencyRed),
            SizedBox(width: 8),
            Text(
              'Emergency SOS',
              style: TextStyle(
                fontFamily: _kFontManrope,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _kNavy,
              ),
            ),
          ],
        ),
        content: const Text(
          'In a production environment, this triggers an immediate alert to local emergency services (Jhargram Police) and your designated trusted contacts with live GPS tracking.\n\n'
          'Notice: Real emergency service dispatch is not integrated in this simulated demo environment.',
          style: TextStyle(
            fontFamily: _kFontInter,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kEmergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Emergency SOS triggered (Demo Simulation). No emergency services were contacted.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Simulate Alert'),
          ),
        ],
      ),
    );
  }

  // ── Ride Action Handlers ───────────────────────────────────────────────────
  void _handleShareTrip(BuildContext context, AppState appState) {
    final currentRide = appState.currentRide;
    if (currentRide != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trip details ready to share: Trip #${currentRide.id} to ${currentRide.destinationLocation.label}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active ride to share. Trip sharing is active during ongoing rides.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDriverDetails(BuildContext context, AppState appState) {
    final driver = appState.assignedDriver ?? appState.currentRide?.driver;
    if (driver != null) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Driver & Vehicle Details',
                style: TextStyle(
                  fontFamily: _kFontManrope,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _kYellow,
                  child: Text(
                    driver.name.isNotEmpty ? driver.name[0] : 'D',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                ),
                title: Text(
                  driver.name,
                  style: const TextStyle(
                    fontFamily: _kFontInter,
                    fontWeight: FontWeight.w600,
                    color: _kNavy,
                  ),
                ),
                subtitle: Text('Vehicle: ${driver.vehicleNumber} (${driver.vehicleName})'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: _kYellow, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${driver.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active ride. Driver details appear once a ride is assigned.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleContactDriver(BuildContext context, AppState appState) {
    final driver = appState.assignedDriver ?? appState.currentRide?.driver;
    if (driver != null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Contact ${driver.name}'),
          content: Text(
            'Vehicle: ${driver.vehicleNumber}\n(Call simulation in demo environment)',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling ${driver.name} (Simulated)...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active driver to contact. Available during active bookings.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleReportIssue(BuildContext context) {
    Navigator.pushNamed(context, EGoRouter.helpSupport);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A. Safety Hero Banner (Warm Yellow #FFC928 + Background Shield Accent)
// ─────────────────────────────────────────────────────────────────────────────
class _SafetyHeroBanner extends StatelessWidget {
  const _SafetyHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kYellow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66E8B61F), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F142B45),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Decorative background shield graphic (low opacity)
            Positioned(
              right: -16,
              bottom: -24,
              child: IgnorePointer(
                child: Icon(
                  Icons.security,
                  size: 140,
                  color: const Color(0x1A142B45), // 10% opacity navy
                ),
              ),
            ),
            // Foreground content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 40x40 Deep navy container with verified user icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kNavy,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: _kYellow,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your safety matters',
                    style: TextStyle(
                      fontFamily: _kFontManrope,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Emergency assistance and ride safety information for every trip across India.',
                    style: TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xD9142B45), // 85% opacity navy
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// B. Emergency Assistance Section
// ─────────────────────────────────────────────────────────────────────────────
class _EmergencyAssistanceSection extends StatelessWidget {
  const _EmergencyAssistanceSection({required this.onTriggerSos});

  final VoidCallback onTriggerSos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'EMERGENCY ASSISTANCE',
            style: TextStyle(
              fontFamily: _kFontInter,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSectionLabel,
              letterSpacing: 1.0,
            ),
          ),
        ),
        // White Rounded Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kCardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x1ADC4545), // Red with 10% opacity
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: _kEmergencyRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency SOS',
                          style: TextStyle(
                            fontFamily: _kFontInter,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Instantly connect with local emergency services and alert your trusted contacts with live tracking.',
                          style: TextStyle(
                            fontFamily: _kFontInter,
                            fontSize: 13,
                            color: _kSectionLabel,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Emergency Red Large Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onTriggerSos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kEmergencyRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.call, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Emergency SOS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _kFontInter,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// C. During Your Ride Section (Exact 4 Navigation Rows)
// ─────────────────────────────────────────────────────────────────────────────
class _DuringRideSection extends StatelessWidget {
  const _DuringRideSection({
    required this.onShareTrip,
    required this.onDriverDetails,
    required this.onContactDriver,
    required this.onReportIssue,
  });

  final VoidCallback onShareTrip;
  final VoidCallback onDriverDetails;
  final VoidCallback onContactDriver;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'DURING YOUR RIDE',
            style: TextStyle(
              fontFamily: _kFontInter,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSectionLabel,
              letterSpacing: 1.0,
            ),
          ),
        ),
        // White Rounded Card with 4 Rows
        Container(
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kCardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.share_location,
                  label: 'Share Trip',
                  onTap: onShareTrip,
                ),
                const Divider(height: 1, thickness: 1, indent: 70, color: _kDivider),
                _ActionRow(
                  icon: Icons.badge_outlined,
                  label: 'Driver & Vehicle Details',
                  onTap: onDriverDetails,
                ),
                const Divider(height: 1, thickness: 1, indent: 70, color: _kDivider),
                _ActionRow(
                  icon: Icons.phone_in_talk,
                  label: 'Contact Driver',
                  onTap: onContactDriver,
                ),
                const Divider(height: 1, thickness: 1, indent: 70, color: _kDivider),
                _ActionRow(
                  icon: Icons.report_problem_outlined,
                  label: 'Report a Safety Issue',
                  onTap: onReportIssue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // 40x40 Icon container in #F0F3F7
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _kNavy, size: 22),
                ),
                const SizedBox(width: 16),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _kNavy,
                    ),
                  ),
                ),
                // Trailing Chevron
                const Icon(
                  Icons.chevron_right,
                  color: _kSectionLabel,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// D. Travel Safely Section (3 Recommendations with Numeric Badges)
// ─────────────────────────────────────────────────────────────────────────────
class _TravelSafelySection extends StatelessWidget {
  const _TravelSafelySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TRAVEL SAFELY',
            style: TextStyle(
              fontFamily: _kFontInter,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSectionLabel,
              letterSpacing: 1.0,
            ),
          ),
        ),
        // White Rounded Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kCardBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Tip 01
              _buildTipRow(
                badgeNumber: '01',
                text: 'Verify your driver and vehicle before boarding.',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, thickness: 1, indent: 38, color: _kDivider),
              ),
              // Tip 02
              _buildTipRow(
                badgeNumber: '02',
                text: 'Confirm your destination and fare before starting your trip.',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, thickness: 1, indent: 38, color: _kDivider),
              ),
              // Tip 03
              _buildTipRow(
                badgeNumber: '03',
                text: 'Share your trip details with someone you trust.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow({required String badgeNumber, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: _kIconBg,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            badgeNumber,
            style: const TextStyle(
              fontFamily: _kFontInter,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: _kFontInter,
              fontSize: 14,
              color: _kNavy,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// E. Passenger Support Access Row
// ─────────────────────────────────────────────────────────────────────────────
class _SafetySupportCard extends StatelessWidget {
  const _SafetySupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  // 48x48 Icon container in pale yellow (primary-container/20)
                  _SupportIconBadge(),
                  SizedBox(width: 16),
                  // Title + Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            fontFamily: _kFontInter,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dedicated passenger incident team',
                          style: TextStyle(
                            fontFamily: _kFontInter,
                            fontSize: 13,
                            color: _kSectionLabel,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trailing Chevron
                  Icon(
                    Icons.chevron_right,
                    color: _kSectionLabel,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportIconBadge extends StatelessWidget {
  const _SupportIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0x33FFC928), // 20% opacity primary yellow
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.support_agent,
        color: _kNavy,
        size: 26,
      ),
    );
  }
}
