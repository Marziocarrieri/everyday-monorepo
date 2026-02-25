import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // HEADER PREMIUM BLOCCATO
              SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Personnel',
                    style: GoogleFonts.poppins(
                      fontSize: 24, 
                      fontWeight: FontWeight.w700, 
                      color: const Color(0xFF5A8B9E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // LISTA CARD PREMIUM (3 righe di testo)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPremiumPersonnelCard(
                      name: 'Luana Gonzalez', role: 'HouseKeeper', status: 'At home', initial: 'L', color: const Color(0xFFF4A261),
                    ),
                    const SizedBox(height: 20),
                    _buildPremiumPersonnelCard(
                      name: 'Romeo De Luca', role: 'Gardener', status: 'Not at home', initial: 'R', color: const Color(0xFFF4A261),
                    ),
                    const SizedBox(height: 20),
                    _buildPremiumPersonnelCard(
                      name: 'Simon Pearson', role: 'Plumber', status: 'Not at home', initial: 'S', color: const Color(0xFFF4A261),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD PERSONALE PREMIUM ---
  Widget _buildPremiumPersonnelCard({
    required String name, required String role, required String status, required String initial, required Color color
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 135, // Più alta per far respirare le 3 righe
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Avatar con piccola ombra
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D342C), 
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3D342C).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Center(child: Text(initial, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                      ),
                      const SizedBox(width: 16),
                      // 3 Righe di Testi
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              overflow: TextOverflow.ellipsis, 
                              style: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                            ),
                            Text(
                              role,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // DIVISORE SFUMATO
              Container(
                width: 1, 
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.0)]
                  )
                ),
              ),
              // PARTE DESTRA
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'View\nActivity',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E), fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}