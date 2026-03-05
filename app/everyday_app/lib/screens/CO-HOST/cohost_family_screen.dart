import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// ==========================================
// FUNZIONE COLORI SIMULATA (Mock di status_color_utils.dart)
// ==========================================
Color getStatusColor(String status) {
  if (status == 'safe') {
    return const Color(0xFF7CB9E8); // Azzurro brillante
  }
  return const Color(0xFF5A8B9E); // Azzurro scuro
}

// ==========================================
// MODELLI MOCKATI (Finti, solo per la UI)
// ==========================================
class MockFamilyMember {
  final String id;
  final String name;
  final String initial;

  MockFamilyMember({required this.id, required this.name, required this.initial});
}

// ==========================================
// SCHERMATA PRINCIPALE (FAMILY)
// ==========================================
class CohostFamilyScreen extends StatefulWidget {
  const CohostFamilyScreen({super.key});

  @override
  State<CohostFamilyScreen> createState() => _CohostFamilyScreenState();
}

class _CohostFamilyScreenState extends State<CohostFamilyScreen> {
  // Dati Finti per la lista della famiglia
  final List<MockFamilyMember> _members = [
    MockFamilyMember(id: '1', name: 'Enrico Cirillo', initial: 'E'),
    MockFamilyMember(id: '2', name: 'Leone Cirillo', initial: 'L'),
    MockFamilyMember(id: '3', name: 'Lara Vigorelli', initial: 'L'),
  ];

  void _simulateNavigateToPets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulazione: Naviga verso Pets Screen'), behavior: SnackBarBehavior.floating),
    );
  }

  void _simulateViewActivity(String memberName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulazione: Attività di $memberName'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usiamo l'azzurro scuro per l'header
    final themeColor = getStatusColor('darkfallback'); // #5A8B9E

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // --- HEADER PREMIUM PULITO (SENZA IL TASTO +) ---
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderIcon(Icons.pets, onTap: _simulateNavigateToPets, activeColor: themeColor),
                    Text(
                      'Family',
                      style: GoogleFonts.poppins(
                        fontSize: 24, 
                        fontWeight: FontWeight.w700, 
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // IL TASTO "+" È STATO RIMOSSO DA QUI
                    const SizedBox(width: 48), // Spacer vuoto per bilanciare l'icona Pets a sinistra
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // LISTA CARD PREMIUM (Dati Mockati)
              Expanded(
                child: _members.isEmpty
                    ? const Center(child: Text('No members found')) 
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: _buildPremiumFamilyCard(
                              id: member.id,
                              name: member.name,
                              initial: member.initial,
                              // Arancione per le card
                              color: const Color(0xFFF4A261), 
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap, Color? activeColor}) {
    final iconColor = activeColor ?? const Color(0xFF5A8B9E);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer( 
        duration: const Duration(milliseconds: 300),
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: iconColor.withValues(alpha: 0.1), width: 1),
          boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  // --- CARD FAMILY PREMIUM AGGIORNATA ---
  Widget _buildPremiumFamilyCard({required String id, required String name, required String initial, required Color color}) {
    // Usiamo l'azzurro scuro per il tasto "View Activity"
    final actionColor = getStatusColor('darkfallback'); // #5A8B9E

    return GestureDetector(
      onTap: () => _simulateViewActivity(name),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D342C), shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFF3D342C).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: Center(child: Text(initial, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1, margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.0)])),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('View\nActivity', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: actionColor, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}