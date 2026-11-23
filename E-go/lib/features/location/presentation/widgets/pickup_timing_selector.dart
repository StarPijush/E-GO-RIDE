import 'package:flutter/material.dart';

enum PickupTiming { now, later }

/// Segmented selector for pickup timing: "Pick up now" vs "Schedule for later".
class PickupTimingSelector extends StatelessWidget {
  const PickupTimingSelector({
    super.key,
    required this.selectedTiming,
    required this.onChanged,
  });

  final PickupTiming selectedTiming;
  final ValueChanged<PickupTiming> onChanged;

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
              label: 'Pick up now',
              isSelected: selectedTiming == PickupTiming.now,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              onTap: () => onChanged(PickupTiming.now),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Schedule for later',
              isSelected: selectedTiming == PickupTiming.later,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              onTap: () => onChanged(PickupTiming.later),
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
