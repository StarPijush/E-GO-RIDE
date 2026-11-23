import 'package:flutter/material.dart';

/// Reusable empty state container matching Reference Set A.
class EmptyPlacesState extends StatelessWidget {
  const EmptyPlacesState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.history_toggle_off,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF142B45);
    const slateColor = Color(0xFF778397);
    const iconBg = Color(0xFFECEEF1);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05142B45),
            blurRadius: 12.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 44x44 rounded circular muted-grey icon container
          Container(
            width: 44.0,
            height: 44.0,
            decoration: const BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22.0,
              color: slateColor,
            ),
          ),
          const SizedBox(height: 12.0),
          // Heading
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: navyColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6.0),
          // Supporting text
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
                fontWeight: FontWeight.w400,
                color: slateColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
