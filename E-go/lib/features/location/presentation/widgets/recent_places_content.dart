import 'package:flutter/material.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/widgets/empty_places_state.dart';

/// Recent Places content widget handling both empty and populated states.
class RecentPlacesContent extends StatelessWidget {
  const RecentPlacesContent({
    super.key,
    required this.recentLocations,
    required this.isLoading,
    required this.onSelectLocation,
  });

  final List<SavedLocation> recentLocations;
  final bool isLoading;
  final ValueChanged<SavedLocation> onSelectLocation;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 180.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.0),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Color(0xFFFFC928),
          ),
        ),
      );
    }

    if (recentLocations.isEmpty) {
      return const EmptyPlacesState(
        title: 'No recent places yet',
        description: 'Your selected destinations will appear here',
        icon: Icons.history_toggle_off,
      );
    }

    const navyColor = Color(0xFF142B45);
    const slateColor = Color(0xFF778397);
    const dividerColor = Color(0xFFECEEF1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08142B45),
            blurRadius: 12.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < recentLocations.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1.0,
                thickness: 1.0,
                color: dividerColor,
              ),
            _RecentPlaceRow(
              location: recentLocations[i],
              onTap: () => onSelectLocation(recentLocations[i]),
              navyColor: navyColor,
              slateColor: slateColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentPlaceRow extends StatelessWidget {
  const _RecentPlaceRow({
    required this.location,
    required this.onTap,
    required this.navyColor,
    required this.slateColor,
  });

  final SavedLocation location;
  final VoidCallback onTap;
  final Color navyColor;
  final Color slateColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              // 40x40 rounded icon tile
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEF1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignment: Alignment.center,
                child: Icon(
                  location.icon ?? iconForPlaceType(location.type),
                  size: 20.0,
                  color: navyColor,
                ),
              ),
              const SizedBox(width: 14.0),
              // Name and Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: navyColor,
                      ),
                    ),
                    if (location.subtitle != null &&
                        location.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        location.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          color: slateColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
