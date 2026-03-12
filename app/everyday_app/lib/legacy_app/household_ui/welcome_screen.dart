// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/legacy_app/services/welcome_flow_service.dart';

class WelcomeScreen extends StatelessWidget {
  final bool fromProfile;
  static final WelcomeFlowService _welcomeFlowService = WelcomeFlowService();

  const WelcomeScreen({super.key, this.fromProfile = false});

  void _openCreateFlow(BuildContext context) {
    final routeName = _welcomeFlowService.hasActiveSession
        ? AppRouteNames.createHousehold
        : AppRouteNames.login2;
    Navigator.of(context).pushNamed(routeName);
  }

  void _openJoinFlow(BuildContext context) {
    final routeName = _welcomeFlowService.hasActiveSession
        ? AppRouteNames.joinHousehold
        : AppRouteNames.login2;
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Abbiamo rimosso l'AppBar standard per mantenere il gradiente ininterrotto
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F9FA), Color(0xFFE3EDF2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Padding verticale ridotto per far spazio al bottone back
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- BOTTONE BACK PREMIUM (Visibile solo se fromProfile == true) ---
                if (fromProfile) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A8B9E).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF5A8B9E),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // Spazio tra il bottone e il titolo
                ] else ...[
                  const SizedBox(height: 20), // Spazio iniziale se non c'è il bottone
                ],

                // HEADER
                Text(
                  'Welcome!', 
                  style: GoogleFonts.poppins(
                    fontSize: 32, 
                    fontWeight: FontWeight.w800, 
                    color: const Color(0xFF5A8B9E), 
                    letterSpacing: -0.5
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s set up your living space.', 
                  style: GoogleFonts.poppins(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500, 
                    color: const Color(0xFF3D342C).withValues(alpha: 0.6)
                  )
                ),
                
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