import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/app_context.dart';
import '../../../../shared/utils/status_color_utils.dart';
import '../../data/models/task_with_details.dart';
import 'task_subtask_list.dart';
import 'task_time_row.dart';

class TaskCard extends StatefulWidget {
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

  const TaskCard({
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
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
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
    _noteController = TextEditingController(text: _savedNote);
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
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
                    if (subtasks.isNotEmpty)
                      TaskSubtaskList(
                        subtasks: subtasks,
                        statusColor: statusColor,
                        onToggle: (subtask) {
                          widget.onSubtaskToggle(
                            subtaskId: subtask.id,
                            isDone: !subtask.isDone,
                          );
                        },
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.6),
                        ],
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
                              TaskTimeRow(timeRange: '$timeFrom - $timeTo'),
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
