import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/app_context.dart';
import '../models/subtask.dart';
import '../models/task_assignement.dart';
import '../models/task_with_details.dart';
import '../services/task_service.dart';
import '../utils/status_color_utils.dart';
import 'add_task_screen.dart';

class DailyTaskScreen extends StatefulWidget {
  final DateTime date;

  const DailyTaskScreen({super.key, required this.date});

  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  String? _error;
  List<TaskWithDetails> _tasks = const [];
  Map<String, String> _roomNamesById = const {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final personalTasks = await _taskService.getTasksAssignedToCurrentMember();
      final rooms = await _taskService.getAvailableRooms();
      final filtered = personalTasks
          .where((task) => _isSameDay(task.task.taskDate, widget.date))
          .toList();

      if (!mounted) return;
      setState(() {
        _tasks = filtered;
        _roomNamesById = {
          for (final room in rooms) room.id: room.name,
        };
      });
    } catch (error) {
      debugPrint('Error loading daily tasks: $error');
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSubtask({
    required String subtaskId,
    required bool isDone,
  }) async {
    try {
      await _taskService.setSubtaskDone(subtaskId: subtaskId, isDone: isDone);
      if (!mounted) return;

      setState(() {
        _tasks = _tasks
            .map(
              (taskWithDetails) => TaskWithDetails(
                task: taskWithDetails.task,
                assignments: taskWithDetails.assignments,
                subtasks: taskWithDetails.subtasks
                    .map(
                      (subtask) => subtask.id == subtaskId
                          ? Subtask(
                              id: subtask.id,
                              taskId: subtask.taskId,
                              title: subtask.title,
                              isDone: isDone,
                            )
                          : subtask,
                    )
                    .toList(),
              ),
            )
            .toList();
      });
    } catch (error) {
      debugPrint('Error toggling subtask: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleAssignmentStatus({
    required String assignmentId,
    required bool isDone,
  }) async {
    final nextStatus = isDone ? 'DONE' : 'TODO';

    try {
      await _taskService.setAssignmentStatus(
        assignmentId: assignmentId,
        status: nextStatus,
      );

      if (!mounted) return;
      setState(() {
        _tasks = _tasks
            .map(
              (taskWithDetails) => TaskWithDetails(
                task: taskWithDetails.task,
                subtasks: taskWithDetails.subtasks,
                assignments: taskWithDetails.assignments
                    .map(
                      (assignment) => assignment.id == assignmentId
                          ? TaskAssignment(
                              id: assignment.id,
                              taskId: assignment.taskId,
                              memberId: assignment.memberId,
                              status: nextStatus,
                              note: assignment.note,
                              completedAt: assignment.completedAt,
                              member: assignment.member,
                            )
                          : assignment,
                    )
                    .toList(),
              ),
            )
            .toList();
      });
    } catch (error) {
      debugPrint('Error toggling assignment status: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveNote({
    required String assignmentId,
    required String note,
  }) async {
    final saved = await _taskService.addPersonnelNote(
      assignmentId: assignmentId,
      note: note,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Note saved' : 'Notes not available yet on this environment',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openEditTask(TaskWithDetails task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          initialDate: task.task.taskDate,
          personalOnly: true,
          initialTask: task,
        ),
      ),
    );

    if (changed == true) {
      await _loadTasks();
    }
  }

  Future<bool> _deleteTask(TaskWithDetails task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    try {
      await _taskService.deleteTask(task.task.id);
      if (!mounted) return false;
      await _loadTasks();
      return true;
    } catch (error) {
      debugPrint('Error deleting task: $error');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM, yyyy').format(widget.date);

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
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _tasks.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 24.0,
                                  right: 24.0,
                                  bottom: 40.0,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _tasks.length,
                                itemBuilder: (context, index) {
                                  final task = _tasks[index];
                                  return _TaskCard(
                                    key: ValueKey(task.task.id),
                                    taskWithDetails: task,
                                    onSubtaskToggle: _toggleSubtask,
                                    onAssignmentToggle: _toggleAssignmentStatus,
                                    onSaveNote: _saveNote,
                                    onEditTask: _openEditTask,
                                    onConfirmDeleteTask: _deleteTask,
                                    roomName: task.task.roomId != null
                                        ? _roomNamesById[task.task.roomId!]
                                        : null,
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        Column(
          children: [
            Text(
              'Daily Task',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF5A8B9E)),
            ),
            Text(
              formattedDate, 
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.5)),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => AddTaskScreen(
                  initialDate: widget.date,
                  personalOnly: true,
                ),
              ),
            );
            if (changed == true) {
              await _loadTasks();
            }
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No tasks assigned today',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D342C).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final TaskWithDetails taskWithDetails;
  final Future<void> Function({required String subtaskId, required bool isDone})
      onSubtaskToggle;
  final Future<void> Function({required String assignmentId, required bool isDone})
      onAssignmentToggle;
  final Future<void> Function({required String assignmentId, required String note})
      onSaveNote;
  final Future<void> Function(TaskWithDetails task) onEditTask;
  final Future<bool> Function(TaskWithDetails task) onConfirmDeleteTask;
  final String? roomName;

  const _TaskCard({
    super.key,
    required this.taskWithDetails,
    required this.onSubtaskToggle,
    required this.onAssignmentToggle,
    required this.onSaveNote,
    required this.onEditTask,
    required this.onConfirmDeleteTask,
    this.roomName,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isExpanded = false;
  bool _isEditingNote = false;
  String _savedNote = '';
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final currentMembershipId = AppContext.instance.membershipId;
    final assignment = widget.taskWithDetails.assignments
        .where((item) => item.memberId == currentMembershipId)
        .toList();
    _savedNote = assignment.isNotEmpty ? (assignment.first.note ?? '').trim() : '';
    _noteController = TextEditingController(
      text: _savedNote,
    );
  }

  @override
  void didUpdateWidget(covariant _TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditingNote) return;

    final currentMembershipId = AppContext.instance.membershipId;
    final assignment = widget.taskWithDetails.assignments
        .where((item) => item.memberId == currentMembershipId)
        .toList();

    final latestNote = assignment.isNotEmpty
        ? (assignment.first.note ?? '').trim()
        : '';

    if (latestNote != _savedNote) {
      _savedNote = latestNote;
      _noteController.text = latestNote;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtasks = widget.taskWithDetails.subtasks;
    final taskHasSubtasks = subtasks.isNotEmpty;
    final isAllDone = taskHasSubtasks && subtasks.every((st) => st.isDone);

    final currentMembershipId = AppContext.instance.membershipId;
    final ownAssignment = widget.taskWithDetails.assignments
      .where((assignment) => assignment.memberId == currentMembershipId)
      .toList();
    final ownAssignmentStatus = ownAssignment.isNotEmpty
      ? ownAssignment.first.status.toUpperCase()
      : 'TODO';
    final isTaskAssignmentDone = ownAssignmentStatus == 'DONE';

    final statusColor = (taskHasSubtasks ? isAllDone : isTaskAssignmentDone)
        ? const Color(0xFF7A898D)
        : getStatusColor('safe');

    final assignmentNames = widget.taskWithDetails.assignments
        .map((assignment) => assignment.member?.profile?.name)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();

    final timeFrom = _formatTaskTime(widget.taskWithDetails.task.timeFrom);
    final timeTo = _formatTaskTime(widget.taskWithDetails.task.timeTo);

    final roomId = widget.taskWithDetails.task.roomId;
    final roomLabel = widget.roomName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Dismissible(
        key: ValueKey('task_${widget.taskWithDetails.task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return await widget.onConfirmDeleteTask(widget.taskWithDetails);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE76F51).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
          ),
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
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (assignmentNames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Assigned to: ${assignmentNames.join(', ')}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D342C).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ...subtasks.map(
                    (subtask) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subtask.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: subtask.isDone
                                    ? const Color(0xFF3D342C).withValues(alpha: 0.5)
                                    : const Color(0xFF3D342C),
                                decoration: subtask.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              widget.onSubtaskToggle(
                                subtaskId: subtask.id,
                                isDone: !subtask.isDone,
                              );
                            },
                            child: Icon(
                              subtask.isDone
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!taskHasSubtasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No subtasks. Use the checkbox on the task row to mark it done.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3D342C).withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  if (ownAssignment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    if (_isEditingNote) ...[
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'My note',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _noteController.text = _savedNote;
                                _isEditingNote = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final note = _noteController.text.trim();
                              await widget.onSaveNote(
                                assignmentId: ownAssignment.first.id,
                                note: note,
                              );
                              if (!mounted) return;
                              setState(() {
                                _savedNote = note;
                                _isEditingNote = false;
                              });
                            },
                            child: const Text('Save note'),
                          ),
                        ],
                      ),
                    ] else if (_savedNote.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditingNote = true;
                            });
                          },
                          icon: const Text('✏️'),
                          label: const Text('Add note'),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditingNote = true;
                            _noteController.text = _savedNote;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _savedNote,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3D342C),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [statusColor.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.6)]
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.taskWithDetails.task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF3D342C),
                                      decoration: (taskHasSubtasks
                                              ? isAllDone
                                              : isTaskAssignmentDone)
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    widget.onEditTask(widget.taskWithDetails);
                                  },
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: Color(0xFF5A8B9E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$timeFrom - $timeTo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D342C).withValues(alpha: 0.6),
                              ),
                            ),
                            if (roomId != null)
                              Text(
                                '📍 ${roomLabel ?? 'Room assigned'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D342C).withValues(alpha: 0.75),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!taskHasSubtasks && ownAssignment.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              widget.onAssignmentToggle(
                                assignmentId: ownAssignment.first.id,
                                isDone: !isTaskAssignmentDone,
                              );
                            },
                            child: Icon(
                              isTaskAssignmentDone
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: statusColor,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: statusColor,
                          size: 20,
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
      ),
    );
  }

  String _formatTaskTime(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return '--:--';
    }

    final value = rawValue.trim();
    for (final pattern in ['HH:mm:ss', 'HH:mm']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(value);
        return DateFormat('HH:mm').format(parsed);
      } catch (_) {}
    }

    final chunks = value.split(':');
    if (chunks.length >= 2) {
      return '${chunks[0].padLeft(2, '0')}:${chunks[1].padLeft(2, '0')}';
    }

    return '--:--';
  }
}