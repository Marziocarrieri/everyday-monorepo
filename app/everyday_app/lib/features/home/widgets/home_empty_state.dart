import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeEmptyState extends StatelessWidget {
  final String message;

  const HomeEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3D342C).withValues(alpha: 0.7),
        fontSize: 12,
      ),
    );
  }
}
