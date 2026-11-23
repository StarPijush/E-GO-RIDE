import 'package:flutter/material.dart';

/// Fixed-width coaxial route marker column connecting pickup and destination.
class RouteMarkerColumn extends StatelessWidget {
  const RouteMarkerColumn({super.key});

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF142B45);
    const yellowColor = Color(0xFFFFC928);

    return SizedBox(
      width: 20.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4.0),
          // Pickup marker: 14px yellow outer ring with 5px navy center
          Container(
            width: 14.0,
            height: 14.0,
            decoration: const BoxDecoration(
              color: yellowColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 5.0,
              height: 5.0,
              decoration: const BoxDecoration(
                color: navyColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Continuous 2px vertical navy line
          Expanded(
            child: Container(
              width: 2.0,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xCC142B45),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
          // Destination marker: 14px navy outer ring with 6px white center
          Container(
            width: 14.0,
            height: 14.0,
            decoration: const BoxDecoration(
              color: navyColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 6.0,
              height: 6.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 4.0),
        ],
      ),
    );
  }
}
