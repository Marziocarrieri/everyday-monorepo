import 'package:flutter/material.dart';
import 'package:everyday_app/features/home/presentation/screens/home_screen.dart';
import 'package:everyday_app/legacy_app/screens/profile_screen.dart';
import 'package:everyday_app/legacy_app/screens/utilities_screen.dart';

class CohostMainLayout extends StatefulWidget {
  const CohostMainLayout({super.key});

  @override
  State<CohostMainLayout> createState() => _CohostMainLayoutState();
}

class _CohostMainLayoutState extends State<CohostMainLayout> {
  // Partiamo dalla Home (che ora è all'indice 1)
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ==========================================
  // BUILD PRINCIPALE
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // L'IndexedStack tiene in memoria le 3 pagine senza ricaricarle
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          UtilitiesScreen(), // 0: Utilities
          HomeScreen(), // 1: Home
          ProfileScreen(), // 2: Profilo
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ==========================================
  // BARRA DI NAVIGAZIONE PREMIUM MINIMALE
  // ==========================================
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
          _buildNavItem(Icons.kitchen, 0), // Utilities
          _buildNavItem(Icons.home_filled, 1), // Home
          _buildNavItem(
            Icons.person_outline, 
            2, // Profilo
            onLongPress: () {
              // Simulazione del BottomSheet del profilo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Simulazione: Cambio Household")),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENTE: SINGOLO TASTO DELLA BARRA
  // ==========================================
  Widget _buildNavItem(IconData icon, int index, {VoidCallback? onLongPress}) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      onLongPress: onLongPress, 
      child: Container(
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Padding aumentato per hit-box migliore
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