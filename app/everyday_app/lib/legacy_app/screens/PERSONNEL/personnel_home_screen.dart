import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; 
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'personnel_daily_task_screen.dart';

class PersonnelHomeScreen extends StatefulWidget {
  const PersonnelHomeScreen({super.key});

  @override
  State<PersonnelHomeScreen> createState() => _PersonnelHomeScreenState();
}

class _PersonnelHomeScreenState extends State<PersonnelHomeScreen> {
  DateTime _selectedDate = DateTime.now();

  // ==========================================
  // BUILD PRINCIPALE DELLO SCHERMO
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header fisso in alto
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0),
              child: SizedBox(
                height: 48,
                child: _buildHeader(),
              ),
            ),
            const SizedBox(height: 30),
            
            // Corpo scrollabile
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                children: [
                  _buildDailyTaskCard(), 
                  const SizedBox(height: 40), // Spazio extra in fondo per respirare
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildAIButton(), 
    );
  }

  // ==========================================
  // SEZIONE 1: HEADER
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showCalendarPopup(context),
          child: _buildIconBtn(Icons.calendar_today_outlined),
        ),
        Text(
          'Home', 
          style: GoogleFonts.poppins(
            fontSize: 24, 
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF5A8B9E),
            letterSpacing: 0.5,
          )
        ),
        GestureDetector(
          onTap: () {},
          child: _buildIconBtn(Icons.notifications_none_rounded),
        ),
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

  // ==========================================
  // SEZIONE 2: CARD DAILY TASK
  // ==========================================
  Widget _buildDailyTaskCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonnelDailyTaskScreen(date: _selectedDate),
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
                              child: Center(child: Text('P', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
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
                            _selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month 
                                ? 'Oggi' 
                                : DateFormat('dd MMM').format(_selectedDate),
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
                            value: 0.50,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4A261)),
                          ),
                        ),
                        Text(
                          '50%', 
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

  // ==========================================
  // SEZIONE 3: TASTO FLOATING (AI Assistant)
  // ==========================================
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
            onPressed: () {},
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SEZIONE 4: POPUP DEL CALENDARIO
  // ==========================================
  void _showCalendarPopup(BuildContext context) {
    DateTime focusedDay = _selectedDate; 
    DateTime? selectedDay = _selectedDate;

    final Color colorAzzurro = const Color(0xFF5A8B9E); 
    final Color colorOrange = const Color(0xFFF4A261); 

    showDialog(
      context: context,
      barrierColor: colorAzzurro.withValues(alpha: 0.15), 
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), 
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85), 
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colorAzzurro.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 15)
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                        
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: _buildCalNavBtn(Icons.chevron_left_rounded, colorAzzurro),
                          rightChevronIcon: _buildCalNavBtn(Icons.chevron_right_rounded, colorAzzurro),
                          titleTextStyle: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.w800, 
                            color: const Color(0xFF3D342C)
                          ),
                        ),
                        
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: GoogleFonts.poppins(color: colorOrange, fontSize: 13, fontWeight: FontWeight.w700),
                          weekendStyle: GoogleFonts.poppins(color: colorOrange, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontWeight: FontWeight.w600),
                          weekendTextStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontWeight: FontWeight.w600),
                          todayDecoration: BoxDecoration(
                            border: Border.all(color: colorAzzurro.withValues(alpha: 0.5), width: 2),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: GoogleFonts.poppins(color: colorAzzurro, fontWeight: FontWeight.w800),
                          selectedDecoration: BoxDecoration(
                            color: colorAzzurro,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: colorAzzurro.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),
                          markerDecoration: BoxDecoration(color: colorOrange, shape: BoxShape.circle),
                          markersMaxCount: 1,
                        ),
                        
                        onDaySelected: (selected, focused) {
                          setDialogState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (context.mounted) {
                              Navigator.pop(context); // Chiude il popup
                              
                              setState(() {
                                _selectedDate = selected; // Cambia la data sulla Card
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PersonnelDailyTaskScreen(date: selected),
                                ),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalNavBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}