import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:everyday_app/features/tasks/presentation/providers/task_providers.dart';
import 'package:everyday_app/features/tasks/presentation/screens/add_task_screen.dart';
import 'package:everyday_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:everyday_app/features/tasks/presentation/widgets/task_delete_confirmation_dialog.dart';
import 'package:everyday_app/features/tasks/utils/task_creator_identity.dart';
import 'package:everyday_app/shared/widgets/main_tab_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const _weeklyInk = Color(0xFF1F3A44);
const _weeklyWarmGrey = Color(0xFF3D342C);
const _weeklyAccent = Color(0xFF78A7A3);
const _weeklyAccentDeep = Color(0xFF56817D);

enum WeekTasksViewMode { self, delegated }

class WeekTasksCapabilities {
  final bool canCreate;
  final bool canManage;
  final bool canCopy;
  final bool canUseChecklist;

  const WeekTasksCapabilities({
    required this.canCreate,
    required this.canManage,
    required this.canCopy,
    required this.canUseChecklist,
  });
}

class WeekTasksScreen extends ConsumerStatefulWidget {
  final WeekTasksViewMode viewMode;
  final String? targetMemberId;
  final String? targetUserId;
  final WeekTasksCapabilities? capabilityOverride;

  const WeekTasksScreen({
    super.key,
    this.viewMode = WeekTasksViewMode.self,
    this.targetMemberId,
    this.targetUserId,
    this.capabilityOverride,
  });

  @override
  ConsumerState<WeekTasksScreen> createState() => _WeekTasksScreenState();
}

class _WeekTasksScreenState extends ConsumerState<WeekTasksScreen> {
  DateTime _selectedWeek = DateTime.now();
  bool _isCopying = false;
  String? _pressedHeaderActionKey;

  bool get _isDelegatedMode => widget.viewMode == WeekTasksViewMode.delegated;

  String _normalizedRole() {
    final rawRole = (AppContext.instance.activeMembership?.role ?? '')
        .toUpperCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    return rawRole;
  }

