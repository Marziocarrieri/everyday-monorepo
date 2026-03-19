import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum HomeTaskPreviewVariant { daily, weekly }

class HomeTaskPreviewTile extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final HomeTaskPreviewVariant variant;
  final Color themeColor;

  const HomeTaskPreviewTile({
    super.key,
    required this.title,
    required this.variant,
    required this.themeColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case HomeTaskPreviewVariant.daily:
        return Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15), // Vetro semi-trasparente
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isCompleted ? 1.0 : 0.5),
                    width: 1.6,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check_rounded, size: 12, color: themeColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95), // Testo bianco
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        );
        
      case HomeTaskPreviewVariant.weekly:
        return Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}