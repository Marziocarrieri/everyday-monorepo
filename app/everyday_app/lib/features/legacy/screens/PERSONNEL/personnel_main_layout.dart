import 'package:flutter/material.dart';

// Importiamo le schermate del Personnel 
import 'personnel_utilities_screen.dart';
import 'personnel_home_screen.dart';
import 'personnel_profile_screen.dart';

class PersonnelMainLayout extends StatefulWidget {
  const PersonnelMainLayout({super.key});

  @override
  State<PersonnelMainLayout> createState() => _PersonnelMainLayoutState();
}

class _PersonnelMainLayoutState extends State<PersonnelMainLayout> {
  // Partiamo dalla Home (che è all'indice 1)
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          PersonnelUtilitiesScreen(), // 0: Utilities
          PersonnelHomeScreen(),      // 1: Home
          PersonnelProfileScreen(),   // 2: Profilo
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 65, 
      margin: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.kitchen, 0),
          _buildNavItem(Icons.home_filled, 1),
          _buildNavItem(Icons.person_outline, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Icon(
          icon, 
          size: 28, 
          color: isSelected 
              ? const Color(0xFFF4A261) 
              : const Color(0xFF5A8B9E).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}