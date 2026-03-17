import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeWeeklyTaskCard extends StatelessWidget {
  final VoidCallback onTap;

  const HomeWeeklyTaskCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: 110, 
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              // Sfondo Arancione Glass
              color: const Color(0xFFF4A261).withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF4A261).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // Ombra tenue arancione sotto il dischetto bianco
                        color: const Color(0xFFF4A261).withOpacity(0.2), 
                        blurRadius: 10, 
                        offset: const Offset(0, 4)
                      )
                    ]
                  ),
                  // --- MODIFICA: Icona diventata BLU ---
                  child: const Icon(Icons.date_range_rounded, color: Color(0xFF5A8B9E), size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // --- MODIFICA: Testo cambiato ---
                        'Week Task', 
                        style: GoogleFonts.poppins(
                          fontSize: 19, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF3D342C),
                          letterSpacing: -0.5,
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View upcoming tasks', 
                        style: GoogleFonts.poppins(
                          fontSize: 13, 
                          fontWeight: FontWeight.w500, 
                          color: const Color(0xFF3D342C).withOpacity(0.6),
                        )
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded, 
                  // --- MODIFICA: Freccina diventata BLU ---
                  color: const Color(0xFF5A8B9E).withOpacity(0.5), 
                  size: 32
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}