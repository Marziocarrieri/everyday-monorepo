import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';

import '../../data/models/task_with_details.dart';
import '../../domain/services/task_service.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/task_delete_confirmation_dialog.dart';
import '../../utils/task_creator_identity.dart';
import 'add_task_screen.dart';

class DailyTaskScreen extends ConsumerWidget {
  final DateTime date;

  const DailyTaskScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final targetUserId = currentUser?.id ?? AppContext.instance.userId ?? '';

    return UserTaskTimelineScreen(
      date: date,
      targetUserId: targetUserId,
      readOnlyChecklist: false,
    );
  }
}

class UserTaskTimelineScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final String targetUserId;
  final bool readOnlyChecklist;

  const UserTaskTimelineScreen({
    super.key,
    required this.date,
    required this.targetUserId,
    this.readOnlyChecklist = false,
  });

  @override
  ConsumerState<UserTaskTimelineScreen> createState() =>
      _UserTaskTimelineScreenState();
}

class _UserTaskTimelineScreenState
    extends ConsumerState<UserTaskTimelineScreen> {
  late final TaskService _taskService;

  final Color themeColor = const Color(0xFF5A8B9E); // Colore Premium Azzurro

  @override
  void initState() {
    super.initState();
    _taskService = ref.read(taskServiceProvider);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- CONTROLLO RUOLO: VERIFICA SE L'UTENTE E' PERSONNEL ---
  bool get _isPersonnel {
    final role = AppContext.instance.activeMembership?.role.toUpperCase() ?? '';
    final cleanRole = role.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
    return cleanRole == 'PERSONNEL';
  }

  Future<void> _openAddTaskFlow() async {
    final changed = await Navigator.of(context).pushNamed(
      AppRouteNames.addTask,
      arguments: AddTaskRouteArgs(initialDate: widget.date, personalOnly: true),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task saved successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: themeColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Future<void> _toggleSubtask({
    required String subtaskId,
    required bool isDone,
  }) async {
    if (widget.readOnlyChecklist) {
      return;
    }

    if (!mounted) return;
    final optimisticOverrides = ref.read(
      optimisticSubtaskOverridesProvider.notifier,
    );
    optimisticOverrides.setOverride(subtaskId: subtaskId, isDone: isDone);

    try {
      await _taskService.setSubtaskDone(subtaskId: subtaskId, isDone: isDone);
    } catch (error) {
      if (mounted) {
        ref
            .read(optimisticSubtaskOverridesProvider.notifier)
            .clearOverride(subtaskId);
      }
      debugPrint('Error toggling subtask: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF28482),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Future<void> _toggleAssignmentStatus({
    required String assignmentId,
    required bool isDone,
  }) async {
    if (widget.readOnlyChecklist) {
      return;
    }

    final nextStatus = isDone ? 'DONE' : 'TODO';

    try {
      await _taskService.setAssignmentStatus(
        assignmentId: assignmentId,
        status: nextStatus,
      );
    } catch (error) {
      debugPrint('Error toggling assignment status: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF28482),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Future<void> _saveNote({
    required String assignmentId,
    required String note,
  }) async {
    if (widget.readOnlyChecklist) {
      return;
    }

    final saved = await _taskService.addPersonnelNote(
      assignmentId: assignmentId,
      note: note,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Note saved successfully'
              : 'Notes not available yet on this environment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: themeColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _openEditTask(TaskWithDetails task) async {
    if (widget.readOnlyChecklist) {
      return;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(
        initialDate: task.task.taskDate,
        personalOnly: true,
        initialTask: task,
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task updated successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: themeColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  String? _resolveTargetMemberId(TaskWithDetails task) {
    final normalizedTargetUserId = widget.targetUserId.trim();
    if (normalizedTargetUserId.isEmpty) {
      return null;
    }

    for (final assignment in task.assignments) {
      final assignmentUserId = assignment.member?.userId.trim();
      if (assignmentUserId == normalizedTargetUserId) {
        return assignment.memberId;
      }
    }

    return null;
  }

  Future<bool> _deleteTask(TaskWithDetails task) async {
    final currentUserId = AppContext.instance.userId;
    final currentMemberId = AppContext.instance.membershipId;
    final canDelete = isTaskCreatedByCurrentUser(
      taskCreatedBy: task.task.createdBy,
      currentUserId: currentUserId,
      currentMemberId: currentMemberId,
    );
    if (!canDelete) return false;

    final mustConfirmDelete = shouldShowTaskDeleteConfirmation(
      task: task,
      currentUserId: currentUserId,
      currentMemberId: currentMemberId,
    );

    if (mustConfirmDelete) {
      final confirmed = await showTaskDeleteConfirmationDialog(context);
      if (!confirmed) return false;
    }

    final targetMemberId = _resolveTargetMemberId(task);
    if (targetMemberId == null || targetMemberId.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'TASK DELETE SKIPPED -> unable to resolve target assignment member for task_id=${task.task.id} target_user_id=${widget.targetUserId}',
        );
      }
      return false;
    }

    try {
      await _taskService.removeTaskAssignment(
        taskId: task.task.id,
        memberId: targetMemberId,
      );
      if (!mounted) return false;
      return true;
    } catch (error) {
      debugPrint('Error deleting task: $error');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF28482),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(
      userTaskTimelineProvider(
        UserTaskTimelineQuery(
          date: widget.date,
          targetUserId: widget.targetUserId,
        ),
      ),
    );
    final roomsAsync = ref.watch(taskRoomsProvider);
    final roomNamesById = roomsAsync.maybeWhen(
      data: (rooms) => {for (final room in rooms) room.id: room.name},
      orElse: () => const <String, String>{},
    );
    final formattedDate = DateFormat('dd MMM, yyyy').format(widget.date);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F9FA),
              Color(0xFFE3EDF2),
            ], // Sfondo Premium App
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: _buildHeader(
                  formattedDate: formattedDate,
                  // NASCONDE IL BOTTONE SE L'UTENTE E' PERSONNEL
                  showAddButton: !_isPersonnel,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: tasksAsync.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(color: themeColor),
                        ),
                        error: (error, _) => Padding(
                          padding: const EdgeInsets.only(
                            left: 24.0,
                            right: 24.0,
                            bottom: 16.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF28482,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFF28482,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFF28482),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    error.toString(),
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFF28482),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (tasks) {
                          if (tasks.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 24.0,
                              right: 24.0,
                              bottom: 40.0,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              if (kDebugMode) {
                                debugPrint(
                                  'BUILDING TASKCARD FROM DAILY SCREEN -> taskId ${task.task.id}',
                                );
                              }
                              return TaskCard(
                                key: ValueKey(task.task.id),
                                taskWithDetails: task,
                                onSubtaskToggle: _toggleSubtask,
                                onAssignmentToggle: _toggleAssignmentStatus,
                                onSaveNote: _saveNote,
                                onEditTask: _openEditTask,
                                onConfirmDeleteTask: _deleteTask,
                                targetUserId: widget.targetUserId,
                                readOnlyChecklist: widget.readOnlyChecklist,
                                roomName: task.task.roomId != null
                                    ? roomNamesById[task.task.roomId!]
                                    : null,
                              );
                            },
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
      ),
    );
  }

  Widget _buildHeader({
    required String formattedDate,
    bool showAddButton = true, // Parametro aggiunto per controllare la visibilità
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: themeColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: themeColor,
              size: 20,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              'Daily Task',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: themeColor,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              formattedDate,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D342C).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        if (showAddButton)
          GestureDetector(
            onTap: _openAddTaskFlow,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, color: themeColor, size: 28),
            ),
          )
        else
          // Spazio vuoto per mantenere centrato il titolo
          const SizedBox(width: 48, height: 48),
      ],
    );
  }

  // === EMPTY STATE PREMIUM ===
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_rounded,
                size: 48,
                color: themeColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3D342C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no tasks\nassigned for this day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D342C).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}