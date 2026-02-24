import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Partiamo dalla Home

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFFF5F1E9), 
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildDailyTaskCard(),
            ],
          ),
        ),
      ),

      floatingActionButton: _buildAIButton(),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- 1. HEADER (Calendario, Titolo, Notifiche) ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconBtn(Icons.calendar_today_outlined),
        Text(
          'Home',
          // USIAMO GOOGLE FONTS QUI!
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5A8B9E),
          ),
        ),
        _buildIconBtn(Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFFF3D2B3), 
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF5A8B9E)),
    );
  }

  // --- 2. CARD DAILY TASK ---
  Widget _buildDailyTaskCard() {
    return Container(
      height: 140, // Altezza fissa per dare respiro
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Aggiungiamo una leggerissima ombra arancione sotto la card
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A261).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // PARTE SINISTRA: Arancione scuro
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFFF4A261),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 35, height: 35,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3D342C), 
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'A', 
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Daily Task',
                          style: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 47), // Allineiamo la data sotto il testo
                      child: Text(
                        '24/02/2026',
                        style: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // PARTE DESTRA: Arancione chiaro con il progresso
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFFFFDAB9),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 75, height: 75,
                      child: CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round, // Rende le punte arrotondate!
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4A261)),
                      ),
                    ),
                    Text(
                      '75 %',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: const Color(0xFFF4A261), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. BOTTONE INTELLIGENZA ARTIFICIALE ---
  Widget _buildAIButton() {
    return FloatingActionButton(
      onPressed: () => debugPrint("AI Clicked"),
      backgroundColor: const Color(0xFFF3D2B3),
      elevation: 0,
      shape: const CircleBorder(),
      child: const Icon(Icons.lightbulb_outline, color: Color(0xFF5A8B9E)),
    );
  }

  // --- 4. BARRA DI NAVIGAZIONE IN BASSO ---
  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(left: 50, right: 50, bottom: 30), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF4A261),
          unselectedItemColor: const Color(0xFF5A8B9E).withValues(alpha: 0.5),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          currentIndex: _selectedIndex, 
          onTap: _onItemTapped, 
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Dispensa'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Membri'),
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profilo'),
          ],
        ),
      ),
    );
  }
}