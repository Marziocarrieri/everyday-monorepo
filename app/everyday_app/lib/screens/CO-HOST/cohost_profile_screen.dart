import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class CohostProfileScreen extends StatefulWidget {
  const CohostProfileScreen({super.key});

  @override
  State<CohostProfileScreen> createState() => _CohostProfileScreenState();
}

class _CohostProfileScreenState extends State<CohostProfileScreen> {
  bool _editingNickname = false;
  late TextEditingController _nicknameController;

  // Dati Mockati (Finti) per il design
  final String _mockNickname = 'Leone';
  final String _mockRole = 'Co-Host';

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: _mockNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNZIONI UI (Mockate)
  // ==========================================
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleLogout() {
    _showSuccessSnackBar("Simulazione: Disconnessione...");
  }

  void _handleAvatarTap() {
    _showSuccessSnackBar("Simulazione: Opzioni foto profilo");
  }

  void _handleInviteMember() {
    _showSuccessSnackBar("Simulazione: Apre popup codice invito");
  }

  void _handleLeaveHousehold() {
    _showSuccessSnackBar("Simulazione: Vuoi lasciare la casa?");
  }

  String _initialFromName(String name) {
    if (name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

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
              // SEZIONE 1: HEADER
              // ==========================================
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
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Color(0xFF5A8B9E)),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ==========================================
              // SEZIONE 2: INFO UTENTE (Avatar e Nome)
              // ==========================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _handleAvatarTap,
                    child: Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D342C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3D342C).withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child: Center(
                                child: Text(
                                  _initialFromName(_mockNickname),
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Iconina fotocamera in basso a destra
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF5A8B9E).withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Color(0xFF5A8B9E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Dati Testuali (Nome modificabile e Ruolo)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _editingNickname
                              ? null
                              : () {
                                  setState(() {
                                    _editingNickname = true;
                                  });
                                },
                          child: Row(
                            children: [
                              Expanded(
                                child: _editingNickname
                                    ? TextField(
                                        controller: _nicknameController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF3D342C),
                                          letterSpacing: -0.5,
                                        ),
                                      )
                                    : Text(
                                        _nicknameController.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF3D342C),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                              ),
                              if (_editingNickname)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingNickname = false;
                                    });
                                    _showSuccessSnackBar("Nickname salvato: ${_nicknameController.text}");
                                  },
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF5A8B9E),
                                  ),
                                )
                              else
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingNickname = true;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF5A8B9E),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _mockRole,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A8B9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 45, height: 45), // Bilanciamento visivo
                ],
              ),
              const SizedBox(height: 50),

              // ==========================================
              // SEZIONE 3: MENU PREMIUM
              // ==========================================
              _buildPremiumMenuButton(
                icon: Icons.fastfood_outlined,
                text: 'Your Diet',
                onTap: () {
                  _showSuccessSnackBar("Simulazione: Apre Diet Screen");
                },
              ),
              const SizedBox(height: 24),
              _buildPremiumMenuButton(
                icon: Icons.receipt_long_rounded,
                text: 'Your Home',
                onTap: () {
                  _showSuccessSnackBar("Simulazione: Apre Your Home Screen");
                },
              ),
              const SizedBox(height: 24),
              
              // ==========================================
              // SEZIONE 4: HOUSEHOLD SETTINGS (Admin/Co-Host)
              // ==========================================
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Household Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A8B9E).withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _handleInviteMember,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5A8B9E),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Invite Member',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  TextButton(
                    onPressed: _handleLeaveHousehold,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Leave household',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENTE: BOTTONI GRANDI PREMIUM
  // ==========================================
  Widget _buildPremiumMenuButton({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF4A261).withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF4A261).withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: const Color(0xFF5A8B9E), size: 28),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D342C),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF5A8B9E).withValues(alpha: 0.5),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}