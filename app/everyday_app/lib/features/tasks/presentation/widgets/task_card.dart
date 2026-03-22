import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_context.dart';
import '../../../../shared/utils/status_color_utils.dart';
import '../../data/models/task_assignement.dart';
import '../../data/models/task_with_details.dart';
import '../../utils/task_creator_identity.dart';
import 'task_subtask_list.dart';
import 'task_time_row.dart';

enum TaskInteractionMode {
  standard,
  readOnlyChecklist,
  supervisionHostReadOnlyChecklist,
}

enum TaskCardVisualStyle { legacy, warmDailyGlass }

class TaskCard extends StatefulWidget {
  final TaskWithDetails taskWithDetails;
  final Future<void> Function({required String subtaskId, required bool isDone})
  onSubtaskToggle;
  final Future<void> Function({
    required String assignmentId,
    required bool isDone,
  })
  onAssignmentToggle;
  final Future<void> Function({
    required String assignmentId,
    required String note,
  })
  onSaveNote;
  final Future<void> Function(TaskWithDetails task) onEditTask;
  final Future<bool> Function(TaskWithDetails task) onConfirmDeleteTask;
  final String? roomName;
  final String targetUserId;
  final bool readOnlyChecklist;
  final bool enableCreatorDeleteSwipe;
  final TaskInteractionMode interactionMode;
  final TaskCardVisualStyle visualStyle;

