import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCompletionBadge extends StatelessWidget {
  final int percent;
  final Color accentColor;

  const HomeCompletionBadge({
    super.key,
    required this.percent,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
    );
  }
}
