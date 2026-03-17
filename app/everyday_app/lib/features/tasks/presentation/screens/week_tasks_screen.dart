import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:everyday_app/features/tasks/presentation/providers/task_providers.dart';
import 'package:everyday_app/features/tasks/presentation/screens/add_task_screen.dart';
import 'package:everyday_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:everyday_app/features/tasks/presentation/widgets/task_delete_confirmation_dialog.dart';
import 'package:everyday_app/features/tasks/utils/task_creator_identity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WeekTasksScreen extends ConsumerStatefulWidget {
  const WeekTasksScreen({super.key});

  @override
  ConsumerState<WeekTasksScreen> createState() => _WeekTasksScreenState();
}

class _WeekTasksScreenState extends ConsumerState<WeekTasksScreen> {
  DateTime _selectedWeek = DateTime.now();
  bool _isCopying = false;

  List<_HistoryDayGroup> _buildGroupedHistory({
    required List<TaskWithDetails> tasks,
  }) {
    final grouped = <DateTime, List<TaskWithDetails>>{};

    for (final task in tasks) {
      final localDate = task.task.taskDate.toLocal();
      final dayKey = DateTime(localDate.year, localDate.month, localDate.day);
      grouped.putIfAbsent(dayKey, () => <TaskWithDetails>[]).add(task);
    }

    final orderedDays = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return orderedDays.map((day) {
      return _HistoryDayGroup(day: day, tasks: grouped[day]!);
    }).toList();
  }

