import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; 

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sfondo Grigio Perla per far risaltare il vetro puro
      backgroundColor: const Color(0xFFF6F8FA), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: _buildHeader(),
              ),
              const SizedBox(height: 40),
              _buildDailyTaskCard(), 
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAIButton(), 
    );
  }

  // --- HEADER ULTRA-PREMIUM ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconBtn(Icons.calendar_today_outlined),
        Text(
          'Home', 
          style: GoogleFonts.poppins(
            fontSize: 24, 
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF1E293B), // Blu Notte elegante
            letterSpacing: 0.5,
          )
        ),
        _buildIconBtn(Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        // Bordo quasi invisibile, fa tutto l'ombra morbida
        border: Border.all(color: Colors.white, width: 2), 
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05), // Ombra fredda leggerissima
            blurRadius: 15, 
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Icon(icon, color: const Color(0xFF1E293B), size: 22), // Icona scura e netta
    );
  }

  // --- CARD: CRISTALLO PURO FLUTTUANTE ---
  Widget _buildDailyTaskCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0), // Sfocatura estrema
        child: Container(
          height: 160, // Leggermente più alta per proporzioni auree
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.8), // Più bianco in alto a sinistra (luce)
                Colors.white.withValues(alpha: 0.2)  // Più trasparente in basso a destra
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 1.5), // Bordo "taglio diamante"
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.06), // Ombra enorme e diffusa
                blurRadius: 40, 
                offset: const Offset(0, 20)
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PARTE SINISTRA
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              // Un gradiente sottile per l'avatar
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2F3E46), Color(0xFF1E293B)]
                              ), 
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.3), 
                                  blurRadius: 12, offset: const Offset(0, 6)
                                )
                              ]
                            ),
                            child: Center(child: Text('A', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Daily Task', 
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1E293B), 
                              fontSize: 19, 
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Text(
                          '24/02/2026', 
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B), // Grigio ardesia elegante
                            fontSize: 14, 
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // DIVISORE SFUMATO BIANCO PURO
              Container(
                width: 1, 
                margin: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0), 
                      Colors.white.withValues(alpha: 0.8), 
                      Colors.white.withValues(alpha: 0.0)
                    ]
                  )
                ),
              ),
              
              // PARTE DESTRA (Anello di caricamento Corallo)
              Expanded(
                flex: 2,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 85, height: 85,
                        child: CircularProgressIndicator(
                          value: 0.75, 
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)), // Corallo vibrante
                        ),
                      ),
                      Text(
                        '75%', 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFFFF6B6B), 
                          fontSize: 18
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TASTO AI: BOTTONE GIOIELLO ---
  Widget _buildAIButton() {
    return Container(
      width: 64, height: 64, 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8E8B), // Pesca chiaro
            Color(0xFFFF6B6B)  // Corallo intenso
          ],
        ),
        shape: BoxShape.circle,
        // Riflesso di luce in alto a sinistra per farlo sembrare un pulsante solido e lucido
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.4), // Ombra colorata che lo fa "brillare"
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 28), // Icona stellina magica
        onPressed: () => debugPrint("AI Clicked"),
      ),
    );
  }
}