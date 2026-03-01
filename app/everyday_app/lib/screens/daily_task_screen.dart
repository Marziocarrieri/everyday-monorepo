import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// --- MODELLI DATI FINTI PER TESTARE IL DESIGN ---
class SubTask {
  String title;
  bool isCompleted;
  SubTask({required this.title, required this.isCompleted});
}

class DailyTask {
  String id;
  String title;
  String timeLabel;
  String status; // 'safe' (verde), 'warning' (giallo), 'danger' (rosso)
  List<SubTask> subTasks;

  DailyTask({
    required this.id, required this.title, required this.timeLabel, 
    required this.status, required this.subTasks
  });
}

// --- SCHERMATA PRINCIPALE ---
class DailyTaskScreen extends StatefulWidget {
  const DailyTaskScreen({super.key});

  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  // Dati di esempio basati sul tuo Figma
  final List<DailyTask> _tasks = [
    DailyTask(
      id: '1', title: 'Homework oversight', timeLabel: '7:45AM - 8:45AM', status: 'warning',
      subTasks: [
        SubTask(title: 'Daily Assignments', isCompleted: true),
        SubTask(title: 'Notes from Teachers', isCompleted: false),
        SubTask(title: 'Parent Sign-Off', isCompleted: true),
        SubTask(title: 'Upcoming Tests', isCompleted: false),
        SubTask(title: 'Completed Homeworks', isCompleted: true),
      ]
    ),
    DailyTask(
      id: '2', title: 'Skin-care Routine', timeLabel: '7:45AM - 8:45AM', status: 'danger',
      subTasks: [
        SubTask(title: 'Cleanser', isCompleted: false),
        SubTask(title: 'Serum', isCompleted: false),
        SubTask(title: 'Moisturizer', isCompleted: false),
      ]
    ),
    DailyTask(
      id: '3', title: 'Seasonal Closet Swap', timeLabel: '7:45AM - 8:45AM', status: 'safe',
      subTasks: [
        SubTask(title: 'Outgrown Items', isCompleted: true),
        SubTask(title: 'Seasonal Items to Store', isCompleted: true),
        SubTask(title: 'Items to Donate', isCompleted: true),
        SubTask(title: 'Needed Items', isCompleted: true),
        SubTask(title: 'Storage Box Labels', isCompleted: true),
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E9), // Sfondo panna/crema
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A8B9E), size: 24),
                  ),
                  Text(
                    'Daily Task',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E)),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF5A8B9E), width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF5A8B9E), size: 28),
                  ),
                ],
              ),
            ),
            
            // --- LISTA DEI TASK ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                physics: const BouncingScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return ExpandableTaskCard(task: _tasks[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET ACCORDION (LA CARD CHE SI ESPANDE) ---
class ExpandableTaskCard extends StatefulWidget {
  final DailyTask task;
  const ExpandableTaskCard({super.key, required this.task});

  @override
  State<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends State<ExpandableTaskCard> {
  bool _isExpanded = false;

  // Riprendiamo la logica dei colori del frigo!
  Color _getStatusColor(String status) {
    switch (status) {
      case 'danger': return const Color(0xFFD67771); // Rosso
      case 'warning': return const Color(0xFFEFC066); // Giallo
      case 'safe': return const Color(0xFF8DBB75); // Verde
      default: return const Color(0xFF5A8B9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getStatusColor(widget.task.status);

    return marginContainer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sfondo bianco (appare solo quando espanso)
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 25), // Lascia spazio alla pillola colorata
              padding: const EdgeInsets.only(top: 45, bottom: 16, left: 16, right: 16), // Padding interno per i subtasks
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                ]
              ),
              child: Column(
                children: widget.task.subTasks.map((subTask) => _buildSubTaskRow(subTask)).toList(),
              ),
            ),

          // Pillola Colorata Principale
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              margin: const EdgeInsets.only(top: 8), // Lascia spazio per l'etichetta dell'orario
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: bgColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  const Text('•', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3D342C))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.arrow_back_ios_new_rounded, 
                    color: const Color(0xFF3D342C).withValues(alpha: 0.6), 
                    size: 20
                  ),
                ],
              ),
            ),
          ),

          // Etichetta Orario (sovrapposta in alto a sinistra)
          Positioned(
            top: 0,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8), // Leggermente trasparente
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bgColor.withValues(alpha: 0.5), width: 1),
              ),
              child: Text(
                widget.task.timeLabel,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper per distanziare le card
  Widget marginContainer({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: child,
    );
  }

  // --- SINGOLO SUB-TASK (Lista bianca) ---
  Widget _buildSubTaskRow(SubTask subTask) {
    final isDone = subTask.isCompleted;
    
    // Colori per la spunta o per la X
    final boxColor = isDone ? const Color(0xFF7CB9E8) : const Color(0xFFF28482);
    final iconData = isDone ? Icons.check : Icons.close;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            subTask.title,
            style: GoogleFonts.poppins(
              fontSize: 14, 
              fontWeight: FontWeight.w600, 
              color: const Color(0xFF3D342C)
            ),
          ),
          // Checkbox personalizzata stile Figma
          GestureDetector(
            onTap: () {
              // Qui in futuro metteremo la logica per invertire lo stato
              setState(() => subTask.isCompleted = !subTask.isCompleted);
            },
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: boxColor, width: 1.5),
              ),
              child: Center(
                child: Icon(iconData, color: boxColor, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}