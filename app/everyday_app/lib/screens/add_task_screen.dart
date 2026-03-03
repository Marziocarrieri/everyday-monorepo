import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../utils/status_color_utils.dart'; // IMPORTA LA TUA MAGICA FUNZIONE COLORI

// ==========================================
// 1. SCHERMATA PRINCIPALE (LIBRERIA TASK)
// ==========================================
class AddTaskScreen extends StatefulWidget {
  // --- NOVITÀ: Parametro opzionale per ricevere i membri selezionati! ---
  final Set<String>? assignedMemberIds;

  const AddTaskScreen({super.key, this.assignedMemberIds});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Categorie e Task preimpostati
  final Map<String, List<String>> _suggestedTasks = {
    'Kids Management': [
      'School Drop-off / Pick-up',
      'After-School Activities',
      'Pediatric Check-ups',
    ],
    'Home Management': [
      'Home Repairs',
      'Car Maintenance',
    ],
    'Personal Care': [
      'Beauty Appointment',
      'Mental Health Check',
    ],
  };

  void _openTaskSheet({String? initialTitle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(
        initialTitle: initialTitle,
        assignedMemberIds: widget.assignedMemberIds, // <-- Passiamo i membri al Bottom Sheet!
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usiamo la TUA funzione per l'azzurro esatto
    final Color colorSafeAzzurro = getStatusColor('safe');

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
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: colorSafeAzzurro.withValues(alpha: 0.1), width: 1),
                        boxShadow: [BoxShadow(color: colorSafeAzzurro.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: colorSafeAzzurro, size: 20),
                    ),
                  ),
                  Text('Add a Task', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: colorSafeAzzurro)),
                  GestureDetector(
                    onTap: () => _openTaskSheet(), 
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: colorSafeAzzurro.withValues(alpha: 0.1), width: 1),
                        boxShadow: [BoxShadow(color: colorSafeAzzurro.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: colorSafeAzzurro, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- BARRA DI RICERCA GLASS BIANCA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    height: 55, padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))]
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search templates...', 
                              hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.4), fontSize: 15), 
                              border: InputBorder.none
                            ),
                            style: GoogleFonts.poppins(color: const Color(0xFF3D342C)),
                          ),
                        ),
                        Icon(Icons.search_rounded, color: colorSafeAzzurro, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- LISTA DELLE CATEGORIE ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _suggestedTasks.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key, 
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF3D342C))
                          ),
                          const SizedBox(height: 12),
                          ...entry.value.map((taskName) => _buildSuggestionPill(taskName, colorSafeAzzurro)).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PILLOLA DEL SUGGERIMENTO CON ICONCINA ---
  Widget _buildSuggestionPill(String taskName, Color colorSafeAzzurro) {
    return GestureDetector(
      onTap: () => _openTaskSheet(initialTitle: taskName),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    colorSafeAzzurro.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.4) 
                  ]
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [BoxShadow(color: colorSafeAzzurro.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: colorSafeAzzurro.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                    ),
                    child: Icon(Icons.check_circle_outline_rounded, color: colorSafeAzzurro, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      taskName, 
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C))
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ==========================================
// 2. BOTTOM SHEET (IL POPUP PER AGGIUNGERE IL TASK)
// ==========================================
class AddTaskSheet extends StatefulWidget {
  final String? initialTitle;
  // --- NOVITÀ: Il popup ora sa a chi stiamo assegnando il task ---
  final Set<String>? assignedMemberIds; 

  const AddTaskSheet({super.key, this.initialTitle, this.assignedMemberIds});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _titleController;
  final List<TextEditingController> _subTaskControllers = [TextEditingController()];
  
  DateTime? _selectedDate;
  DateTime? _startTime;
  DateTime? _endTime;

