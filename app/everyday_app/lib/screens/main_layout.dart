import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Aggiunto per i font
import 'dart:ui'; // Aggiunto per l'effetto vetro

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

  // La lista delle nostre 5 schermate
  final List<Widget> _screens = [
    const UtilitiesScreen(), // 0: Dispensa
    const PersonnelScreen(), // 1: Personale
    const HomeScreen(),      // 2: Home
    const FamilyScreen(),    // 3: Famiglia
    const ProfileScreen(),   // 4: Profilo
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
      // L'IndexedStack tiene in memoria le pagine senza ricaricarle
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
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
            onLongPress: () => _showProfileBottomSheet(context), // <--- LA MAGIA!
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

  // ==========================================
  // MODAL: MENU PROFILO (Azzurro Premium & Marrone Scuro)
  // ==========================================
  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                // Sfondo grigio-azzurro morbido
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF8E9B9E).withValues(alpha: 0.85), 
                    const Color(0xFF7A898D).withValues(alpha: 0.95), 
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trattino per lo swipe in alto
                  Container(
                    width: 40, height: 4, 
                    decoration: BoxDecoration(color: const Color(0xFF5A8B9E).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10))
                  ),
                  const SizedBox(height: 25),
                  
                  // Titolo Centrato nel nostro Azzurro Originale
                  Text('Your Households', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E))),
                  const SizedBox(height: 30),

                  // CARDS DELLE CASE
                  _buildHouseholdOption(context, 'Main Home', true),
                  const SizedBox(height: 8), 
                  _buildHouseholdOption(context, 'Beach House', false),
                  
                  const SizedBox(height: 25),

                  // Divisorio leggerissimo in vetro
                  Container(
                    height: 1, 
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.0)]))
                  ),
                  const SizedBox(height: 25),

                  // TASTO LOGOUT (Pillola color Corallo)
                  GestureDetector(
                    onTap: () {
                      debugPrint("Logout premuto!");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE76F51).withValues(alpha: 0.15), 
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: Color(0xFFE76F51), size: 22),
                          const SizedBox(width: 12),
                          Text('Logout', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFE76F51))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // --- SINGOLA OPZIONE CASA (Icone Azzurre, Testi Marroni) ---
  Widget _buildHouseholdOption(BuildContext context, String name, bool isActive) {
    return GestureDetector(
      onTap: () {
        debugPrint("Cambiato alla casa: $name");
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.4) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive ? Border.all(color: Colors.white, width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Cerchietto con l'icona della casa nell'Azzurro Originale
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF5A8B9E).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_rounded, 
                    color: isActive ? const Color(0xFF5A8B9E) : const Color(0xFF3D342C).withValues(alpha: 0.4), 
                    size: 22
                  ),
                ),
                const SizedBox(width: 15),
                // Nome della casa in Marrone Scuro (#3D342C)
                Text(
                  name, 
                  style: GoogleFonts.poppins(
                    fontSize: 17, 
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, 
                    color: isActive ? const Color(0xFF3D342C) : const Color(0xFF3D342C).withValues(alpha: 0.6)
                  )
                ),
              ],
            ),
            // Spunta nell'Azzurro Originale
            if (isActive)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF5A8B9E), size: 26),
          ],
        ),
      ),
    );
  }
}