import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutline;
  final VoidCallback onTap;

  const ProfileActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.isOutline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isOutline
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isOutline ? color : Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isOutline ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}