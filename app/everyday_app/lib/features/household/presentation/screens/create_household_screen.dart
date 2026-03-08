import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/features/household/data/household_service.dart';
import 'package:everyday_app/shared/services/session_initializer.dart';
import 'package:everyday_app/core/app_context.dart';

class CreateHouseholdScreen extends StatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  State<CreateHouseholdScreen> createState() => _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends State<CreateHouseholdScreen> {
  final TextEditingController _nameController = TextEditingController();
  final HouseholdFeatureService _householdService = HouseholdFeatureService();
  final SessionInitializer _sessionInitializer = SessionInitializer();

  bool _isLoading = false;
  String? _error;

  Future<void> _createHousehold() async {
    final householdName = _nameController.text.trim();
    if (householdName.isEmpty) {
      setState(() {
        _error = 'Household name is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final household = await _householdService.createHousehold(
        name: householdName,
      );
      AppContext.instance.setActiveHousehold(household.id);
      final state = await _sessionInitializer.initialize();

      if (!mounted) return;
      if (state != BootstrapState.ready) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouteNames.welcome,
          (route) => false,
        );
        return;
      }

      AppRouter.replace<void, void>(
        context,
        AppRouteNames.householdOnboarding,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F9FA), Color(0xFFE3EDF2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER CON TASTO BACK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: _buildHeader(context),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // ICONA FLUTTUANTE
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0xFFF4A261).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: const Icon(Icons.add_home_outlined, color: Color(0xFFF4A261), size: 40), // Arancione caldo
                      ),
                      const SizedBox(height: 40),
                      
                      // CAMPO DI TESTO IN VETRO
                      _buildGlassTextField(label: 'Household name', controller: _nameController, icon: Icons.home_outlined),
                      
                      const SizedBox(height: 50),

                      // BOTTONE CONFERMA
                      _buildPrimaryButton('Create', () {
                        _createHousehold();
                      }),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
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
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A8B9E), size: 20),
          ),
        ),
        const SizedBox(width: 20),
        Text('Create household', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF5A8B9E))),
      ],
    );
  }

  // --- CAMPO DI TESTO IN VETRO ---
  Widget _buildGlassTextField({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              height: 60, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2), 
                boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF5A8B9E).withValues(alpha: 0.7), size: 22),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(border: InputBorder.none),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
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

  // --- BOTTONE ---
  Widget _buildPrimaryButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 60, width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5A8B9E), Color(0xFF3A5F6E)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
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
              : Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}