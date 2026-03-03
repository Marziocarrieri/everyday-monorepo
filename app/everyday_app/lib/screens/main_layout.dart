import 'package:flutter/material.dart';
import '../core/app_context.dart';

// Assicurati che i nomi di questi file corrispondano esattamente ai tuoi!
import 'utilities_screen.dart';
import 'personnel_screen.dart';
import 'home_screen.dart';
import 'family_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Partiamo dalla Home (indice 2)
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppContext.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          // L'IndexedStack tiene in memoria le pagine senza ricaricarle
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              UtilitiesScreen(), // 0: Dispensa
              PersonnelScreen(), // 1: Personale
              HomeScreen(), // 2: Home
              FamilyScreen(), // 3: Famiglia
              ProfileScreen(), // 4: Profilo
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context),
        );
      },
    );
  }

  // --- BARRA DI NAVIGAZIONE PREMIUM MINIMALE ---
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 65, 
      margin: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2), // Riflesso vetro
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
          _buildNavItem(Icons.face_retouching_natural, 1), 
          _buildNavItem(Icons.home_filled, 2), 
          _buildNavItem(Icons.public, 3), 
          _buildNavItem(
            Icons.person_outline, 
            4,
            onLongPress: () => showProfileHouseholdBottomSheet(context),
          ),
        ],
      ),
    );
  }

  // Abbiamo aggiunto la possibilità di passare la funzione onLongPress!
  Widget _buildNavItem(IconData icon, int index, {VoidCallback? onLongPress}) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      onLongPress: onLongPress, // Agganciato!
      child: Container(
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon, 
          size: 28, 
          // Selezionato = Arancione vivo. Non selezionato = Azzurro spento
          color: isSelected 
              ? const Color(0xFFF4A261) 
              : const Color(0xFF5A8B9E).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}