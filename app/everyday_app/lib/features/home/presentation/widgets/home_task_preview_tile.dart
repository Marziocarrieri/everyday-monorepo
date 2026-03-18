import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum HomeTaskPreviewVariant { daily, weekly }

class HomeTaskPreviewTile extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final Color accentColor;
  final HomeTaskPreviewVariant variant;

  const HomeTaskPreviewTile({
    super.key,
    required this.title,
    required this.accentColor,
    required this.variant,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case HomeTaskPreviewVariant.daily:
        return Opacity(
          opacity: 0.9,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? accentColor.withValues(alpha: 0.95)
                      : Colors.transparent,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1.6,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D342C),
                  ),
                ),
              ),
            ],
          ),
        );
      case HomeTaskPreviewVariant.weekly:
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D342C).withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