  const TaskCard({
    super.key,
    required this.taskWithDetails,
    required this.onSubtaskToggle,
    required this.onAssignmentToggle,
    required this.onSaveNote,
    required this.onEditTask,
    required this.onConfirmDeleteTask,
    required this.targetUserId,
    this.readOnlyChecklist = false,
    this.enableCreatorDeleteSwipe = true,
    this.interactionMode = TaskInteractionMode.standard,
    this.visualStyle = TaskCardVisualStyle.legacy,
    this.roomName,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;
  bool _isEditingNote = false;
  bool _isCardPressed = false;
  String? _pressedActionKey;
  String _savedNote = '';
  late final TextEditingController _noteController;
  bool _didRestoreExpandedState = false;

  static const Color _warmInk = Color(0xFF1F3A44);
  static const Color _warmGrey = Color(0xFF3D342C);
  static const Color _dailyAccent = Color(0xFF78A7A3);
  static const double _addTileRadius = 22.0;

  bool get _isWarmDailyGlass =>
      widget.visualStyle == TaskCardVisualStyle.warmDailyGlass;

  String _subtaskSignature(TaskWithDetails taskWithDetails) {
    return taskWithDetails.subtasks
        .map((subtask) => '${subtask.id}:${subtask.isDone}')
        .join('|');
  }

  String get _expandedStorageId =>
      'task_card_expanded_${widget.taskWithDetails.task.id}';

  void _restoreExpandedState() {
    if (_didRestoreExpandedState) {
      return;
    }

    final storedValue = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _expandedStorageId);

    if (storedValue is bool) {
      _isExpanded = storedValue;
    }

    _didRestoreExpandedState = true;
  }

  void _persistExpandedState() {
    PageStorage.maybeOf(
      context,
    )?.writeState(context, _isExpanded, identifier: _expandedStorageId);
  }

  bool get _isAssignedToCurrentUser {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ??
        AppContext.instance.userId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    final assignedUserIds = widget.taskWithDetails.assignments
        .map((assignment) => assignment.member?.userId)
        .whereType<String>()
        .toSet();

    return assignedUserIds.contains(currentUserId);
  }

  bool get _isChecklistReadOnly {
    if (widget.readOnlyChecklist) {
      return true;
    }

    if (widget.interactionMode == TaskInteractionMode.readOnlyChecklist ||
        widget.interactionMode ==
            TaskInteractionMode.supervisionHostReadOnlyChecklist) {
      return true;
    }

    return !_isAssignedToCurrentUser;
  }

  bool get _canEditNote {
    return !widget.readOnlyChecklist &&
        widget.interactionMode == TaskInteractionMode.standard;
  }

  /// Returns true when the current user has ownership-based edit permission:
  /// - personnel can never edit
  /// - host can edit only tasks they created
  /// - cohost can edit only tasks they created and are self-assigned to
  bool get _canEditByPermission {
    final roleRaw = (AppContext.instance.activeMembership?.role ?? '')
        .toLowerCase();
    final role = roleRaw.replaceAll('_', '');
    if (role == 'personnel') return false;

    final membershipId = AppContext.instance.membershipId;
    final isCreator = isTaskCreatedByCurrentUser(
      taskCreatedBy: widget.taskWithDetails.task.createdBy,
      currentUserId: AppContext.instance.userId,
      currentMemberId: membershipId,
    );

    if (!isCreator) {
      return false;
    }

    if (role == 'cohost') {
      if (membershipId == null || membershipId.isEmpty) {
        return false;
      }

      return widget.taskWithDetails.assignments.any(
        (assignment) => assignment.memberId == membershipId,
      );
    }

    return true;
  }

  bool get _canEditTaskMetadata {
    if (widget.readOnlyChecklist) {
      return false;
    }
    if (!_canEditByPermission) {
      return false;
    }

    return widget.interactionMode == TaskInteractionMode.standard ||
        widget.interactionMode ==
            TaskInteractionMode.supervisionHostReadOnlyChecklist;
  }

  List<TaskAssignment> _targetAssignments() {
    return widget.taskWithDetails.assignments
        .where((assignment) => assignment.member?.userId == widget.targetUserId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final assignment = _targetAssignments();
    _savedNote = assignment.isNotEmpty
        ? (assignment.first.note ?? '').trim()
        : '';
    _noteController = TextEditingController(text: _savedNote);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restoreExpandedState();
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.taskWithDetails.task.id != widget.taskWithDetails.task.id) {
      _didRestoreExpandedState = false;
      _restoreExpandedState();
    }

    final oldSubtaskSignature = _subtaskSignature(oldWidget.taskWithDetails);
    final newSubtaskSignature = _subtaskSignature(widget.taskWithDetails);

    if (oldSubtaskSignature != newSubtaskSignature) {
      final storedValue = PageStorage.maybeOf(
        context,
      )?.readState(context, identifier: _expandedStorageId);
      if (storedValue is bool) {
        _isExpanded = storedValue;
      }

      setState(() {});
    }

    if (_isEditingNote) return;

    final assignment = _targetAssignments();

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

    if (kDebugMode) {
      final subtaskSignature = subtasks
          .map((subtask) => '${subtask.id}:${subtask.isDone ? 1 : 0}')
          .join('|');
      debugPrint(
        'TASK UI BUILD task_id=${widget.taskWithDetails.task.id} expanded=$_isExpanded subtasks=$subtaskSignature',
      );
    }

    final ownAssignment = widget.taskWithDetails.assignments
        .where((assignment) => assignment.member?.userId == widget.targetUserId)
        .toList();
    final ownAssignmentStatus = ownAssignment.isNotEmpty
        ? ownAssignment.first.status.toUpperCase()
        : 'TODO';
    final isTaskAssignmentDone = ownAssignmentStatus == 'DONE';
    final isCompleted = taskHasSubtasks ? isAllDone : isTaskAssignmentDone;

    final statusColor = isCompleted
        ? const Color(0xFF7A898D)
        : getStatusColor('safe');
    final cardAccent = _isWarmDailyGlass ? _dailyAccent : statusColor;
    final titleColor = _isWarmDailyGlass ? _warmInk : const Color(0xFF3D342C);
    final metadataColor = _isWarmDailyGlass
        ? _warmGrey.withValues(alpha: 0.62)
        : const Color(0xFF3D342C).withValues(alpha: 0.6);
    final iconTone = _isWarmDailyGlass
        ? _warmInk.withValues(alpha: 0.82)
        : cardAccent;
    final iconToneMuted = _isWarmDailyGlass
        ? _warmInk.withValues(alpha: 0.62)
        : cardAccent.withValues(alpha: 0.72);
    final headerRadius = _isWarmDailyGlass ? _addTileRadius : 30.0;
    final expandedRadius = _isWarmDailyGlass ? _addTileRadius : 28.0;

    final assignmentNames = widget.taskWithDetails.assignments
        .map((assignment) => assignment.member?.profile?.name)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();

    final timeFrom = _formatTaskTime(widget.taskWithDetails.task.timeFrom);
    final timeTo = _formatTaskTime(widget.taskWithDetails.task.timeTo);

    final roomId = widget.taskWithDetails.task.roomId;
    final roomLabel = widget.roomName;
    final normalizedTitle = widget.taskWithDetails.task.title.trim();
    final taskTitle = normalizedTitle.isEmpty
        ? 'Untitled task'
        : normalizedTitle;
    final isCreator = isTaskCreatedByCurrentUser(
      taskCreatedBy: widget.taskWithDetails.task.createdBy,
      currentUserId: AppContext.instance.userId,
      currentMemberId: AppContext.instance.membershipId,
    );
    final canSwipeDelete = isCreator && widget.enableCreatorDeleteSwipe;
    final dismissDirection = canSwipeDelete
        ? DismissDirection.endToStart
        : DismissDirection.none;
    final dismissibleKey = ValueKey(widget.taskWithDetails.task.id);

    final ancestorListView = context.findAncestorWidgetOfExactType<ListView>();
    final ancestorScrollable = context
        .findAncestorWidgetOfExactType<Scrollable>();
    final ancestorPageView = context.findAncestorWidgetOfExactType<PageView>();
    final ancestorGestureDetector = context
        .findAncestorWidgetOfExactType<GestureDetector>();

    if (kDebugMode) {
      debugPrint(
        'TASKCARD BUILD -> taskId: ${widget.taskWithDetails.task.id} | isCreator: $isCreator | dismissDirection: $dismissDirection',
      );
      debugPrint('Dismissible key hash -> ${dismissibleKey.hashCode}');
      debugPrint(
        'TASKCARD ANCESTRY -> widget: ${context.widget.runtimeType} | listView: ${ancestorListView?.runtimeType ?? 'null'} | scrollable: ${ancestorScrollable?.runtimeType ?? 'null'} | pageView: ${ancestorPageView?.runtimeType ?? 'null'} | gestureDetector: ${ancestorGestureDetector?.runtimeType ?? 'null'}',
      );
    }

    return Dismissible(
      key: dismissibleKey,
      direction: dismissDirection,
      confirmDismiss: canSwipeDelete
          ? (_) async {
              if (kDebugMode) {
                debugPrint(
                  'SWIPE CONFIRM TRIGGERED -> taskId: ${widget.taskWithDetails.task.id}',
                );
              }
              return await widget.onConfirmDeleteTask(widget.taskWithDetails);
            }
          : null,
      onDismissed: canSwipeDelete
          ? (_) {
              if (kDebugMode) {
                debugPrint(
                  'SWIPE DISMISSED -> taskId: ${widget.taskWithDetails.task.id}',
                );
              }
            }
          : null,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: _isWarmDailyGlass
              ? const Color(0xFFE08A86).withValues(alpha: 0.9)
              : Colors.redAccent,
          borderRadius: BorderRadius.circular(_isWarmDailyGlass ? 22 : 30),
          boxShadow: [
            BoxShadow(
              color:
                  (_isWarmDailyGlass
                          ? const Color(0xFFE08A86)
                          : Colors.redAccent)
                      .withValues(alpha: _isWarmDailyGlass ? 0.18 : 0.25),
              blurRadius: _isWarmDailyGlass ? 10 : 12,
              offset: Offset(0, _isWarmDailyGlass ? 3 : 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // --- BOX INFERIORE ESPANSO (NOTE E SUBTASKS) ---
            if (_isExpanded)
              Container(
                margin: EdgeInsets.only(top: _isWarmDailyGlass ? 28 : 35),
                padding: EdgeInsets.only(
                  top: _isWarmDailyGlass ? 52 : 60,
                  bottom: _isWarmDailyGlass ? 18 : 20,
                  left: _isWarmDailyGlass ? 18 : 20,
                  right: _isWarmDailyGlass ? 18 : 20,
                ),
                decoration: BoxDecoration(
                  gradient: _isWarmDailyGlass
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.24),
                            cardAccent.withValues(alpha: 0.11),
                          ],
                        )
                      : null,
                  color: _isWarmDailyGlass
                      ? null
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(expandedRadius),
                  border: Border.all(
                    color: _isWarmDailyGlass
                        ? Colors.white.withValues(alpha: 0.36)
                        : Colors.white,
                    width: _isWarmDailyGlass ? 1.2 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isWarmDailyGlass
                          ? cardAccent.withValues(alpha: 0.09)
                          : cardAccent.withValues(alpha: 0.1),
                      blurRadius: _isWarmDailyGlass ? 18 : 25,
                      offset: Offset(0, _isWarmDailyGlass ? 7 : 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (assignmentNames.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: _isWarmDailyGlass ? 14 : 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 14,
                              color: _isWarmDailyGlass
                                  ? iconToneMuted
                                  : const Color(
                                      0xFF3D342C,
                                    ).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Assigned to: ${assignmentNames.join(', ')}',
                                style:
                                    (_isWarmDailyGlass
                                    ? GoogleFonts.manrope
                                    : GoogleFonts.poppins)(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _isWarmDailyGlass
                                          ? metadataColor
                                          : const Color(
                                              0xFF3D342C,
                                            ).withValues(alpha: 0.6),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (subtasks.isNotEmpty) ...[
                      if (_isWarmDailyGlass)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Checklist',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: _warmGrey.withValues(alpha: 0.58),
                            ),
                          ),
                        ),
                      TaskSubtaskList(
                        key: ValueKey(
                          'task_subtasks_${widget.taskWithDetails.task.id}_${_subtaskSignature(widget.taskWithDetails)}',
                        ),
                        subtasks: subtasks,
                        statusColor: cardAccent,
                        warmStyle: _isWarmDailyGlass,
                        readOnly: _isChecklistReadOnly,
                        onToggle: (subtask) {
                          if (_isChecklistReadOnly) {
                            return;
                          }

                          widget.onSubtaskToggle(
                            subtaskId: subtask.id,
                            isDone: !subtask.isDone,
                          );
                        },
                      ),
                    ],

                    if (subtasks.isNotEmpty && ownAssignment.isNotEmpty)
                      SizedBox(height: _isWarmDailyGlass ? 2 : 8),

                    if (!taskHasSubtasks)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: _isWarmDailyGlass ? 14 : 16,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cardAccent.withValues(
                              alpha: _isWarmDailyGlass ? 0.08 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cardAccent.withValues(
                                alpha: _isWarmDailyGlass ? 0.18 : 0.1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: _isWarmDailyGlass
                                    ? iconToneMuted
                                    : cardAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Use the circle on the main row to mark as done.',
                                  style:
                                      (_isWarmDailyGlass
                                      ? GoogleFonts.manrope
                                      : GoogleFonts.poppins)(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: cardAccent.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // --- SEZIONE NOTE PREMIUM ---
                    if (ownAssignment.isNotEmpty) ...[
                      SizedBox(height: _isWarmDailyGlass ? 14 : 8),
                      if (_isWarmDailyGlass)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Notes',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: _warmGrey.withValues(alpha: 0.58),
                            ),
                          ),
                        ),

                      // Modalità Modifica Nota
                      if (_isEditingNote) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: _isWarmDailyGlass
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.24),
                                      cardAccent.withValues(alpha: 0.09),
                                    ],
                                  )
                                : null,
                            color: _isWarmDailyGlass ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isWarmDailyGlass
                                  ? Colors.white.withValues(alpha: 0.34)
                                  : cardAccent.withValues(alpha: 0.3),
                              width: _isWarmDailyGlass ? 1.1 : 1.5,
                            ),
                            boxShadow: _isWarmDailyGlass
                                ? const []
                                : [
                                    BoxShadow(
                                      color: statusColor.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: TextField(
                            controller: _noteController,
                            style:
                                (_isWarmDailyGlass
                                ? GoogleFonts.manrope
                                : GoogleFonts.poppins)(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _isWarmDailyGlass
                                      ? _warmInk
                                      : const Color(0xFF3D342C),
                                ),
                            decoration: InputDecoration(
                              hintText: 'Type your note here...',
                              hintStyle:
                                  (_isWarmDailyGlass
                                  ? GoogleFonts.manrope
                                  : GoogleFonts.poppins)(
                                    color: _isWarmDailyGlass
                                        ? metadataColor.withValues(alpha: 0.7)
                                        : const Color(
                                            0xFF3D342C,
                                          ).withValues(alpha: 0.4),
                                  ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (!_canEditNote) {
                                  return;
                                }

                                setState(() {
                                  _noteController.text = _savedNote;
                                  _isEditingNote = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Cancel',
                                  style:
                                      (_isWarmDailyGlass
                                      ? GoogleFonts.manrope
                                      : GoogleFonts.poppins)(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isWarmDailyGlass
                                            ? metadataColor
                                            : const Color(
                                                0xFF3D342C,
                                              ).withValues(alpha: 0.6),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: !_canEditNote
                                  ? null
                                  : () async {
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isWarmDailyGlass
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            cardAccent.withValues(alpha: 0.98),
                                            cardAccent.withValues(alpha: 0.86),
                                          ],
                                        )
                                      : null,
                                  color: _isWarmDailyGlass ? null : cardAccent,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cardAccent.withValues(
                                        alpha: _isWarmDailyGlass ? 0.16 : 0.3,
                                      ),
                                      blurRadius: _isWarmDailyGlass ? 6 : 8,
                                      offset: Offset(
                                        0,
                                        _isWarmDailyGlass ? 2 : 4,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Save',
                                  style:
                                      (_isWarmDailyGlass
                                      ? GoogleFonts.manrope
                                      : GoogleFonts.poppins)(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]
                      // Bottone "Aggiungi Nota" Premium (CENTRATO)
                      else if (_savedNote.isEmpty && _canEditNote)
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTapDown: (_) {
                              if (_isWarmDailyGlass && _canEditNote) {
                                setState(() => _pressedActionKey = 'note');
                              }
                            },
                            onTapUp: (_) {
                              if (_pressedActionKey == 'note') {
                                setState(() => _pressedActionKey = null);
                              }
                            },
                            onTapCancel: () {
                              if (_pressedActionKey == 'note') {
                                setState(() => _pressedActionKey = null);
                              }
                            },
                            onTap: !_canEditNote
                                ? null
                                : () {
                                    setState(() {
                                      _pressedActionKey = null;
                                      _isEditingNote = true;
                                    });
                                  },
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 110),
                              scale: _pressedActionKey == 'note' ? 0.97 : 1,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _isWarmDailyGlass
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: _pressedActionKey == 'note'
                                                  ? 0.34
                                                  : 0.28,
                                            ),
                                            cardAccent.withValues(
                                              alpha: _pressedActionKey == 'note'
                                                  ? 0.18
                                                  : 0.12,
                                            ),
                                          ],
                                        )
                                      : null,
                                  color: _isWarmDailyGlass
                                      ? null
                                      : cardAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isWarmDailyGlass
                                        ? Colors.white.withValues(alpha: 0.34)
                                        : cardAccent.withValues(alpha: 0.2),
                                    width: _isWarmDailyGlass ? 1.1 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: _isWarmDailyGlass
                                          ? iconTone
                                          : cardAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add a note',
                                      style:
                                          (_isWarmDailyGlass
                                          ? GoogleFonts.manrope
                                          : GoogleFonts.poppins)(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: cardAccent,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      // Nota Salvata (Cliccabile per modificare)
                      else if (_savedNote.isNotEmpty)
                        GestureDetector(
                          onTap: !_canEditNote
                              ? null
                              : () {
                                  setState(() {
                                    _isEditingNote = true;
                                    _noteController.text = _savedNote;
                                  });
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: _isWarmDailyGlass
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.22),
                                        cardAccent.withValues(alpha: 0.08),
                                      ],
                                    )
                                  : null,
                              color: _isWarmDailyGlass
                                  ? null
                                  : const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isWarmDailyGlass
                                    ? Colors.white.withValues(alpha: 0.34)
                                    : const Color(
                                        0xFF3D342C,
                                      ).withValues(alpha: 0.05),
                                width: _isWarmDailyGlass ? 1.1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_rounded,
                                  size: 18,
                                  color: _isWarmDailyGlass
                                      ? iconToneMuted
                                      : cardAccent.withValues(alpha: 0.72),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _savedNote,
                                    style:
                                        (_isWarmDailyGlass
                                        ? GoogleFonts.manrope
                                        : GoogleFonts.poppins)(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _isWarmDailyGlass
                                              ? _warmInk.withValues(alpha: 0.86)
                                              : const Color(
                                                  0xFF3D342C,
                                                ).withValues(alpha: 0.8),
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

            // --- HEADER DELLA CARD PRINCIPALE (Pillola In Alto) ---
            GestureDetector(
              onTapDown: (_) {
                if (_isWarmDailyGlass) {
                  setState(() => _isCardPressed = true);
                }
              },
              onTapUp: (_) {
                if (_isWarmDailyGlass && _isCardPressed) {
                  setState(() => _isCardPressed = false);
                }
              },
              onTapCancel: () {
                if (_isWarmDailyGlass && _isCardPressed) {
                  setState(() => _isCardPressed = false);
                }
              },
              onTap: () {
                setState(() {
                  _isCardPressed = false;
                  _isExpanded = !_isExpanded;
                });
                _persistExpandedState();
              },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: _isWarmDailyGlass && _isCardPressed ? 0.97 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(headerRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isWarmDailyGlass
                              ? [
                                  Colors.white.withValues(alpha: 0.24),
                                  cardAccent.withValues(
                                    alpha: _isCardPressed ? 0.16 : 0.12,
                                  ),
                                ]
                              : [
                                  statusColor.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.7),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(headerRadius),
                        border: Border.all(
                          color: _isWarmDailyGlass
                              ? Colors.white.withValues(alpha: 0.36)
                              : Colors.white.withValues(alpha: 0.9),
                          width: _isWarmDailyGlass ? 1.2 : 1.5,
                        ),
                        boxShadow: _isExpanded
                            ? []
                            : [
                                BoxShadow(
                                  color:
                                      (_isWarmDailyGlass
                                              ? cardAccent
                                              : statusColor)
                                          .withValues(
                                            alpha: _isWarmDailyGlass
                                                ? 0.1
                                                : 0.1,
                                          ),
                                  blurRadius: _isWarmDailyGlass ? 18 : 15,
                                  offset: Offset(0, _isWarmDailyGlass ? 6 : 8),
                                ),
                              ],
                      ),
                      child: Row(
                        crossAxisAlignment: _isWarmDailyGlass
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          _isWarmDailyGlass
                              ? _buildWarmLeadingState(
                                  taskHasSubtasks: taskHasSubtasks,
                                  ownAssignment: ownAssignment,
                                  isTaskAssignmentDone: isTaskAssignmentDone,
                                  isCompleted: isCompleted,
                                  cardAccent: cardAccent,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cardAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: cardAccent,
                                    size: 24,
                                  ),
                                ),
                          SizedBox(width: _isWarmDailyGlass ? 12 : 16),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  taskTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      (_isWarmDailyGlass
                                      ? GoogleFonts.manrope
                                      : GoogleFonts.poppins)(
                                        fontSize: _isWarmDailyGlass ? 17 : 17,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                ),
                                SizedBox(height: _isWarmDailyGlass ? 5 : 4),
                                if (_isWarmDailyGlass)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: _isWarmDailyGlass
                                            ? iconToneMuted
                                            : cardAccent.withValues(
                                                alpha: 0.62,
                                              ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: TaskTimeRow(
                                          timeRange: '$timeFrom - $timeTo',
                                          warmStyle: true,
                                          textColor: metadataColor,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  TaskTimeRow(timeRange: '$timeFrom - $timeTo'),
                                if (roomId != null || roomLabel != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: _isWarmDailyGlass ? 5 : 2,
                                    ),
                                    child: _isWarmDailyGlass
                                        ? Row(
                                            children: [
                                              Icon(
                                                Icons.place_rounded,
                                                size: 12,
                                                color: _isWarmDailyGlass
                                                    ? iconToneMuted
                                                    : cardAccent.withValues(
                                                        alpha: 0.6,
                                                      ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  roomLabel ?? 'Room assigned',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: metadataColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            '📍 ${roomLabel ?? 'Room assigned'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(
                                                0xFF3D342C,
                                              ).withValues(alpha: 0.6),
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          ),

                          if (!_isWarmDailyGlass &&
                              !taskHasSubtasks &&
                              ownAssignment.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 6, left: 4),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  if (_isWarmDailyGlass &&
                                      !_isChecklistReadOnly) {
                                    setState(() => _pressedActionKey = 'check');
                                  }
                                },
                                onTapUp: (_) {
                                  if (_pressedActionKey == 'check') {
                                    setState(() => _pressedActionKey = null);
                                  }
                                },
                                onTapCancel: () {
                                  if (_pressedActionKey == 'check') {
                                    setState(() => _pressedActionKey = null);
                                  }
                                },
                                onTap: _isChecklistReadOnly
                                    ? null
                                    : () {
                                        widget.onAssignmentToggle(
                                          assignmentId: ownAssignment.first.id,
                                          isDone: !isTaskAssignmentDone,
                                        );
                                      },
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 110),
                                  scale: _pressedActionKey == 'check'
                                      ? 0.97
                                      : 1,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: _isWarmDailyGlass ? 24 : 28,
                                    height: _isWarmDailyGlass ? 24 : 28,
                                    decoration: BoxDecoration(
                                      color: isTaskAssignmentDone
                                          ? cardAccent
                                          : (_isWarmDailyGlass
                                                ? Colors.white.withValues(
                                                    alpha: 0.34,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.5,
                                                  )),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isTaskAssignmentDone
                                            ? cardAccent
                                            : cardAccent.withValues(alpha: 0.3),
                                        width: _isWarmDailyGlass ? 1.6 : 2,
                                      ),
                                      boxShadow: isTaskAssignmentDone
                                          ? [
                                              BoxShadow(
                                                color: cardAccent.withValues(
                                                  alpha: _isWarmDailyGlass
                                                      ? 0.14
                                                      : 0.3,
                                                ),
                                                blurRadius: _isWarmDailyGlass
                                                    ? 5
                                                    : 8,
                                                offset: Offset(
                                                  0,
                                                  _isWarmDailyGlass ? 1 : 3,
                                                ),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: isTaskAssignmentDone
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 15,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),

                          if (_isWarmDailyGlass)
                            _buildWarmActionCluster(cardAccent: cardAccent)
                          else ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: !_canEditTaskMetadata
                                    ? null
                                    : () => widget.onEditTask(
                                        widget.taskWithDetails,
                                      ),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: cardAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: cardAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildWarmLeadingState({
    required bool taskHasSubtasks,
    required List<TaskAssignment> ownAssignment,
    required bool isTaskAssignmentDone,
    required bool isCompleted,
    required Color cardAccent,
  }) {
    final canToggle =
        !taskHasSubtasks && ownAssignment.isNotEmpty && !_isChecklistReadOnly;
    final isDone = taskHasSubtasks ? isCompleted : isTaskAssignmentDone;

    final indicator = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isDone
            ? cardAccent.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.34),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone
              ? cardAccent.withValues(alpha: 0.9)
              : cardAccent.withValues(alpha: 0.3),
          width: 1.4,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
          : null,
    );

    if (!canToggle) {
      return indicator;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedActionKey = 'check'),
      onTapUp: (_) {
        if (_pressedActionKey == 'check') {
          setState(() => _pressedActionKey = null);
        }
      },
      onTapCancel: () {
        if (_pressedActionKey == 'check') {
          setState(() => _pressedActionKey = null);
        }
      },
      onTap: () {
        widget.onAssignmentToggle(
          assignmentId: ownAssignment.first.id,
          isDone: !isTaskAssignmentDone,
        );
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressedActionKey == 'check' ? 0.97 : 1,
        child: indicator,
      ),
    );
  }

  Widget _buildWarmActionCluster({required Color cardAccent}) {
    final actionIconColor = _warmInk.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.26),
            cardAccent.withValues(alpha: 0.11),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.34),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (_) {
              if (_canEditTaskMetadata) {
                setState(() => _pressedActionKey = 'edit');
              }
            },
            onTapUp: (_) {
              if (_pressedActionKey == 'edit') {
                setState(() => _pressedActionKey = null);
              }
            },
            onTapCancel: () {
              if (_pressedActionKey == 'edit') {
                setState(() => _pressedActionKey = null);
              }
            },
            onTap: !_canEditTaskMetadata
                ? null
                : () => widget.onEditTask(widget.taskWithDetails),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 110),
              scale: _pressedActionKey == 'edit' ? 0.97 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Icon(
                  Icons.edit_rounded,
                  color: _canEditTaskMetadata
                      ? actionIconColor
                      : _warmInk.withValues(alpha: 0.34),
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 14,
            color: Colors.white.withValues(alpha: 0.34),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: actionIconColor,
              size: 18,
            ),
          ),
        ],
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
