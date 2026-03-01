import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../utils/status_color_utils.dart';
import 'add_task_screen.dart';

// --- MODELLI DATI ---
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
  // Dati di esempio (stessi del tuo Figma)
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER PREMIUM  ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: _buildPremiumHeader(context),
            ),
            const SizedBox(height: 10),
            
            // --- LISTA DEI TASK ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
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

  // --- HEADER WIDGET ---
  Widget _buildPremiumHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tasto Indietro
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A8B9E), size: 20),
          ),
        ),
        
        // Titolo
        Text(
          'Daily Task',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E)),
        ),
        
        // Tasto Aggiungi (+)
     GestureDetector(
       onTap: () {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (context) => const AddTaskScreen()),
         );
       },
       child: Container(
         width: 48, height: 48,
         decoration: BoxDecoration(
           color: Colors.white, shape: BoxShape.circle,
           border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
           boxShadow: [BoxShadow(color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
         ),
         child: const Icon(Icons.add_rounded, color: Color(0xFF5A8B9E), size: 28),
       ),
     ),
      ],
    );
  }
}

// --- WIDGET ACCORDION (LIQUID GLASS 2.0) ---
class ExpandableTaskCard extends StatefulWidget {
  final DailyTask task;
  const ExpandableTaskCard({super.key, required this.task});

  @override
  State<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends State<ExpandableTaskCard> {
  bool _isExpanded = false;

  // Nuova Logica Colori: Usa la funzione del Fridge Keeping per l'azzurro, o un grigio scuro se completato
  Color _getDynamicColor() {
    bool isAllDone = widget.task.subTasks.every((st) => st.isCompleted);
    return isAllDone ? const Color(0xFF7A898D) : getStatusColor('safe'); // <-- Usa la TUA funzione per l'azzurro esatto
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getDynamicColor();
    final bool isAllDone = widget.task.subTasks.every((st) => st.isCompleted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- SFONDO BIANCO ESPANSO CON I SUB-TASKS ---
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 25), // Lascia spazio alla pillola colorata
              padding: const EdgeInsets.only(top: 70, bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8), // Bianco traslucido morbidissimo
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                children: widget.task.subTasks.map((subTask) => _buildSubTaskRow(subTask)).toList(),
              ),
            ),

          // --- PILLOLA COLORATA PRINCIPALE (VETRO) ---
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: AnimatedContainer( // Sfuma il colore quando completi tutto!
                  duration: const Duration(milliseconds: 300),
                  height: 75, // Più alta per far respirare titolo e orario
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.15), // <-- Sfumatura leggera, come nel Fridge Keeping
                        Colors.white.withValues(alpha: 0.6)  
                      ]
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Icona tonda per richiamare lo stile del frigo, invece del pallino nero
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                        ),
                        child: Icon(Icons.check_circle_outline_rounded, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TITOLO TASK
                            Text(
                              widget.task.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16, 
                                fontWeight: FontWeight.w700, 
                                color: const Color(0xFF3D342C),
                                decoration: isAllDone ? TextDecoration.lineThrough : TextDecoration.none, // Sbarra il titolo se finito
                              ),
                            ),
                            const SizedBox(height: 2),
                            // NUOVO ORARIO: Pulito, integrato sotto il titolo
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: const Color(0xFF3D342C).withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.timeLabel,
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                          color: statusColor, 
                          size: 20
                        ),
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

  // --- SINGOLO SUB-TASK (Lista Interna) ---
  Widget _buildSubTaskRow(SubTask subTask) {
    final isDone = subTask.isCompleted;
    
    // Aggiornati anche i colori dei check interni per usare lo stesso azzurro del frigo
    final boxColor = isDone ? getStatusColor('safe') : const Color(0xFFF28482);
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
              color: isDone ? const Color(0xFF3D342C).withValues(alpha: 0.5) : const Color(0xFF3D342C),
              decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => subTask.isCompleted = !subTask.isCompleted),
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isDone ? boxColor.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: boxColor.withValues(alpha: 0.6), width: 1.5),
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