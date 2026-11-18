import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:e_go/features/home/presentation/home_screen.dart';
import 'package:e_go/features/rides/presentation/screens/my_rides_screen.dart';
import 'package:e_go/features/safety/presentation/screens/safety_screen.dart';
import 'package:e_go/features/account/presentation/profile_screen.dart';
import 'package:e_go/shared/widgets/ego_gooey_bottom_navigation.dart';

/// E-GO primary application navigation shell.
///
/// Houses the four primary destinations (Home, Rides, Safety, Account) and the
/// single shared [EgoGooeyBottomNavigation] instance.
///
/// Child screens are pushed onto the root Navigator, automatically hiding
/// the bottom navigation bar and restoring it upon popping.
class EGoMainShell extends StatefulWidget {
  const EGoMainShell({super.key, this.initialIndex = 0, this.tileProvider});

  /// The destination index to show when mounting the shell.
  /// 0: Home, 1: Rides, 2: Safety, 3: Account
  final int initialIndex;

  /// Injectable map tiles for tests; production uses the default provider.
  final TileProvider? tileProvider;

  /// Retrieves the nearest [EGoMainShellState] ancestor if available.
  static EGoMainShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<EGoMainShellState>();
  }

  /// Programmatically switches the active tab of the nearest [EGoMainShell].
  static void switchTab(BuildContext context, int index) {
    final state = of(context);
    if (state != null) {
      state.setIndex(index);
    }
  }

  @override
  State<EGoMainShell> createState() => EGoMainShellState();
}

class EGoMainShellState extends State<EGoMainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant EGoMainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.initialIndex.clamp(0, 3);
      });
    }
  }

  /// Switches the active primary tab with fluid GooeyNav animation.
  void setIndex(int index) {
    final target = index.clamp(0, 3);
    if (_currentIndex == target) return;
    setState(() {
      _currentIndex = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            EGoHomeScreen(tileProvider: widget.tileProvider),
            const MyRidesScreen(),
            const SafetyScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: EgoGooeyBottomNavigation(
        selectedIndex: _currentIndex,
        onTap: setIndex,
      ),
    );
  }
}
