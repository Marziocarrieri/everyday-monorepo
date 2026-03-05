import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ECCO L'IMPORT AGGIUNTO!
import 'cohost_add_task_screen.dart';

// ==========================================
// FUNZIONE COLORI SIMULATA
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
class MockSubtask {
  final String id;
  final String title;
  bool isDone;

  MockSubtask({required this.id, required this.title, this.isDone = false});
}

class MockTask {
  final String id;
  final String title;
  final String? timeFrom;
  final String? timeTo;
  final String? roomName;
  bool isDone;
  final List<MockSubtask> subtasks;
  String? note;

  MockTask({
    required this.id,
    required this.title,
    this.timeFrom,
    this.timeTo,
    this.roomName,
    this.isDone = false,
    this.subtasks = const [],
    this.note,
  });
}

// ==========================================
// SCHERMATA PRINCIPALE
// ==========================================
class CohostDailyTaskScreen extends StatefulWidget {
  final DateTime date;

  const CohostDailyTaskScreen({super.key, required this.date});

  @override
  State<CohostDailyTaskScreen> createState() => _CohostDailyTaskScreenState();
}

class _CohostDailyTaskScreenState extends State<CohostDailyTaskScreen> {
  late List<MockTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = [
      MockTask(
        id: 't1', title: 'Pulizia Salotto', timeFrom: '09:00', timeTo: '10:30', roomName: 'Living Room',
        subtasks: [MockSubtask(id: 's1', title: 'Spolverare i mobili'), MockSubtask(id: 's2', title: 'Passare l\'aspirapolvere')],
      ),
      MockTask(id: 't2', title: 'Fare la lavatrice', timeFrom: '11:00', timeTo: '11:15', roomName: 'Bathroom', note: 'Usare detersivo delicato'),
      MockTask(id: 't3', title: 'Preparare il pranzo', timeFrom: '12:30', timeTo: '14:00', roomName: 'Kitchen', isDone: true),
    ];
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _simulateToggleSubtask(MockTask task, String subtaskId, bool isDone) {
    setState(() => task.subtasks.firstWhere((s) => s.id == subtaskId).isDone = isDone);
  }

  void _simulateToggleTask(MockTask task, bool isDone) => setState(() => task.isDone = isDone);
  void _simulateSaveNote(MockTask task, String note) { setState(() => task.note = note); _showSuccessSnackBar('Simulazione: Nota salvata'); }
  void _simulateDeleteTask(MockTask task) { setState(() => _tasks.removeWhere((t) => t.id == task.id)); _showSuccessSnackBar('Simulazione: Task eliminato'); }

  String _formatDisplayDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDisplayDate(widget.date);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: _buildHeader(formattedDate),
            ),
            Expanded(
              child: _tasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        return _TaskCard(
                          key: ValueKey(_tasks[index].id),
                          task: _tasks[index],
                          onSubtaskToggle: (id, done) => _simulateToggleSubtask(_tasks[index], id, done),
                          onTaskToggle: (done) => _simulateToggleTask(_tasks[index], done),
                          onSaveNote: (note) => _simulateSaveNote(_tasks[index], note),
                          onDelete: () => _simulateDeleteTask(_tasks[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    final themeColor = getStatusColor('safe'); 
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: themeColor, size: 20),
          ),
        ),
        Column(
          children: [
            Text('Daily Task', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: themeColor)),
            Text(formattedDate, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.5))),
          ],
        ),
        
        // --- IL TASTO "+" ORA È COLLEGATO QUI ---
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CohostAddTaskScreen(initialDate: widget.date),
              ),
            );
          },
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
              boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Icon(Icons.add_rounded, color: themeColor, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No tasks assigned today', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.6))),
    );
  }
}

// ==========================================
// COMPONENTE: SINGOLA CARD TASK 
// ==========================================
class _TaskCard extends StatefulWidget {
  final MockTask task;
  final Function(String subtaskId, bool isDone) onSubtaskToggle;
  final Function(bool isDone) onTaskToggle;
  final Function(String note) onSaveNote;
  final VoidCallback onDelete;

  const _TaskCard({
    super.key, required this.task, required this.onSubtaskToggle, required this.onTaskToggle, required this.onSaveNote, required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isExpanded = false;
  bool _isEditingNote = false;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.task.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskHasSubtasks = widget.task.subtasks.isNotEmpty;
    final isAllDone = taskHasSubtasks ? widget.task.subtasks.every((st) => st.isDone) : widget.task.isDone;

    final statusColor = isAllDone ? const Color(0xFF7A898D) : getStatusColor('safe');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Dismissible(
        key: ValueKey('task_${widget.task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete task'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
              ],
            ),
          );
        },
        onDismissed: (_) => widget.onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: const Color(0xFFE76F51).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_isExpanded)
              Container(
                margin: const EdgeInsets.only(top: 25),
                padding: const EdgeInsets.only(top: 70, bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.task.subtasks.map((subtask) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subtask.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: subtask.isDone ? const Color(0xFF3D342C).withValues(alpha: 0.5) : const Color(0xFF3D342C),
                                decoration: subtask.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.onSubtaskToggle(subtask.id, !subtask.isDone),
                            child: Icon(subtask.isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: statusColor),
                          ),
                        ],
                      ),
                    )),
                    if (!taskHasSubtasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('No subtasks. Use the checkbox on the task row to mark it done.', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.65))),
                      ),
                    const SizedBox(height: 6),
                    if (_isEditingNote) ...[
                      TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'My note', border: OutlineInputBorder(), isDense: true), maxLines: 3),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => setState(() { _noteController.text = widget.task.note ?? ''; _isEditingNote = false; }), child: const Text('Cancel')),
                          TextButton(onPressed: () { widget.onSaveNote(_noteController.text.trim()); setState(() => _isEditingNote = false); }, child: const Text('Save note')),
                        ],
                      ),
                    ] else if (widget.task.note == null || widget.task.note!.isEmpty)
                      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => _isEditingNote = true), icon: const Text('✏️'), label: const Text('Add note')))
                    else
                      GestureDetector(
                        onTap: () => setState(() { _isEditingNote = true; _noteController.text = widget.task.note!; }),
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 1)),
                          child: Text(widget.task.note!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C))),
                        ),
                      ),
                  ],
                ),
              ),

            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [statusColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.6)]),
                      borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: Icon(isAllDone ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.task.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF3D342C), decoration: isAllDone ? TextDecoration.lineThrough : TextDecoration.none),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit_rounded, size: 18, color: statusColor),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.task.timeFrom ?? '--:--'} - ${widget.task.timeTo ?? '--:--'}',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.6)),
                              ),
                              if (widget.task.roomName != null)
                                Text('📍 ${widget.task.roomName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                        if (!taskHasSubtasks)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => widget.onTaskToggle(!widget.task.isDone),
                              child: Icon(widget.task.isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: statusColor),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle),
                          child: Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: statusColor, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}