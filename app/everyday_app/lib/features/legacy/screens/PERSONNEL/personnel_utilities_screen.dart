import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// I collegamenti alle pagine del Personnel che andremo a creare
import 'personnel_fridge_keeping_screen.dart';
import 'personnel_provision_list_screen.dart';

class PersonnelUtilitiesScreen extends StatefulWidget {
  const PersonnelUtilitiesScreen({super.key});

  @override
  State<PersonnelUtilitiesScreen> createState() => _PersonnelUtilitiesScreenState();
}

class _PersonnelUtilitiesScreenState extends State<PersonnelUtilitiesScreen> {
  
  // ==========================================
  // BUILD PRINCIPALE DELLO SCHERMO
  // ==========================================
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
              // ==========================================
              // HEADER
              // ==========================================
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
              
              // ==========================================
              // BOTTONI MENU 
              // ==========================================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PersonnelFridgeKeepingScreen()),
                  );
                },
                child: _buildPremiumMenuButton(icon: Icons.kitchen, text: 'Fridge Keeping'),
              ),             
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PersonnelProvisionListScreen()),
                  );
                },
                child: _buildPremiumMenuButton(
                  icon: Icons.shopping_cart_outlined, 
                  text: 'Provision List',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENTE: BOTTONE MENU PREMIUM
  // ==========================================
  Widget _buildPremiumMenuButton({required IconData icon, required String text}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32), 
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 130, 
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2), 
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A261).withValues(alpha: 0.08), 
                blurRadius: 30, offset: const Offset(0, 15)
              )
            ],
          ),
          child: Row(
            children: [
              // Icona nel dischetto di vetro
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
              
              // Testo del Menu
              Expanded(
                child: Text(
                  text, 
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.w700, 
                    color: const Color(0xFF3D342C),
                    letterSpacing: -0.5, 
                  )
                ),
              ),
              
              // Freccia direzionale
              Icon(Icons.chevron_right_rounded, color: const Color(0xFF5A8B9E).withValues(alpha: 0.5), size: 32),
            ],
          ),
        ),
      ),
    );
  }
}