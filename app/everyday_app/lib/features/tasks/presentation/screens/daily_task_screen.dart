import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';

import '../../data/models/subtask.dart';
import '../../data/models/task_assignement.dart';
import '../../data/models/task_with_details.dart';
import '../../domain/services/task_service.dart';
import '../widgets/task_card.dart';

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
    final changed = await AppRouter.navigate(
      context,
      AppRouteNames.addTask,
      arguments: AddTaskRouteArgs(
        initialDate: task.task.taskDate,
        personalOnly: true,
        initialTask: task,
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
                                  return TaskCard(
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
            final changed = await AppRouter.navigate(
              context,
              AppRouteNames.addTask,
              arguments: AddTaskRouteArgs(
                initialDate: widget.date,
                personalOnly: true,
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