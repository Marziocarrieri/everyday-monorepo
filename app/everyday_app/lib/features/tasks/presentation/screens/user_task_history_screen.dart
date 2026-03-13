import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:everyday_app/features/tasks/presentation/providers/task_providers.dart';
import 'package:everyday_app/features/tasks/presentation/screens/add_task_screen.dart';
import 'package:everyday_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserTaskHistoryScreen extends ConsumerWidget {
  final String targetUserId;

  const UserTaskHistoryScreen({super.key, required this.targetUserId});

  bool _isAssignedToTargetUser(TaskWithDetails task) {
    return task.assignments.any(
      (assignment) => assignment.member?.userId == targetUserId,
    );
  }

  int _startTimeMinutes(TaskWithDetails task) {
    final rawTime = task.task.timeFrom;
    if (rawTime == null || rawTime.isEmpty) {
      return -1;
    }

    final chunks = rawTime.split(':');
    if (chunks.length < 2) {
      return -1;
    }

    final hour = int.tryParse(chunks[0]);
    final minute = int.tryParse(chunks[1]);
    if (hour == null || minute == null) {
      return -1;
    }

    return (hour * 60) + minute;
  }

  List<_HistoryDayGroup> _buildGroupedHistory({
    required String householdId,
    required List<TaskWithDetails> tasks,
  }) {
    final filtered = tasks
        .where((task) => task.task.householdId == householdId)
        .where(_isAssignedToTargetUser)
        .toList();

    final grouped = <DateTime, List<TaskWithDetails>>{};

    for (final task in filtered) {
      final localDate = task.task.taskDate.toLocal();
      final dayKey = DateTime(localDate.year, localDate.month, localDate.day);
      grouped.putIfAbsent(dayKey, () => <TaskWithDetails>[]).add(task);
    }

    final orderedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return orderedDays.map((day) {
      final dayTasks = grouped[day]!
        ..sort((left, right) {
          final rightStart = _startTimeMinutes(right);
          final leftStart = _startTimeMinutes(left);

          final byStartTime = rightStart.compareTo(leftStart);
          if (byStartTime != 0) {
            return byStartTime;
          }

          return right.task.taskDate.compareTo(left.task.taskDate);
        });

      return _HistoryDayGroup(day: day, tasks: dayTasks);
    }).toList();
  }

  Future<void> _openAddTask(BuildContext context) async {
    final changed = await Navigator.of(context).pushNamed(
      AppRouteNames.addTask,
      arguments: AddTaskRouteArgs(
        initialDate: DateTime.now(),
        preselectedAssigneeUserId: targetUserId,
        supervisionCreationMode: true,
      ),
    );

    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task saved successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF5A8B9E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Future<void> _noopToggleSubtask({
    required String subtaskId,
    required bool isDone,
  }) async {}

  Future<void> _noopToggleAssignment({
    required String assignmentId,
    required bool isDone,
  }) async {}

  Future<void> _noopSaveNote({
    required String assignmentId,
    required String note,
  }) async {}

  Future<void> _openEditTask(BuildContext context, TaskWithDetails task) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: task.task.taskDate,
        initialTask: task,
        preselectedAssigneeUserId: targetUserId,
        supervisionCreationMode: true,
      ),
    );

    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task updated successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF5A8B9E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  Future<bool> _noopDeleteTask(TaskWithDetails task) async {
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);
    
    // --- NUOVO CONTROLLO RUOLO: Blocca Cohost e Personnel ---
    final role = AppContext.instance.activeMembership?.role.toUpperCase() ?? '';
    final cleanRole = role.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
    final isCohostOrPersonnel = cleanRole == 'COHOST' || cleanRole == 'PERSONNEL';

    final tasksAsync = ref.watch(tasksStreamProvider);
    final roomsAsync = ref.watch(taskRoomsProvider);
    final roomNamesById = roomsAsync.maybeWhen(
      data: (rooms) => {for (final room in rooms) room.id: room.name},
      orElse: () => const <String, String>{},
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F9FA), Color(0xFFE3EDF2)],
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
                  context: context,
                  onAddTask: () => _openAddTask(context),
                  // Nascondi il bottone se è Cohost o Personnel
                  showAddButton: !isCohostOrPersonnel,
                ),
              ),
              Expanded(
                child: tasksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5A8B9E)),
                  ),
                  error: (error, _) => _buildErrorState(error.toString()),
                  data: (tasks) {
                    if (householdId == null || householdId.isEmpty) {
                      return _buildEmptyState();
                    }

                    final groupedHistory = _buildGroupedHistory(
                      householdId: householdId,
                      tasks: tasks,
                    );

                    if (groupedHistory.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 40,
                      ),
                      itemCount: groupedHistory.length,
                      itemBuilder: (context, index) {
                        final group = groupedHistory[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDayHeader(group.day),
                            const SizedBox(height: 14),
                            ...group.tasks.map(
                              (task) => TaskCard(
                                key: ValueKey('history_${task.task.id}'),
                                taskWithDetails: task,
                                onSubtaskToggle: _noopToggleSubtask,
                                onAssignmentToggle: _noopToggleAssignment,
                                onSaveNote: _noopSaveNote,
                                onEditTask: (task) =>
                                    _openEditTask(context, task),
                                onConfirmDeleteTask: _noopDeleteTask,
                                targetUserId: targetUserId,
                                interactionMode: TaskInteractionMode
                                    .supervisionHostReadOnlyChecklist,
                                roomName: task.task.roomId != null
                                    ? roomNamesById[task.task.roomId!]
                                    : null,
                              ),
                            ),
                            if (index < groupedHistory.length - 1)
                              const SizedBox(height: 10),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required VoidCallback onAddTask,
    bool showAddButton = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: _buildHeaderIcon(Icons.arrow_back_ios_new_rounded),
        ),
        Expanded(
          child: Text(
            'Task History',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5A8B9E),
            ),
          ),
        ),
        if (showAddButton)
          GestureDetector(
            onTap: onAddTask,
            child: _buildHeaderIcon(Icons.add_rounded),
          )
        else
          const SizedBox(width: 48, height: 48),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    const accent = Color(0xFF5A8B9E);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: 24),
    );
  }

  Widget _buildDayHeader(DateTime day) {
    final weekday = DateFormat('EEEE').format(day);
    final fullDate = DateFormat('dd MMMM yyyy').format(day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF5A8B9E).withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekday,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D342C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fullDate,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D342C).withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          'No history for this member yet.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D342C).withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF28482).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF28482).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFF28482)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF28482),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDayGroup {
  final DateTime day;
  final List<TaskWithDetails> tasks;

  const _HistoryDayGroup({required this.day, required this.tasks});
}