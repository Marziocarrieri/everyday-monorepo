import 'package:flutter/material.dart';
import '../models/household.dart';
import '../services/household_service.dart';

class HouseholdListScreen extends StatefulWidget {
  const HouseholdListScreen({super.key});

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends State<HouseholdListScreen> {
  final HouseholdService _householdService = HouseholdService();

  bool _isLoading = true;
  List<Household> _households = [];

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final households = await _householdService.getMyHouseholds();
      if (!mounted) return;

      setState(() {
        _households = households;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onCreateHouseholdPressed() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create household'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Household name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.isEmpty) {
      return;
    }

    try {
      await _householdService.createHousehold(name);
      await _loadHouseholds();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Households")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_households.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Households")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("No household found"),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _onCreateHouseholdPressed,
                child: const Text('Create household'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Households")),
      body: RefreshIndicator(
        onRefresh: _loadHouseholds,
        child: ListView.builder(
          itemCount: _households.length,
          itemBuilder: (context, index) {
            final household = _households[index];
            return ListTile(
              title: Text(household.name),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateHouseholdPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}