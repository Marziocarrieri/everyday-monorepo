// TODO migrate to features/household
import 'dart:typed_data';
import 'dart:ui'; // Aggiunto per il BackdropFilter

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/household/services/household_onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart'; // Aggiunto per i font

class HouseholdOnboardingScreen extends StatefulWidget {
  const HouseholdOnboardingScreen({super.key});

  @override
  State<HouseholdOnboardingScreen> createState() =>
      _HouseholdOnboardingScreenState();
}

class _HouseholdOnboardingScreenState extends State<HouseholdOnboardingScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final HouseholdOnboardingService _onboardingService =
      HouseholdOnboardingService();

  bool _isSaving = false;
  Uint8List? _selectedAvatarBytes;

  // Colori Brand
  final Color primaryColor = const Color(0xFF5A8B9E);
  final Color darkTextColor = const Color(0xFF3D342C);
  final Color errorColor = const Color(0xFFF28482);

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedAvatarBytes = bytes;
    });
  }

  Future<String?> _uploadAvatarIfNeeded() async {
    return _onboardingService.uploadAvatarIfNeeded(
      bytes: _selectedAvatarBytes,
      householdId: AppContext.instance.householdId,
      membershipId: AppContext.instance.membershipId,
    );
  }

  Future<void> _continue() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) {
      if (!mounted) return;
      // FIX DEL BUG: Puntiamo alla nuova rotta RoleShell, non più al MainLayout obsoleto
      Navigator.of(context).pushReplacementNamed(AppRouteNames.roleShell);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final nickname = _nicknameController.text.trim();
      final avatarUrl = await _uploadAvatarIfNeeded();
      await _onboardingService.saveMemberProfile(
        membershipId: membershipId,
        nickname: nickname,
        avatarUrl: avatarUrl,
      );

      await AppContext.instance.reloadMemberContext();

      if (!mounted) return;
      // FIX DEL BUG: Puntiamo alla nuova rotta RoleShell
      Navigator.of(context).pushReplacementNamed(AppRouteNames.roleShell);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _skip() {
    // FIX DEL BUG: Puntiamo alla nuova rotta RoleShell
    Navigator.of(context).pushReplacementNamed(AppRouteNames.roleShell);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sfondo con gradiente Premium
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  'Set up your profile',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personalize your identity in this home.\nYou can always change it later.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: darkTextColor.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 40),

                // AVATAR PICKER IN VETRO
                Center(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickAvatar,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow dietro l'avatar
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                        // Avatar Container
                        ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.6),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                image: _selectedAvatarBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_selectedAvatarBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _selectedAvatarBytes == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_rounded,
                                          color: primaryColor.withValues(alpha: 0.8),
                                          size: 36,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Upload',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        // Badge Modifica (visibile se c'è un'immagine)
                        if (_selectedAvatarBytes != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // TEXT FIELD PREMIUM
                Text(
                  'What should we call you?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: darkTextColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: TextField(
                      controller: _nicknameController,
                      enabled: !_isSaving,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Mom, Dad, Alex...',
                        hintStyle: GoogleFonts.poppins(
                          color: darkTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),

                // BOTTONE CONTINUA
                GestureDetector(
                  onTap: _isSaving ? null : _continue,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save & Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // BOTTONE SKIP
                Center(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _skip,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}