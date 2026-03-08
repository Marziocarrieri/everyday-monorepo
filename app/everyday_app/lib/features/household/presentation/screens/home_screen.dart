// TODO: legacy household flow – candidate for removal
import 'package:flutter/material.dart';
import 'package:everyday_app/shared/services/auth_service.dart';

import '../../../../core/app_context.dart';
import '../../../../core/app_route_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final householdId = AppContext.instance.householdId;
    if (householdId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Household context not ready'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Home placeholder'),
      ),
    );
  }
}
