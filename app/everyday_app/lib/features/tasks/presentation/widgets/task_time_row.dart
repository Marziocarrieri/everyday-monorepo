import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskTimeRow extends StatelessWidget {
  final String timeRange;
  final bool warmStyle;
  final Color? textColor;

  const TaskTimeRow({
    super.key,
    required this.timeRange,
    this.warmStyle = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        textColor ??
        (warmStyle
            ? const Color(0xFF3D342C).withValues(alpha: 0.58)
            : const Color(0xFF3D342C).withValues(alpha: 0.6));

    return Text(
      timeRange,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (warmStyle ? GoogleFonts.manrope : GoogleFonts.poppins)(
        fontSize: 12,
        fontWeight: warmStyle ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: warmStyle ? 0.1 : 0,
        color: effectiveColor,
      ),
    );
  }
}
