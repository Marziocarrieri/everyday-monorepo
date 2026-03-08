import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/subtask.dart';

class TaskSubtaskList extends StatelessWidget {
  final List<Subtask> subtasks;
  final Color statusColor;
  final ValueChanged<Subtask> onToggle;

  const TaskSubtaskList({
    super.key,
    required this.subtasks,
    required this.statusColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: subtasks
          .map(
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
                    onTap: () => onToggle(subtask),
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
          )
          .toList(),
    );
  }
}