  String? _resolveEffectiveTargetMemberId() {
    final delegatedMemberId = (widget.targetMemberId ?? '').trim();
    final selfMemberId = (AppContext.instance.membershipId ?? '').trim();
    final normalized = _isDelegatedMode
        ? delegatedMemberId
        : (selfMemberId.isNotEmpty ? selfMemberId : delegatedMemberId);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _resolveEffectiveTargetUserId() {
    final delegatedUserId = (widget.targetUserId ?? '').trim();
    final selfUserId = (AppContext.instance.userId ?? '').trim();
    final normalized = _isDelegatedMode
        ? delegatedUserId
        : (selfUserId.isNotEmpty ? selfUserId : delegatedUserId);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  WeekTasksCapabilities _resolveCapabilities() {
    final override = widget.capabilityOverride;
    if (override != null) {
      return override;
    }

    final role = _normalizedRole();
    if (_isDelegatedMode) {
      if (role == 'HOST') {
        return const WeekTasksCapabilities(
          canCreate: true,
          canManage: true,
          canCopy: true,
          canUseChecklist: false,
        );
      }

      return const WeekTasksCapabilities(
        canCreate: false,
        canManage: false,
        canCopy: false,
        canUseChecklist: false,
      );
    }

    if (role == 'HOST' || role == 'COHOST') {
      return const WeekTasksCapabilities(
        canCreate: true,
        canManage: true,
        canCopy: true,
        canUseChecklist: true,
      );
    }

    return const WeekTasksCapabilities(
      canCreate: false,
      canManage: false,
      canCopy: false,
      canUseChecklist: true,
    );
  }

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

  Future<void> _openEditTask(
    BuildContext context,
    TaskWithDetails task,
    String? effectiveTargetUserId,
    WeekTasksCapabilities capabilities,
  ) async {
    if (!capabilities.canManage) {
      return;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: task.task.taskDate,
        initialTask: task,
        preselectedAssigneeUserId: effectiveTargetUserId,
      ),
    );

    if (changed == true && context.mounted) {
      _showSnackBar('Task updated successfully');
    }
  }

  Future<bool> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    TaskWithDetails task, {
    required WeekTasksCapabilities capabilities,
    required String? effectiveTargetMemberId,
  }) async {
    if (!capabilities.canManage) {
      return false;
    }

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

    final deleteMemberId = _isDelegatedMode
        ? (effectiveTargetMemberId ?? '')
        : ((currentMemberId ?? '').trim());
    if (deleteMemberId.isEmpty) {
      return false;
    }

    try {
      await ref
          .read(taskServiceProvider)
          .removeTaskAssignment(taskId: task.task.id, memberId: deleteMemberId);
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<void> _openAddTask(
    BuildContext context, {
    required WeekTasksCapabilities capabilities,
    required String? effectiveTargetMemberId,
    required String? effectiveTargetUserId,
  }) async {
    if (!capabilities.canCreate) {
      return;
    }

    if (_isDelegatedMode &&
        (effectiveTargetMemberId == null || effectiveTargetMemberId.isEmpty)) {
      _showSnackBar('Unable to resolve delegated member', isError: true);
      return;
    }

    final initialAssigneeMemberIds =
        (effectiveTargetMemberId == null || effectiveTargetMemberId.isEmpty)
        ? null
        : <String>{effectiveTargetMemberId};

    final args = _isDelegatedMode
        ? AddTaskRouteArgs(
            initialDate: _selectedWeek,
            assignedMemberIds: <String>{effectiveTargetMemberId!},
            preselectedAssigneeUserId: effectiveTargetUserId,
            multiAssignMode: true,
          )
        : AddTaskRouteArgs(
            initialDate: _selectedWeek,
            assignedMemberIds: initialAssigneeMemberIds,
            preselectedAssigneeUserId: effectiveTargetUserId,
          );

    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRouteNames.addTask, arguments: args);

    if (changed == true && mounted) {
      _showSnackBar('Task saved successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFF28482) : _weeklyAccentDeep,
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
            colorScheme: const ColorScheme.light(primary: _weeklyAccentDeep),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedWeek = picked);
    }
  }

  // --- LOGICA DI COPIA SETTIMANA CON SOVRASCRITTURA ---
  Future<void> _handleCopyWeek({
    required WeekTasksCapabilities capabilities,
    required String? effectiveTargetMemberId,
  }) async {
    if (!capabilities.canCopy) {
      return;
    }

    if (_isDelegatedMode &&
        (effectiveTargetMemberId == null || effectiveTargetMemberId.isEmpty)) {
      _showSnackBar('Unable to resolve delegated member', isError: true);
      return;
    }

    final sourceDate = await showDatePicker(
      context: context,
      initialDate: _selectedWeek.subtract(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'SELECT SOURCE WEEK TO CLONE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _weeklyAccentDeep),
          ),
          child: child!,
        );
      },
    );

    if (sourceDate == null) return;
    if (!mounted) return;

