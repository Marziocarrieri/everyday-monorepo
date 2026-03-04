import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'add_task_screen.dart'; // Importiamo la pagina di aggiunta task!

class MemberActivitiesScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final Color themeColor;
  final bool isPersonnel;

  const MemberActivitiesScreen({
    super.key, 
    required this.memberId, 
    required this.memberName, 
    required this.themeColor,
    this.isPersonnel = false,
  });

  @override
  State<MemberActivitiesScreen> createState() => _MemberActivitiesScreenState();
}

class _MemberActivitiesScreenState extends State<MemberActivitiesScreen> {
  // Dati Mockati (In futuro arriveranno dal DB per questo specifico utente)
  final List<Map<String, dynamic>> _activitiesByDate = [
    {
      'date': 'Monday 27/11',
      'tasks': [
        {'title': 'Homework oversight', 'time': '7:45AM - 8:45AM', 'isCompleted': true},
        {'title': 'Skin-care Routine', 'time': '8:00PM - 8:30PM', 'isCompleted': false},
      ]
    },
    {
      'date': 'Tuesday 28/11',
      'tasks': [
        {'title': 'Seasonal Closet Swap', 'time': '10:00AM - 12:00PM', 'isCompleted': false},
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER PREMIUM ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _buildHeaderIcon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      "${widget.memberName.split(' ')[0]}'s Activities", // Prende solo il nome (es. "Enrico's Activities")
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: widget.themeColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // LA MAGIA: Apriamo AddTaskScreen e gli diciamo già per chi è!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(
                            assignedMemberIds: {widget.memberId}, 
                          ),
                        ),
                      );
                    },
                    child: _buildHeaderIcon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // --- LISTA ATTIVITÀ A FISARMONICA (Liquid Glass) ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
                physics: const BouncingScrollPhysics(),
                itemCount: _activitiesByDate.length,
                itemBuilder: (context, index) {
                  return ExpandableDateCard(
                    data: _activitiesByDate[index],
                    color: widget.themeColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.1), width: 1),
        boxShadow: [BoxShadow(color: widget.themeColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(icon, color: widget.themeColor, size: 24),
    );
  }
}

// --- WIDGET CARD FISARMONICA (Date Card) ---
class ExpandableDateCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color color;
  
  const ExpandableDateCard({super.key, required this.data, required this.color});

  @override
  State<ExpandableDateCard> createState() => _ExpandableDateCardState();
}

class _ExpandableDateCardState extends State<ExpandableDateCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final List tasks = widget.data['tasks'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ESPANSIONE BIANCA (I Task del giorno)
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 25),
              padding: const EdgeInsets.only(top: 70, bottom: 10, left: 20, right: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tasks.map<Widget>((task) {
                  bool isDone = task['isCompleted'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox custom
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: isDone ? widget.color.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isDone ? widget.color.withValues(alpha: 0.6) : const Color(0xFFF28482).withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Center(
                            child: Icon(isDone ? Icons.check : Icons.close, color: isDone ? widget.color : const Color(0xFFF28482), size: 14),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Dettagli Task
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w600, 
                                  color: isDone ? const Color(0xFF3D342C).withValues(alpha: 0.5) : const Color(0xFF3D342C),
                                  decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: const Color(0xFF3D342C).withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Text(
                                    task['time'],
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // PILLOLA PRINCIPALE (La Data)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 75,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.4)]
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                        ),
                        child: Icon(Icons.calendar_today_rounded, color: widget.color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.data['date'],
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                        color: widget.color.withValues(alpha: 0.6), size: 28
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}