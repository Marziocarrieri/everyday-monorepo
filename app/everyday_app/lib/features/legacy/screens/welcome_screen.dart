import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:everyday_app/features/household/screens/create_household_screen.dart';
import 'package:everyday_app/features/household/screens/join_household_screen.dart';

import 'login2_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final bool fromProfile;

  const WelcomeScreen({super.key, this.fromProfile = false});

  void _openCreateFlow(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final destination = session == null
        ? const Login2Screen()
        : const CreateHouseholdScreen();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _openJoinFlow(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final destination = session == null
        ? const Login2Screen()
        : const JoinHouseholdScreen();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: fromProfile
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F9FA), Color(0xFFE3EDF2)], 
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text('Welcome!', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E), letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Let\'s set up your living space.', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.6))),
                
                const Spacer(),

                // CARD: CREATE HOUSEHOLD (Arancione Caldo)
                _buildActionCard(
                  title: 'Create household',
                  subtitle: 'Start a new home from scratch and invite your family.',
                  icon: Icons.add_home_outlined,
                  color: const Color(0xFFF4A261),
                  onTap: () {
                    _openCreateFlow(context);
                  }
                ),
                
                const SizedBox(height: 24),

                // CARD: JOIN HOUSEHOLD (Azzurro)
                _buildActionCard(
                  title: 'Join household',
                  subtitle: 'Enter an invite code to join an existing family.',
                  icon: Icons.login_rounded,
                  color: const Color(0xFF5A8B9E),
                  onTap: () {
                    _openJoinFlow(context);
                  }
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CARD D'AZIONE IN VETRO ---
  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                // Icona colorata
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                // Testi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C))),
                      const SizedBox(height: 4),
                      Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                // Freccia destra
                Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}