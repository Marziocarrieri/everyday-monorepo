// TODO: legacy household flow – candidate for removal
import 'package:flutter/material.dart';
import 'package:everyday_app/shared/services/auth_service.dart';

import '../../../../core/app_route_names.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService().signOut();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouteNames.login2,
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

  void _openCreateHousehold() {
    Navigator.of(context).pushNamed(AppRouteNames.createHousehold);
  }

  void _openJoinHousehold() {
    Navigator.of(context).pushNamed(AppRouteNames.joinHousehold);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _openCreateHousehold,
                child: const Text('Create household'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _openJoinHousehold,
                child: const Text('Join household'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
