import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design constants (matches HTML reference + DESIGN.md)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBackground = Color(0xFFF5F7FA);
const Color _kNavy = Color(0xFF142B45);
const Color _kYellow = Color(0xFFFFC928);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kCardBorder = Color(0xFFE7EAF0);
const Color _kSectionLabel = Color(0xFF8490A0);
const Color _kChevron = Color(0xFF8490A0);
const Color _kDivider = Color(0xFFE7EAF0);
const Color _kRowRipple = Color(0xFFEDF0F4);
const Color _kLogoutText = Color(0xFFDC2626);
const Color _kLogoutBorder = Color(0xFFFFCDD2); // red-200 equivalent

const String _kFontInter = 'Inter';
const String _kFontManrope = 'Manrope';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Account/Profile screen
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;

    return Scaffold(
      backgroundColor: _kBackground,
      // ── Top App Bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Back button — standard Navigator.pop
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kNavy, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Go back',
          splashRadius: 20,
        ),
        // Centered title
        title: const Text(
          'Account',
          style: TextStyle(
            fontFamily: _kFontManrope,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kNavy,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        // Invisible spacer to balance leading button and keep title centred
        actions: [const SizedBox(width: 48)],
      ),
      // ── Scrollable body ──────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A — Profile hero card
            _ProfileHeaderCard(profile: profile),
            const SizedBox(height: 24),

            // B — Activity section
            _AccountSection(
              title: 'ACTIVITY',
              items: [
                _AccountTile(
                  icon: Icons.history,
                  label: 'My rides',
                  onTap: () => Navigator.pushNamed(context, EGoRouter.myRides),
                ),
                _AccountTile(
                  icon: Icons.bookmark_border,
                  label: 'Saved places',
                  onTap: () =>
                      Navigator.pushNamed(context, EGoRouter.savedPlaces),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // C — Payments section
            _AccountSection(
              title: 'PAYMENTS',
              items: [
                _AccountTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment methods',
                  onTap: () =>
                      Navigator.pushNamed(context, EGoRouter.paymentMethods),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // D — Preferences section
            _AccountSection(
              title: 'PREFERENCES',
              items: [
                _AccountTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () =>
                      Navigator.pushNamed(context, EGoRouter.notifications),
                ),
                _AccountTile(
                  icon: Icons.settings_outlined,
                  label: 'App settings',
                  onTap: () =>
                      Navigator.pushNamed(context, EGoRouter.settings),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // E — Support section
            _AccountSection(
              title: 'SUPPORT',
              items: [
                _AccountTile(
                  icon: Icons.help_outline,
                  label: 'Help & support',
                  onTap: () =>
                      Navigator.pushNamed(context, EGoRouter.helpSupport),
                ),
                _AccountTile(
                  icon: Icons.info_outline,
                  label: 'About E-GO',
                  onTap: () => Navigator.pushNamed(context, EGoRouter.about),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // F — Log out button
            _LogoutButton(
              onPressed: () => _showLogoutDialog(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Logout confirmation dialog ─────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AppState>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  EGoRouter.login,
                  (_) => false,
                );
              }
            },
            child: const Text(
              'Log out',
              style: TextStyle(color: _kLogoutText),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Card
// Warm-yellow card with circular avatar, name, phone and edit button.
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final dynamic profile; // AuthUser

  @override
  Widget build(BuildContext context) {
    final String name = (profile.name != null &&
            (profile.name as String).isNotEmpty)
        ? profile.name as String
        : 'Pijush Mahato';
    final String phone = (profile.phone != null &&
            (profile.phone as String).isNotEmpty)
        ? profile.phone as String
        : '+91 98765 43210';
    final String initial =
        name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      decoration: BoxDecoration(
        color: _kYellow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F142B45),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          // Circular white avatar with initial
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kWhite,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14142B45),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: _kFontManrope,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _kFontManrope,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kNavy,
                    height: 1.2,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xCC142B45), // navy/80
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Edit button — circular, deep-navy background, white icon
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, EGoRouter.editProfile),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kNavy,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A142B45),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit,
                color: _kWhite,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section — section heading + white card of tiles
// ─────────────────────────────────────────────────────────────────────────────
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_AccountTile> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: _kFontInter,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSectionLabel,
              letterSpacing: 1.0,
              height: 1.4,
            ),
          ),
        ),
        // White rounded card
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
              children: () {
                final children = <Widget>[];
                for (int i = 0; i < items.length; i++) {
                  children.add(items[i]);
                  if (i < items.length - 1) {
                    // Inset divider: starts after icon area (20px padding + 24px icon + 16px gap = 60px)
                    children.add(
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 60,
                        endIndent: 0,
                        color: _kDivider,
                      ),
                    );
                  }
                }
                return children;
              }(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Tile — 72dp tall row: icon | label | chevron
// ─────────────────────────────────────────────────────────────────────────────
class _AccountTile extends StatelessWidget {
  const _AccountTile({
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
        highlightColor: _kRowRipple,
        splashColor: _kRowRipple,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Leading icon
                Icon(icon, size: 24, color: _kNavy),
                const SizedBox(width: 16),
                // Label — expands to fill, allows wrapping for long text
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _kNavy,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Trailing chevron
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: _kChevron,
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
// Log out button — full-width, white background, red border, red label
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _kWhite,
          side: const BorderSide(color: _kLogoutBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            _kLogoutText.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, size: 20, color: _kLogoutText),
            SizedBox(width: 8),
            Text(
              'Log out',
              style: TextStyle(
                fontFamily: _kFontInter,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _kLogoutText,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
