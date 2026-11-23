import 'package:flutter/material.dart';

/// Full-width white "Select on map" button matching Reference Sets A & B.
class SelectOnMapButton extends StatelessWidget {
  const SelectOnMapButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF142B45);

    return Container(
      width: double.infinity,
      height: 54.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: const Center(
            child: Text(
              'Select on map',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: navyColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
