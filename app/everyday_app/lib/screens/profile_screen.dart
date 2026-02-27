import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_context.dart';
import 'login2_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      AppContext.instance.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login2Screen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  String _initialFromName(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppContext.instance.profile;
    final householdId = AppContext.instance.householdId;
    if (householdId == null || profile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Session context not ready'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER PREMIUM BLOCCATO
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A8B9E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isLoggingOut ? null : _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFF5A8B9E)),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // INFO UTENTE PREMIUM
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 85, height: 85,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D342C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF3D342C).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))
                      ]
                    ),
                    child: Center(child: Text(_initialFromName(profile.name), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name ?? '', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C), letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Text('Host', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF5A8B9E))),
                        Text('HomeID: $householdId', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF5A8B9E).withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  // Tasto Edit Premium
                  Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
                      boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))]
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF5A8B9E), size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // BOTTONI PREMIUM
              _buildPremiumMenuButton(icon: Icons.fastfood_outlined, text: 'Your Diet'),
              const SizedBox(height: 24),
              _buildPremiumMenuButton(icon: Icons.receipt_long_rounded, text: 'Your Home'),
            ],
          ),
        ),
      ),
    );
  }

  // --- BOTTONI GRANDI PREMIUM ---
  Widget _buildPremiumMenuButton({required IconData icon, required String text}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [const Color(0xFFF4A261).withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFF4A261).withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Icon(icon, color: const Color(0xFF5A8B9E), size: 28),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  text, 
                  style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C), letterSpacing: -0.3)
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: const Color(0xFF5A8B9E).withValues(alpha: 0.5), size: 32),
            ],
          ),
        ),
      ),
    );
  }
}