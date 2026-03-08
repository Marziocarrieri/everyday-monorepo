import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskTimeRow extends StatelessWidget {
  final String timeRange;

  const TaskTimeRow({super.key, required this.timeRange});

  @override
  Widget build(BuildContext context) {
    return Text(
      timeRange,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3D342C).withValues(alpha: 0.6),
      ),
    );
  }
}
