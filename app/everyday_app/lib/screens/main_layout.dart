import 'package:flutter/material.dart';

// Importiamo le nostre 5 bellissime schermate!
import 'utilities_screen.dart';
import 'personnel_screen.dart';
import 'home_screen2.dart';
import 'family_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Partiamo dalla Home, che è l'icona centrale (indice 2)
  int _selectedIndex = 2;

  // Questa è la "cartucciera" con le nostre 5 pagine nell'ordine esatto della barra
  final List<Widget> _screens = [
    const UtilitiesScreen(), // 0: Frigo
    const PersonnelScreen(), // 1: Faccina
    const HomeScreen2(),      // 2: Home
    const FamilyScreen(),    // 3: Globo
    const ProfileScreen(),   // 4: Omino
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // IndexedStack mostra solo la schermata corrispondente a _selectedIndex
      // ma tiene le altre "congelate" in memoria per non doverle ricaricare ogni volta!
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // Mettiamo la barra qui, UNA SOLA VOLTA per tutta l'app!
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- LA NOSTRA BARRA CUSTOM ---
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 65, 
      margin: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.kitchen, 0), 
          _buildNavItem(Icons.face_retouching_natural, 1), 
          _buildNavItem(Icons.home_filled, 2), 
          _buildNavItem(Icons.public, 3), 
          _buildNavItem(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        // Rimuoviamo il cerchio pesca e lasciamo lo sfondo trasparente
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Icon(
          icon, 
          size: 28, 
          // Icona Arancione se selezionata, Blu semi-trasparente se non lo è
          color: isSelected 
              ? const Color(0xFFF4A261) 
              : const Color(0xFF5A8B9E).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}