  final Color colorOrange = const Color(0xFFF4A261);
  final Color colorRed = const Color(0xFFF28482);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  void _addSubTask() {
    setState(() => _subTaskControllers.add(TextEditingController()));
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTaskControllers[index].dispose();
      _subTaskControllers.removeAt(index);
    });
  }

  void _showIOSPicker({required Widget child, required VoidCallback onConfirm}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280, padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)), onPressed: () => Navigator.of(context).pop()),
                    CupertinoButton(child: Text('Done', style: GoogleFonts.poppins(color: colorOrange, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: () { onConfirm(); Navigator.of(context).pop(); })
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDate() {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    _showIOSPicker(
      child: CupertinoDatePicker(initialDateTime: tempDate, mode: CupertinoDatePickerMode.date, onDateTimeChanged: (newDate) => tempDate = newDate),
      onConfirm: () => setState(() => _selectedDate = tempDate),
    );
  }

  void _selectTime(bool isStart) {
    DateTime tempTime = isStart ? (_startTime ?? DateTime.now()) : (_endTime ?? DateTime.now().add(const Duration(hours: 1)));
    _showIOSPicker(
      child: CupertinoDatePicker(initialDateTime: tempTime, mode: CupertinoDatePickerMode.time, onDateTimeChanged: (newTime) => tempTime = newTime),
      onConfirm: () => setState(() { if (isStart) _startTime = tempTime; else _endTime = tempTime; }),
    );
  }

  String _formatDate(DateTime date) => "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _subTaskControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color colorSafeAzzurro = getStatusColor('safe'); // Azzurro esatto!

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), border: Border.all(color: Colors.white, width: 1.5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: const Color(0xFF3D342C).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              
              // --- SE ABBIAMO RICEVUTO DEI MEMBRI DALLA FAMILY SCREEN, MOSTRIAMO UN BADGE ---
              if (widget.assignedMemberIds != null && widget.assignedMemberIds!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Assigning to ${widget.assignedMemberIds!.length} member(s)',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: colorOrange),
                  ),
                ),
              // --------------------------------------------------------------------------------

              Text('Task Details', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: colorSafeAzzurro)),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CARD DEL TITOLO ---
                      _buildGlassTextField(controller: _titleController, hint: 'Task Name', color: colorSafeAzzurro, isTitle: true),
                      const SizedBox(height: 20),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildActionPill(icon: Icons.calendar_today_rounded, text: _selectedDate != null ? _formatDate(_selectedDate!) : 'Set Date', color: colorOrange, onTap: _selectDate),
                            const SizedBox(width: 10),
                            _buildActionPill(icon: Icons.access_time_rounded, text: _startTime != null ? TimeOfDay.fromDateTime(_startTime!).format(context) : 'Start Time', color: colorOrange, onTap: () => _selectTime(true)),
                            const SizedBox(width: 10),
                            _buildActionPill(icon: Icons.access_time_filled_rounded, text: _endTime != null ? TimeOfDay.fromDateTime(_endTime!).format(context) : 'End Time', color: colorOrange, onTap: () => _selectTime(false)),
                            const SizedBox(width: 10),
                            _buildActionPill(icon: Icons.add_rounded, text: 'Sub-task', color: colorSafeAzzurro, onTap: _addSubTask),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      ..._subTaskControllers.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(child: _buildGlassTextField(controller: entry.value, hint: 'Sub-task detail...', color: colorSafeAzzurro)),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _removeSubTask(entry.key),
                                child: Container(
                                  width: 44, height: 44, 
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.6), 
                                    borderRadius: BorderRadius.circular(16), 
                                    border: Border.all(color: colorRed.withValues(alpha: 0.5), width: 1.5)
                                  ), 
                                  child: Icon(Icons.remove, color: colorRed)
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // --- TASTO SALVA (Qui un domani ci sarà la vera logica per Supabase) ---
              GestureDetector(
                onTap: () {
                  // ESEMPIO DI LOGICA FUTURA:
                  // final assignedTo = widget.assignedMemberIds ?? ['me'];
                  // print("Salvando il task per gli utenti: $assignedTo");
                  Navigator.pop(context); // Chiude il Bottom Sheet
                  Navigator.pop(context); // Chiude la AddTaskScreen
                },
                child: Container(
                  width: 70, height: 70, 
                  decoration: BoxDecoration(
                    color: colorSafeAzzurro, shape: BoxShape.circle, 
                    boxShadow: [BoxShadow(color: colorSafeAzzurro.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))], 
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2)
                  ), 
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({required TextEditingController controller, required String hint, required Color color, bool isTitle = false}) {
    return Container(
      height: isTitle ? 60 : 50, padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isTitle ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.6), 
        borderRadius: BorderRadius.circular(isTitle ? 20 : 16), 
        border: Border.all(color: isTitle ? color.withValues(alpha: 0.5) : Colors.white, width: 1.5), 
        boxShadow: isTitle ? [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))] : []
      ),
      child: Center(
        child: TextField(
          controller: controller, 
          style: GoogleFonts.poppins(fontSize: isTitle ? 18 : 15, fontWeight: isTitle ? FontWeight.w700 : FontWeight.w500, color: const Color(0xFF3D342C)),
          decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.4))),
        ),
      ),
    );
  }

  Widget _buildActionPill({required IconData icon, required String text, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5), 
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Icon(icon, color: color, size: 18), 
            const SizedBox(width: 8), 
            Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: color))
          ]
        ),
      ),
    );
  }
}