    // POPUP DI PERICOLO ROSSO
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF28482).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF28482),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Overwrite Week?',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D342C),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'All existing tasks in the current week will be DELETED and replaced with the tasks from the week of ${DateFormat('MMM dd').format(sourceDate)}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3D342C).withValues(alpha: 0.6),
                  ),
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
                            border: Border.all(
                              color: const Color(
                                0xFF3D342C,
                              ).withValues(alpha: 0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFF3D342C,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF28482),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'Overwrite',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCopying = true);
    try {
      await ref
          .read(taskServiceProvider)
          .copyWeekTasks(
            sourceWeekDate: sourceDate,
            targetWeekDate: _selectedWeek,
            targetMemberId: _isDelegatedMode ? effectiveTargetMemberId : null,
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
    final capabilities = _resolveCapabilities();
    final effectiveTargetMemberId = _resolveEffectiveTargetMemberId();
    final effectiveTargetUserId = _resolveEffectiveTargetUserId();

    final tasksAsync = effectiveTargetMemberId == null
        ? const AsyncValue<List<TaskWithDetails>>.data([])
        : ref.watch(
            weeklyTasksByMemberFamilyProvider(
              WeeklyTasksByMemberQuery(
                selectedWeek: _selectedWeek,
                targetMemberId: effectiveTargetMemberId,
              ),
            ),
          );
    final roomsAsync = ref.watch(taskRoomsProvider);

    final roomNamesById = roomsAsync.maybeWhen(
      data: (rooms) => {for (final room in rooms) room.id: room.name},
      orElse: () => const <String, String>{},
    );

    return Scaffold(
      body: MainTabScreenBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 20.0,
                      bottom: 10.0,
                    ),
                    child: _buildHeader(
                      context,
                      capabilities: capabilities,
                      onCreateTask: () => _openAddTask(
                        context,
                        capabilities: capabilities,
                        effectiveTargetMemberId: effectiveTargetMemberId,
                        effectiveTargetUserId: effectiveTargetUserId,
                      ),
                      onCopyWeek: () => _handleCopyWeek(
                        capabilities: capabilities,
                        effectiveTargetMemberId: effectiveTargetMemberId,
                      ),
                    ),
                  ),
                  Expanded(
                    child: tasksAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: _weeklyAccentDeep,
                        ),
                      ),
                      error: (error, _) => _buildErrorState(error.toString()),
                      data: (tasks) {
                        final groupedHistory = _buildGroupedHistory(
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
                                const SizedBox(height: 6),
                                ...group.tasks.map((task) {
                                  return TaskCard(
                                    key: ValueKey('weekly_${task.task.id}'),
                                    taskWithDetails: task,
                                    // --- FIX PERFETTO PARAMETRI NOMINATI ---
                                    onSubtaskToggle:
                                        ({
                                          required String subtaskId,
                                          required bool isDone,
                                        }) async {
                                          if (!capabilities.canUseChecklist) {
                                            return;
                                          }
                                          await ref
                                              .read(taskServiceProvider)
                                              .setSubtaskDone(
                                                subtaskId: subtaskId,
                                                isDone: isDone,
                                              );
                                        },
                                    onAssignmentToggle:
                                        ({
                                          required String assignmentId,
                                          required bool isDone,
                                        }) async {
                                          if (!capabilities.canUseChecklist) {
                                            return;
                                          }
                                          final status = isDone
                                              ? 'DONE'
                                              : 'TODO';
                                          await ref
                                              .read(taskServiceProvider)
                                              .setAssignmentStatus(
                                                assignmentId: assignmentId,
                                                status: status,
                                              );
                                        },
                                    onSaveNote:
                                        ({
                                          required String assignmentId,
                                          required String note,
                                        }) async {
                                          await ref
                                              .read(taskServiceProvider)
                                              .addPersonnelNote(
                                                assignmentId: assignmentId,
                                                note: note,
                                              );
                                        },
                                    // ---------------------------------------
                                    onEditTask: (task) => _openEditTask(
                                      context,
                                      task,
                                      effectiveTargetUserId,
                                      capabilities,
                                    ),
                                    onConfirmDeleteTask: (task) => _deleteTask(
                                      context,
                                      ref,
                                      task,
                                      capabilities: capabilities,
                                      effectiveTargetMemberId:
                                          effectiveTargetMemberId,
                                    ),
                                    targetUserId: effectiveTargetUserId ?? '',
                                    interactionMode: _isDelegatedMode
                                        ? (capabilities.canManage
                                              ? TaskInteractionMode
                                                    .supervisionHostReadOnlyChecklist
                                              : TaskInteractionMode
                                                    .readOnlyChecklist)
                                        : TaskInteractionMode.standard,
                                    readOnlyChecklist:
                                        !capabilities.canUseChecklist,
                                    enableCreatorDeleteSwipe:
                                        capabilities.canManage,
                                    visualStyle:
                                        TaskCardVisualStyle.warmDailyGlass,
                                    roomName: task.task.roomId == null
                                        ? null
                                        : (roomNamesById[task.task.roomId!] ??
                                              task.task.roomId!),
                                  );
                                }),
                                if (index < groupedHistory.length - 1)
                                  const SizedBox(height: 14),
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
                    color: const Color(0xFFF4EBDD).withValues(alpha: 0.56),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.78),
                              Colors.white.withValues(alpha: 0.62),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.82),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _weeklyInk.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: _weeklyAccentDeep,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Overwriting Week...',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: _weeklyInk,
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
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required WeekTasksCapabilities capabilities,
    required VoidCallback onCreateTask,
    required VoidCallback onCopyWeek,
  }) {
    final hasActions = capabilities.canCopy || capabilities.canCreate;
    final headerHeight = hasActions ? 100.0 : 78.0;
    final rangeTopOffset = hasActions ? 40.0 : 38.0;

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _buildHeaderIconButton(
              actionKey: 'back_week',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
              iconSize: 24,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Week Tasks',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _weeklyInk,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: rangeTopOffset),
              child: _buildWeekRangeControl(),
            ),
          ),
          if (hasActions)
            Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (capabilities.canCreate)
                    _buildHeaderIconButton(
                      actionKey: 'create_week_task',
                      icon: Icons.add_rounded,
                      onTap: onCreateTask,
                      iconSize: 24,
                    ),
                  if (capabilities.canCopy && capabilities.canCreate)
                    const SizedBox(height: (28)),
                  if (capabilities.canCopy)
                    _buildHeaderTextAction(
                      actionKey: 'repeat_week',
                      icon: Icons.repeat_rounded,
                      label: 'Repeat',
                      onTap: onCopyWeek,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required String actionKey,
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 22,
  }) {
    final isPressed = _pressedHeaderActionKey == actionKey;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedHeaderActionKey = actionKey),
      onTapUp: (_) {
        if (_pressedHeaderActionKey == actionKey) {
          setState(() => _pressedHeaderActionKey = null);
        }
      },
      onTapCancel: () {
        if (_pressedHeaderActionKey == actionKey) {
          setState(() => _pressedHeaderActionKey = null);
        }
      },
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.97 : 1,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              icon,
              color: _weeklyInk.withValues(alpha: isPressed ? 0.64 : 0.94),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTextAction({
    required String actionKey,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedHeaderActionKey == actionKey;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedHeaderActionKey = actionKey),
      onTapUp: (_) {
        if (_pressedHeaderActionKey == actionKey) {
          setState(() => _pressedHeaderActionKey = null);
        }
      },
      onTapCancel: () {
        if (_pressedHeaderActionKey == actionKey) {
          setState(() => _pressedHeaderActionKey = null);
        }
      },
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.98 : 1,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: _weeklyInk.withValues(alpha: isPressed ? 0.66 : 0.9),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _weeklyInk.withValues(alpha: isPressed ? 0.66 : 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekRangeControl() {
    return GestureDetector(
      onTap: _pickWeek,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.24),
                  _weeklyAccent.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.36),
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 14,
                  color: _weeklyInk.withValues(alpha: 0.74),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatWeekRange(_selectedWeek),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _weeklyInk.withValues(alpha: 0.82),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: _weeklyInk.withValues(alpha: 0.74),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeader(DateTime day) {
    final weekday = DateFormat('EEEE').format(day);
    final fullDate = DateFormat('dd MMMM').format(day);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekday,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _weeklyInk,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            fullDate,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _weeklyWarmGrey.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.82),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _weeklyInk.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _weeklyAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 44,
                color: _weeklyAccentDeep.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Caught Up!',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _weeklyInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're completely free this week!",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _weeklyWarmGrey.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF28482).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF28482).withValues(alpha: 0.3),
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
                message,
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
    );
  }
}

class _HistoryDayGroup {
  final DateTime day;
  final List<TaskWithDetails> tasks;

  const _HistoryDayGroup({required this.day, required this.tasks});
}
