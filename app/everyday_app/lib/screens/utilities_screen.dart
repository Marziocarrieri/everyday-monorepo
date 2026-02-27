import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'fridge_keeping_screen.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER BLOCCATO (No rimbalzi) E RAFFINATO
              SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Utilities',
                    style: GoogleFonts.poppins(
                      fontSize: 24, 
                      fontWeight: FontWeight.w700, 
                      color: const Color(0xFF5A8B9E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // BOTTONI PREMIUM
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FridgeKeepingScreen()),
                  );
                },
                child: _buildPremiumMenuButton(icon: Icons.kitchen, text: 'Fridge Keeping'),
              ),             
              const SizedBox(height: 24),
              _buildPremiumMenuButton(icon: Icons.list_alt_rounded, text: 'Provisions List'),
            ],
          ),
        ),
      ),
    );
  }

  // --- BOTTONI GRANDI PREMIUM ---
  Widget _buildPremiumMenuButton({required IconData icon, required String text}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32), // Curvatura Premium
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 130, // Un po' più alti per farli respirare
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF4A261).withValues(alpha: 0.2), 
                Colors.white.withValues(alpha: 0.5)
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2), // Riflesso
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A261).withValues(alpha: 0.08), // Ombra morbida arancione
                blurRadius: 30, offset: const Offset(0, 15)
              )
            ],
          ),
          child: Row(
            children: [
              // L'icona ora è dentro un suo "dischetto" di vetro per risaltare di più
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Icon(icon, color: const Color(0xFF5A8B9E), size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  text, 
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.w700, 
                    color: const Color(0xFF3D342C),
                    letterSpacing: -0.5, // Look moderno
                  )
                ),
              ),
              // Freccina elegante per far capire che è cliccabile
              Icon(Icons.chevron_right_rounded, color: const Color(0xFF5A8B9E).withValues(alpha: 0.5), size: 32),
            ],
          ),
        ),
      ),
    );
  }
}