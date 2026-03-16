// lib/shared/widgets/avatar_image.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarImage extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final double size;
  final Color backgroundColor;
  final Color textColor;

  const AvatarImage({
    super.key,
    this.avatarUrl,
    required this.initial,
    this.size = 48.0,
    this.backgroundColor = const Color(0xFF3D342C), // Il grigio scuro usato nel tuo design
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) {
      return _buildInitial();
    }

    return Image.network(
      avatarUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildInitial(),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35, // Dimensione testo proporzionale al cerchio
        ),
      ),
    );
  }
}