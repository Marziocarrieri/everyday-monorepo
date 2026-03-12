import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/core/runtime/household_runtime_controller.dart';
import 'package:everyday_app/features/household/data/models/household.dart';
import 'package:everyday_app/features/household/domain/services/household_service.dart';
import 'package:everyday_app/shared/services/auth_service.dart';
import 'package:everyday_app/features/household/presentation/providers/household_providers.dart';
import 'package:everyday_app/shared/services/session_initializer.dart';

class JoinHouseholdScreen extends ConsumerStatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final TextEditingController _codeController = TextEditingController();
  final SessionInitializer _sessionInitializer = SessionInitializer();

  bool _isLoading = false;
  String? _selectedRole = 'PERSONNEL'; // Valore di default

  // Colori Brand
  final Color primaryColor = const Color(0xFF5A8B9E);
  final Color errorColor = const Color(0xFFF28482);
  final Color darkTextColor = const Color(0xFF3D342C);

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: errorColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _joinHousehold(HouseholdService householdService) async {
    final inviteCode = _codeController.text.trim();
    if (inviteCode.isEmpty) {
      _showErrorSnackBar('Please enter an invite code.');
      return;
    }

    final selectedRole = _selectedRole;
    if (selectedRole == null || selectedRole.trim().isEmpty) {
      _showErrorSnackBar('Please select a role.');
      return;
    }

    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('User not authenticated.');
      return;
    }

    debugPrint("JOIN UI EMAIL: ${currentUser.email}");

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("JOIN UI SELECTED ROLE: $selectedRole");

      final joinResult = await householdService.joinHouseholdByInviteCode(
        inviteCode: inviteCode,
        selectedRole: selectedRole,
      );

      final households = await householdService.getMyHouseholds();
      Household? joinedHousehold;
      for (final household in households) {
        if (household.id == joinResult.householdId) {
          joinedHousehold = household;
          break;
        }
      }

      if (joinedHousehold == null) {
        throw Exception('Joined household not found in your household list');
      }

      AppContext.instance.household = joinedHousehold;
      AppContext.instance.setMembership(joinResult.membershipId);
      await ref
          .read(householdRuntimeControllerProvider)
          .switchHousehold(ref, joinResult.householdId);

      final state = await _sessionInitializer.initialize();

      if (!mounted) return;
      if (state != BootstrapState.ready) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRouteNames.welcome, (route) => false);
        return;
      }

      AppRouter.replace<void, void>(context, AppRouteNames.householdOnboarding);
    } catch (error) {
      debugPrint('Error joining household: $error');
      if (!mounted) return;
      _showErrorSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final householdService = ref.watch(householdServiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F9FA), Color(0xFFE3EDF2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER CON TASTO BACK
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: _buildHeader(context),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // ICONA FLUTTUANTE
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.vpn_key_outlined,
                          color: primaryColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // CAMPO DI TESTO IN VETRO
                      _buildGlassTextField(
                        label: 'Enter Invite Code',
                        controller: _codeController,
                        icon: Icons.qr_code_2_rounded,
                      ),

                      const SizedBox(height: 32),

                      // SELETTORE RUOLO (Nuovo Design a Pillole)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your Role in this Home',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildRolePill('HOST', 'Host', Icons.admin_panel_settings_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRolePill('CO_HOST', 'Co-Host', Icons.supervised_user_circle_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRolePill('PERSONNEL', 'Personnel', Icons.work_outline_rounded),
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // BOTTONE CONFERMA
                      _buildPrimaryButton('Join Household', () {
                        _joinHousehold(householdService);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          'Join Household',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800, // Reso più spesso per coerenza
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  // --- CAMPO DI TESTO IN VETRO ---
  Widget _buildGlassTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkTextColor.withValues(alpha: 0.8),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: primaryColor.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. A1B2C3D4',
                        hintStyle: GoogleFonts.poppins(
                          color: darkTextColor.withValues(alpha: 0.3),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkTextColor,
                        letterSpacing: 1.5, // Leggermente distanziato per il codice
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- ROLE PILL (Sostituisce i vecchi RadioButton) ---
  Widget _buildRolePill(String roleValue, String label, IconData icon) {
    bool isSelected = _selectedRole == roleValue;
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              setState(() {
                _selectedRole = roleValue;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : primaryColor.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : darkTextColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTONE PRIMARY ---
  Widget _buildPrimaryButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, const Color(0xFF3A5F6E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}