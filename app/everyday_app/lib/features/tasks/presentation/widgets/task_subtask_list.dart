import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/subtask.dart';

class TaskSubtaskList extends StatelessWidget {
  final List<Subtask> subtasks;
  final Color statusColor;
  final ValueChanged<Subtask> onToggle;
  final bool readOnly;
  final bool warmStyle;

  const TaskSubtaskList({
    super.key,
    required this.subtasks,
    required this.statusColor,
    required this.onToggle,
    this.readOnly = false,
    this.warmStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!warmStyle) {
      return Column(
        children: subtasks
            .map((subtask) {
              return KeyedSubtree(
                key: ValueKey(
                  'subtask_${subtask.id}_${subtask.isDone ? 1 : 0}',
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtask.title.isEmpty
                              ? 'Untitled subtask'
                              : subtask.title,
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
                        onTap: readOnly ? null : () => onToggle(subtask),
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
              );
            })
            .toList(growable: false),
      );
    }

    return Column(
      children: subtasks
          .map((subtask) {
            final isDone = subtask.isDone;
            return KeyedSubtree(
              key: ValueKey('subtask_${subtask.id}_${subtask.isDone ? 1 : 0}'),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        statusColor.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtask.title.isEmpty
                              ? 'Untitled subtask'
                              : subtask.title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? const Color(0xFF3D342C).withValues(alpha: 0.5)
                                : const Color(0xFF1F3A44),
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: readOnly ? null : () => onToggle(subtask),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDone
                                ? statusColor.withValues(alpha: 0.88)
                                : Colors.white.withValues(alpha: 0.34),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone
                                  ? statusColor.withValues(alpha: 0.88)
                                  : statusColor.withValues(alpha: 0.28),
                              width: 1.4,
                            ),
                            boxShadow: isDone
                                ? [
                                    BoxShadow(
                                      color: statusColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
