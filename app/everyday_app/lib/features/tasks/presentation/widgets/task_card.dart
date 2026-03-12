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
import 'task_subtask_list.dart';
import 'task_time_row.dart';

enum TaskInteractionMode {
  standard,
  readOnlyChecklist,
  supervisionHostReadOnlyChecklist,
}

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
  final TaskInteractionMode interactionMode;

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
    this.interactionMode = TaskInteractionMode.standard,
    this.roomName,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;
  bool _isEditingNote = false;
  String _savedNote = '';
  late final TextEditingController _noteController;

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
    return !_isAssignedToCurrentUser;
  }

  bool get _canEditNote {
    return !widget.readOnlyChecklist &&
        widget.interactionMode == TaskInteractionMode.standard;
  }

  bool get _canDeleteTask {
    return !widget.readOnlyChecklist &&
        widget.interactionMode == TaskInteractionMode.standard;
  }

  bool get _canEditTaskMetadata {
    if (widget.readOnlyChecklist) {
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
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);

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
        direction: !_canDeleteTask
            ? DismissDirection.none
            : DismissDirection.endToStart,
        confirmDismiss: !_canDeleteTask
            ? null
            : (_) async {
                return await widget.onConfirmDeleteTask(widget.taskWithDetails);
              },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF28482),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF28482).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // --- BOX INFERIORE ESPANSO (NOTE E SUBTASKS) ---
            if (_isExpanded)
              Container(
                margin: const EdgeInsets.only(top: 35),
                padding: const EdgeInsets.only(
                  top: 60,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (assignmentNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 14,
                              color: const Color(
                                0xFF3D342C,
                              ).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Assigned to: ${assignmentNames.join(', ')}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
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

                    if (subtasks.isNotEmpty)
                      TaskSubtaskList(
                        subtasks: subtasks,
                        statusColor: statusColor,
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

                    if (!taskHasSubtasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Use the circle on the main row to mark as done.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // --- SEZIONE NOTE PREMIUM ---
                    if (ownAssignment.isNotEmpty) ...[
                      const SizedBox(height: 8),

                      // Modalità Modifica Nota
                      if (_isEditingNote) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _noteController,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3D342C),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your note here...',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(
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
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.poppins(
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
                            onTap: !_canEditNote
                                ? null
                                : () {
                                    setState(() {
                                      _isEditingNote = true;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add a note',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
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
                              color: const Color(0xFFF8FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF3D342C,
                                ).withValues(alpha: 0.05),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.sticky_note_2_rounded,
                                  size: 18,
                                  color: statusColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _savedNote,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(
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
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      boxShadow: _isExpanded
                          ? []
                          : [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icona di Stato Sinistra
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Titolo, Tempo e Stanza
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.taskWithDetails.task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3D342C),
                                  decoration:
                                      (taskHasSubtasks
                                          ? isAllDone
                                          : isTaskAssignmentDone)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TaskTimeRow(timeRange: '$timeFrom - $timeTo'),
                              if (roomId != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
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

                        // --- CHECKBOX TONDA (Se non ci sono subtasks) ---
                        if (!taskHasSubtasks && ownAssignment.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6, left: 4),
                            child: GestureDetector(
                              onTap: _isChecklistReadOnly
                                  ? null
                                  : () {
                                      widget.onAssignmentToggle(
                                        assignmentId: ownAssignment.first.id,
                                        isDone: !isTaskAssignmentDone,
                                      );
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isTaskAssignmentDone
                                      ? statusColor
                                      : Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isTaskAssignmentDone
                                        ? statusColor
                                        : statusColor.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: isTaskAssignmentDone
                                      ? [
                                          BoxShadow(
                                            color: statusColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: isTaskAssignmentDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            ),
                          ),

                        // --- BOTTONE EDIT (MATITA) ---
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: !_canEditTaskMetadata
                                ? null
                                : () =>
                                      widget.onEditTask(widget.taskWithDetails),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: statusColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        // --- FRECCIA ESPANDI/RIDUCI ---
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
