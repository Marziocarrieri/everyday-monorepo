// TODO: legacy household flow – candidate for removal
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_context.dart';
import '../../../../screens/login_screen.dart';

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
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