  Future<void> _openEditTask(BuildContext context, TaskWithDetails task, String? currentUserId) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: task.task.taskDate,
        initialTask: task,
        preselectedAssigneeUserId: currentUserId,
      ),
    );

    if (changed == true && context.mounted) {
      _showSnackBar('Task updated successfully');
    }
  }

  Future<bool> _deleteTask(BuildContext context, WidgetRef ref, TaskWithDetails task) async {
    final currentUserId = AppContext.instance.userId;
    final currentMemberId = AppContext.instance.membershipId;
    final isCreator = isTaskCreatedByCurrentUser(
      taskCreatedBy: task.task.createdBy,
      currentUserId: currentUserId,
      currentMemberId: currentMemberId,
    );

    if (!isCreator) return false;

    final mustConfirmDelete = shouldShowTaskDeleteConfirmation(
      task: task,
      currentUserId: currentUserId,
      currentMemberId: currentMemberId,
    );

    if (mustConfirmDelete) {
      final confirmed = await showTaskDeleteConfirmationDialog(context);
      if (!confirmed) return false;
    }

    try {
      await ref.read(taskServiceProvider).removeTaskAssignment(
        taskId: task.task.id,
        memberId: currentMemberId ?? '',
      );
      return true;
    } catch (error) {
      return false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFF28482) : const Color(0xFF5A8B9E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _formatWeekRange(DateTime date) {
    final daysSinceMonday = date.weekday - 1;
    final start = date.subtract(Duration(days: daysSinceMonday));
    final end = start.add(const Duration(days: 6));
    
    final startStr = DateFormat('dd').format(start);
    final endStr = DateFormat('dd MMM yyyy').format(end);
    
    if (start.month != end.month) {
        return '${DateFormat('dd MMM').format(start)} - $endStr';
    }
    return '$startStr - $endStr';
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeek,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5A8B9E)),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) {
      setState(() => _selectedWeek = picked);
    }
  }

  // --- LOGICA DI COPIA SETTIMANA CON SOVRASCRITTURA ---
  Future<void> _handleCopyWeek() async {
    final sourceDate = await showDatePicker(
      context: context,
      initialDate: _selectedWeek.subtract(const Duration(days: 7)), 
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'SELECT SOURCE WEEK TO CLONE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5A8B9E)),
          ),
          child: child!,
        );
      }
    );

    if (sourceDate == null) return;

    // POPUP DI PERICOLO ROSSO
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32), side: const BorderSide(color: Colors.white, width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: const Color(0xFFF28482).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF28482), size: 28),
                ),
                const SizedBox(height: 20),
                Text('Overwrite Week?', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF3D342C))),
                const SizedBox(height: 12),
                Text(
                  'All existing tasks in the current week will be DELETED and replaced with the tasks from the week of ${DateFormat('MMM dd').format(sourceDate)}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withOpacity(0.6)),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF3D342C).withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withOpacity(0.7)))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(color: const Color(0xFFF28482), borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Overwrite', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
    );

    if (confirmed != true) return;

    setState(() => _isCopying = true);
    try {
      await ref.read(taskServiceProvider).copyWeekTasks(
        sourceWeekDate: sourceDate,
        targetWeekDate: _selectedWeek,
      );
      _showSnackBar('Week overwritten successfully! ✨');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isCopying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(weeklyTasksFamilyProvider(_selectedWeek));
    final roomsAsync = ref.watch(taskRoomsProvider);
    final currentUserId = AppContext.instance.userId;
    
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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: _buildHeader(context),
                  ),
                  Expanded(
                    child: tasksAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF5A8B9E))),
                      error: (error, _) => _buildErrorState(error.toString()),
                      data: (tasks) {
                        final groupedHistory = _buildGroupedHistory(tasks: tasks);

                        if (groupedHistory.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
                          itemCount: groupedHistory.length,
                          itemBuilder: (context, index) {
                            final group = groupedHistory[index];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDayHeader(group.day),
                                const SizedBox(height: 14),
                                ...group.tasks.map((task) {
                                  return TaskCard(
                                    key: ValueKey('weekly_${task.task.id}'),
                                    taskWithDetails: task,
                                    // --- FIX PERFETTO PARAMETRI NOMINATI ---
                                    onSubtaskToggle: ({required String subtaskId, required bool isDone}) async {
                                      await ref.read(taskServiceProvider).setSubtaskDone(subtaskId: subtaskId, isDone: isDone);
                                    },
                                    onAssignmentToggle: ({required String assignmentId, required bool isDone}) async {
                                      final status = isDone ? 'DONE' : 'TODO';
                                      await ref.read(taskServiceProvider).setAssignmentStatus(assignmentId: assignmentId, status: status);
                                    },
                                    onSaveNote: ({required String assignmentId, required String note}) async {
                                      await ref.read(taskServiceProvider).addPersonnelNote(assignmentId: assignmentId, note: note);
                                    },
                                    // ---------------------------------------
                                    onEditTask: (task) => _openEditTask(context, task, currentUserId),
                                    onConfirmDeleteTask: (task) => _deleteTask(context, ref, task),
                                    targetUserId: currentUserId ?? '',
                                    roomName: task.task.roomId == null
                                        ? null
                                        : (roomNamesById[task.task.roomId!] ?? task.task.roomId!),
                                  );
                                }),
                                if (index < groupedHistory.length - 1) const SizedBox(height: 20),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              // --- OVERLAY DI CARICAMENTO ---
              if (_isCopying)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.7),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF5A8B9E)),
                            const SizedBox(height: 16),
                            Text('Overwriting Week...', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF5A8B9E))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: _buildHeaderIcon(Icons.arrow_back_ios_new_rounded),
        ),
        
        Expanded(
          child: Column(
            children: [
              Text(
                'Week Tasks',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5A8B9E),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickWeek,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A8B9E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5A8B9E).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF5A8B9E)),
                      const SizedBox(width: 8),
                      Text(
                        _formatWeekRange(_selectedWeek),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A8B9E),
                        )
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF5A8B9E)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        GestureDetector(
          onTap: _handleCopyWeek,
          child: _buildHeaderIcon(Icons.content_copy_rounded),
        ),
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
        border: Border.all(color: accent.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: 22),
    );
  }

  Widget _buildDayHeader(DateTime day) {
    final weekday = DateFormat('EEEE').format(day);
    final fullDate = DateFormat('dd MMMM').format(day); 
    
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFFF4A261).withOpacity(0.15) : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isToday ? const Color(0xFFF4A261).withOpacity(0.3) : const Color(0xFF5A8B9E).withOpacity(0.16),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today' : weekday,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isToday ? const Color(0xFFF4A261) : const Color(0xFF3D342C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullDate,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D342C).withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              if (isToday)
                Icon(Icons.star_rounded, color: const Color(0xFFF4A261).withOpacity(0.8), size: 28),
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
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          "You're completely free this week! ✨",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D342C).withOpacity(0.7),
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
          color: const Color(0xFFF28482).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF28482).withOpacity(0.3),
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