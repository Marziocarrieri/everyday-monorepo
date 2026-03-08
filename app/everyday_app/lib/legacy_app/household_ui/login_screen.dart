// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:everyday_app/shared/services/auth_service.dart';
import 'package:everyday_app/features/household/data/household_service.dart';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final HouseholdFeatureService _householdService = HouseholdFeatureService();

  bool _isLoading = false;
  String? _error;

  Future<void> _routeAfterAuth() async {
    final households = await _householdService.getUserHouseholds();
    if (!mounted) return;

    if (households.isNotEmpty) {
      AppContext.instance.setHousehold(households.first.id);
    }

    final nextRoute = households.isEmpty
        ? AppRouteNames.welcome
        : AppRouteNames.mainLayout;

    Navigator.of(context).pushNamedAndRemoveUntil(
      nextRoute,
      (route) => false,
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

      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        AppContext.instance.setUser(currentUser.id);
      }

      await _routeAfterAuth();
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        AppContext.instance.setUser(currentUser.id);
      }

      await _routeAfterAuth();
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
      });
    }

    setState(() {
      _isLoading = false;
    });
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
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: const Text("Login"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: const Text("Register"),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}