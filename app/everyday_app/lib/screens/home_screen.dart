import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; 
import '../core/app_context.dart';
import 'daily_task_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();

    debugPrint("USER: ${AppContext.instance.userId}");
    debugPrint("HOUSEHOLD: ${AppContext.instance.householdId}");
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

  // --- HEADER PREMIUM ---
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
            color: const Color(0xFF5A8B9E),
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
        border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), 
            blurRadius: 20, 
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5A8B9E), size: 22),
    );
  }

  // --- CARD PREMIUM ---
  // --- CARD PREMIUM ---
  Widget _buildDailyTaskCard() {
    return GestureDetector(
      // --- ECCO IL COLLEGAMENTO MAGICO ---
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DailyTaskScreen(),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF4A261).withValues(alpha: 0.2), 
                  Colors.white.withValues(alpha: 0.5)
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF4A261).withValues(alpha: 0.08), 
                  blurRadius: 30, 
                  offset: const Offset(0, 15)
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D342C), 
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3D342C).withValues(alpha: 0.2), 
                                    blurRadius: 10, offset: const Offset(0, 4)
                                  )
                                ]
                              ),
                              child: Center(child: Text('A', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Daily Task', 
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3D342C), 
                                fontSize: 19, 
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 54),
                          child: Text(
                            '24/02/2026', 
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF3D342C).withValues(alpha: 0.6), 
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
                Container(
                  width: 1, 
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.0), 
                        Colors.white.withValues(alpha: 0.6), 
                        Colors.white.withValues(alpha: 0.0)
                      ]
                    )
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80, height: 80,
                          child: CircularProgressIndicator(
                            value: 0.75, 
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4A261)),
                          ),
                        ),
                        Text(
                          '75%', 
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, 
                            color: const Color(0xFFF4A261), 
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
      ),
    );
  }
  // --- TASTO AI PREMIUM ---
  Widget _buildAIButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 60, height: 60, 
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF4A261).withValues(alpha: 0.3), 
                Colors.white.withValues(alpha: 0.4)
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A261).withValues(alpha: 0.15), 
                blurRadius: 20, 
                offset: const Offset(0, 10)
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Color(0xFF5A8B9E), size: 26),
            onPressed: () => debugPrint("AI Clicked"),
          ),
        ),
      ),
    );
  }
}