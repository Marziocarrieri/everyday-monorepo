import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_completion_badge.dart';
import 'home_task_preview_tile.dart';

class HomeDailyPreviewItem {
  final String title;
  final bool isCompleted;

  const HomeDailyPreviewItem({
    required this.title,
    required this.isCompleted,
  });
}

class HomeDailyModule extends StatelessWidget {
  final double completion;
  final List<HomeDailyPreviewItem> previewItems;
  final String emptyLabel;
  final VoidCallback onTap;

  const HomeDailyModule({
    super.key,
    required this.completion,
    required this.previewItems,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF08A4B);
    const surfaceColor = Color(0xFFFFF3EB);
    final previewTasks = previewItems.take(3).toList(growable: false);
    final normalizedCompletion = completion.clamp(0.0, 1.0);

    final taskListPreview = previewTasks.isEmpty
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              emptyLabel,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D342C).withValues(alpha: 0.75),
              ),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < previewTasks.length; i++) ...[
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: HomeTaskPreviewTile(
                      title: previewTasks[i].title,
                      isCompleted: previewTasks[i].isCompleted,
                      accentColor: primaryColor,
                      variant: HomeTaskPreviewVariant.daily,
                    ),
                  ),
                ),
                if (i != previewTasks.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          );

    final progressRow = Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: primaryColor.withValues(alpha: 0.2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: normalizedCompletion,
                  child: Container(
                    color: primaryColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surfaceColor,
              const Color(0xFFFFF8F4),
            ],
          ),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Tasks',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D342C),
                  ),
                ),
                HomeCompletionBadge(
                  percent: (normalizedCompletion * 100).round(),
                  accentColor: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 18),
            taskListPreview,
            const SizedBox(height: 8),
            progressRow,
          ],
        ),
      ),
    );
  }
}
