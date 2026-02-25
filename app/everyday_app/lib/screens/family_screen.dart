import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderIcon(Icons.pets), // Zampa
                    Text(
                      'Family',
                      style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.w700, 
                        color: const Color(0xFF5A8B9E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    _buildHeaderIcon(Icons.add), // Tasto più raffinato
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // LISTA CARD PREMIUM
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPremiumFamilyCard(name: 'Enrico Cirillo', status: 'At home', initial: 'E', color: const Color(0xFFF4A261)),
                    const SizedBox(height: 20),
                    _buildPremiumFamilyCard(name: 'Leone Cirillo', status: 'Not at home', initial: 'L', color: const Color(0xFF5A8B9E)),
                    const SizedBox(height: 20),
                    _buildPremiumFamilyCard(name: 'Lara Vigorelli', status: 'Not at home', initial: 'L', color: const Color(0xFFF4A261)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ICONE HEADER PREMIUM ---
  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5A8B9E), size: 24),
    );
  }

  // --- CARD FAMILY PREMIUM ---
  Widget _buildPremiumFamilyCard({required String name, required String status, required String initial, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 120,
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
              // PARTE SINISTRA
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
                      // Testi
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