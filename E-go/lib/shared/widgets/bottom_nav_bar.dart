import 'package:flutter/material.dart';
import 'ego_gooey_bottom_navigation.dart';

export 'ego_gooey_bottom_navigation.dart';
export 'journey_route_icon.dart';

/// E-GO shared bottom navigation component.
///
/// Backwards-compatible wrapper around the premium native [EgoGooeyBottomNavigation].
class EGoBottomNavBar extends StatelessWidget {
  const EGoBottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
    this.profileLabel = 'Account',
    this.showGestureIndicator = false,
  });

  final int selectedIndex;
  final ValueChanged<int>? onTap;
  final String profileLabel;
  final bool showGestureIndicator;

  @override
  Widget build(BuildContext context) {
    return EgoGooeyBottomNavigation(
      selectedIndex: selectedIndex,
      onTap: onTap,
      profileLabel: profileLabel,
    );
  }
}
