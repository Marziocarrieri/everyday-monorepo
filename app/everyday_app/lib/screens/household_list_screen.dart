import 'package:flutter/material.dart';

class HouseholdListScreen extends StatelessWidget {
  const HouseholdListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Households")),
      body: const Center(
        child: Text("Logged in successfully"),
      ),
    );
  }
}