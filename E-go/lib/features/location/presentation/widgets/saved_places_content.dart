import 'package:flutter/material.dart';
import 'package:e_go/mock_data/mock_data.dart';
import 'package:e_go/features/location/presentation/widgets/empty_places_state.dart';

/// Saved Places list card and Add New Location card matching Reference Set B.
class SavedPlacesContent extends StatelessWidget {
  const SavedPlacesContent({
    super.key,
    required this.savedPlaces,
    required this.onSelectPlace,
    required this.onEditPlace,
    required this.onAddNewLocation,
  });

  final List<SavedPlace> savedPlaces;
  final ValueChanged<SavedPlace> onSelectPlace;
  final ValueChanged<SavedPlace> onEditPlace;
  final VoidCallback onAddNewLocation;

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF142B45);
    const slateColor = Color(0xFF778397);
    const dividerColor = Color(0xFFECEEF1);
    const paleYellow = Color(0xFFFFDF95);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Saved Places List Card
        if (savedPlaces.isEmpty)
          const EmptyPlacesState(
            title: 'No saved places',
            description: 'Save home, work, or favorite Toto stands for quick rides',
            icon: Icons.bookmark_border,
          )
        else
          Container(
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
                for (int i = 0; i < savedPlaces.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: dividerColor,
                    ),
                  _SavedPlaceRow(
                    place: savedPlaces[i],
                    onTap: () => onSelectPlace(savedPlaces[i]),
                    onEdit: () => onEditPlace(savedPlaces[i]),
                    navyColor: navyColor,
                    slateColor: slateColor,
                    paleYellow: paleYellow,
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 12.0),

        // ── Add New Location Card ──
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08142B45),
                blurRadius: 10.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddNewLocation,
              borderRadius: BorderRadius.circular(18.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 14.0,
                ),
                child: Row(
                  children: [
                    // Pale yellow 40x40 icon well with plus icon
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: const Color(0x66FFDF95),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        size: 20.0,
                        color: navyColor,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    const Expanded(
                      child: Text(
                        'Add new location',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: navyColor,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20.0,
                      color: slateColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedPlaceRow extends StatelessWidget {
  const _SavedPlaceRow({
    required this.place,
    required this.onTap,
    required this.onEdit,
    required this.navyColor,
    required this.slateColor,
    required this.paleYellow,
  });

  final SavedPlace place;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Color navyColor;
  final Color slateColor;
  final Color paleYellow;

  @override
  Widget build(BuildContext context) {
    final isHome = place.type == SavedPlaceType.home;
    final iconBgColor = isHome
        ? const Color(0x66FFDF95)
        : const Color(0xFFECEEF1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              // 40x40 icon tile
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignment: Alignment.center,
                child: Icon(
                  place.icon,
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
                      place.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: navyColor,
                      ),
                    ),
                    if (place.address.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        place.address,
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
              // Edit button
              SizedBox(
                width: 32.0,
                height: 32.0,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18.0,
                  icon: const Icon(Icons.edit_outlined),
                  color: slateColor,
                  tooltip: 'Edit ${place.label}',
                  onPressed: onEdit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
