import 'package:flutter/material.dart';

const Color _kNavy = Color(0xFF142B45);
const Color _kYellow = Color(0xFFFFC928);
const Color _kSecondaryText = Color(0xFF8490A0);
const Color _kDivider = Color(0xFFE7EAF0);
const String _kFontInter = 'Inter';

/// Category filter options for E-GO Rides screen.
enum RideFilter { all, electricTotos, bike, shared }

/// Minimalist horizontal category tabs with yellow underline indicator.
class RideFilterTabs extends StatelessWidget {
  const RideFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final RideFilter selectedFilter;
  final ValueChanged<RideFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        border: Border(
          bottom: BorderSide(color: _kDivider, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTab(filter: RideFilter.all, label: 'All'),
            const SizedBox(width: 32),
            _buildTab(
              filter: RideFilter.electricTotos,
              label: 'Electric TOTOs',
            ),
            const SizedBox(width: 32),
            _buildTab(filter: RideFilter.bike, label: 'Bike'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({required RideFilter filter, required String label}) {
    final isSelected = selectedFilter == filter;

    return InkWell(
      onTap: () => onFilterSelected(filter),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: IntrinsicWidth(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFontInter,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kNavy : _kSecondaryText,
              ),
            ),
            const Spacer(),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? _kYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
