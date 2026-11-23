import 'package:flutter/material.dart';

enum PlaceCategory { recent, saved }

/// Segmented selector for Location list: "Recent places" vs "Saved places".
class PlaceCategorySelector extends StatelessWidget {
  const PlaceCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final PlaceCategory selectedCategory;
  final ValueChanged<PlaceCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFFC928);
    const inactiveColor = Colors.transparent;
    const activeTextColor = Color(0xFF142B45);
    const inactiveTextColor = Color(0xFF778397);
    const containerBg = Color(0xFFECEEF1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(9999.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Recent places',
              isSelected: selectedCategory == PlaceCategory.recent,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              onTap: () => onChanged(PlaceCategory.recent),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Saved places',
              isSelected: selectedCategory == PlaceCategory.saved,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              onTap: () => onChanged(PlaceCategory.saved),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeTextColor,
    required this.inactiveTextColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(9999.0),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14142B45),
                      blurRadius: 2.0,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeTextColor : inactiveTextColor,
                letterSpacing: -0.01,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
