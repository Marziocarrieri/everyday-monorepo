// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/shared/services/auth_service.dart';
import 'package:everyday_app/shared/services/session_initializer.dart';

class Login2Screen extends StatefulWidget {
  const Login2Screen({super.key});

  @override
  State<Login2Screen> createState() => _Login2ScreenState();
}

class _Login2ScreenState extends State<Login2Screen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SessionInitializer _sessionInitializer = SessionInitializer();

  // STATI SEPARATI PER EVITARE CHE GIRINO ENTRAMBE LE ROTELLINE
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;

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

  Future<void> _routeAfterAuth() async {
    final state = await _sessionInitializer.initialize();
    if (!mounted) return;

    if (state != BootstrapState.ready) {
      AppRouter.navigateAndRemoveUntil<void>(
        context,
        AppRouteNames.welcome,
      );
      return;
    }

    AppRouter.navigateAndRemoveUntil<void>(
      context,
      AppRouteNames.roleShell,
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoginLoading = true;
    });

    try {
      await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await _routeAfterAuth();
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(error.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoginLoading = false;
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _isRegisterLoading = true;
    });

    try {
      final enteredName = _nameController.text.trim();
      if (enteredName.isEmpty) {
        throw Exception('Name is required for registration');
      }

      await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text,
        enteredName,
      );

      await _sessionInitializer.ensureProfileForCurrentUser(
        name: enteredName,
        email: _emailController.text.trim(),
      );

      await _routeAfterAuth();
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(error.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _isRegisterLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnyLoading = _isLoginLoading || _isRegisterLoading;

    return Scaffold(
      // Sfondo leggermente sfumato per far risaltare il VETRO
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F9FA), Color(0xFFE3EDF2)], // Bianco perla -> Azzurrino chiarissimo
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO / TITOLO
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Icon(Icons.home_rounded, color: primaryColor, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text('Everyday App', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: -0.5)),
                  Text('Login to continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: darkTextColor.withValues(alpha: 0.6))),
                  const SizedBox(height: 50),

                  // CAMPI DI TESTO IN VETRO
                  _buildGlassTextField(label: 'Name', controller: _nameController, icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildGlassTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildGlassTextField(label: 'Password', controller: _passwordController, icon: Icons.lock_outline, isPassword: true),
                  
                  const SizedBox(height: 50),

                  // BOTTONI
                  _buildPrimaryButton(
                    text: 'Login', 
                    isLoading: _isLoginLoading, 
                    isDisabled: isAnyLoading, 
                    onTap: _login
                  ),
                  const SizedBox(height: 16),
                  _buildSecondaryButton(
                    text: 'Register', 
                    isLoading: _isRegisterLoading, 
                    isDisabled: isAnyLoading, 
                    onTap: _register
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- INPUT IN VETRO PREMIUM ---
  Widget _buildGlassTextField({required String label, required TextEditingController controller, required IconData icon, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextColor)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              height: 60, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7), // Vetro super trasparente
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2), // Bordo bianco lucido
                boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Icon(icon, color: primaryColor.withValues(alpha: 0.7), size: 22),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      obscureText: isPassword,
                      decoration: const InputDecoration(border: InputBorder.none),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor),
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

  // --- BOTTONE PRINCIPALE (Azzurro Premium) ---
  Widget _buildPrimaryButton({required String text, required bool isLoading, required bool isDisabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 60, width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5A8B9E), Color(0xFF3A5F6E)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: isLoading
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

  // --- BOTTONE SECONDARIO (Vetro trasparente) ---
  Widget _buildSecondaryButton({required String text, required bool isLoading, required bool isDisabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 60, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: primaryColor,
                  ),
                )
              : Text(text, style: GoogleFonts.poppins(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}