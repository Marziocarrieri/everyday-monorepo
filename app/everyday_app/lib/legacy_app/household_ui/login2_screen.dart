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

  bool _isLoading = false;
  String? _error;

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
      AppRouteNames.mainLayout,
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await _routeAfterAuth();
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

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFF5A8B9E), size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text('Everyday App', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E), letterSpacing: -0.5)),
                  Text('Login to continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.6))),
                  const SizedBox(height: 50),

                  // CAMPI DI TESTO IN VETRO
                  _buildGlassTextField(label: 'Name', controller: _nameController, icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildGlassTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildGlassTextField(label: 'Password', controller: _passwordController, icon: Icons.lock_outline, isPassword: true),
                  
                  const SizedBox(height: 50),

                  // BOTTONI
                  _buildPrimaryButton('Login', () {
                    _login();
                  }),
                  const SizedBox(height: 16),
                  _buildSecondaryButton('Register', () {
                    _register();
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
          child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))),
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
                boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF5A8B9E).withValues(alpha: 0.7), size: 22),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      obscureText: isPassword,
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

  // --- BOTTONE PRINCIPALE (Azzurro Premium) ---
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

  // --- BOTTONE SECONDARIO (Vetro trasparente) ---
  Widget _buildSecondaryButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 60, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(text, style: GoogleFonts.poppins(color: const Color(0xFF5A8B9E), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}