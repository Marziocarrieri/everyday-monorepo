import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_task_preview_tile.dart';

enum WeeklyDayState { empty, pending, done }

class WeeklyTimelineItem {
  final String label;
  final int pendingCount;
  final WeeklyDayState state;

  const WeeklyTimelineItem({
    required this.label,
    required this.pendingCount,
    required this.state,
  });
}

class NextWeeklyTaskPreviewData {
  final String title;
  final bool isCompleted;

  const NextWeeklyTaskPreviewData({
    required this.title,
    required this.isCompleted,
  });
}

class HomeWeeklyModule extends StatelessWidget {
  final List<WeeklyTimelineItem> timelineItems;
  final NextWeeklyTaskPreviewData? nextTask;
  final String? statusLabel;
  final VoidCallback onTap;

  const HomeWeeklyModule({
    super.key,
    required this.timelineItems,
    this.nextTask,
    this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brightColor = Color(0xFF45B9A7);
    const darkColor = Color(0xFF1F7568);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brightColor, darkColor],
          ),
          boxShadow: [
            BoxShadow(
              color: brightColor.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (Senza icona calendario)
            Text(
              'Weekly Tasks',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // TIMELINE PILLS
            _WeeklyTimelineRow(items: timelineItems, themeColor: brightColor),

            const SizedBox(height: 16),
            Text(
              'Next',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),

            // --- FIX OVERFLOW & DESIGN ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: nextTask != null
                    ? HomeTaskPreviewTile(
                        title: nextTask!.title,
                        isCompleted: nextTask!.isCompleted,
                        variant: HomeTaskPreviewVariant
                            .daily, // ORA USA LO STESSO DESIGN DEL DAILY!
                        themeColor: brightColor,
                      )
                    : SizedBox(
                        height: 44,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            statusLabel ?? 'All weekly tasks completed',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.96),
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
}

class _WeeklyTimelineRow extends StatelessWidget {
  final List<WeeklyTimelineItem> items;
  final Color themeColor;

  const _WeeklyTimelineRow({required this.items, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final safeItems = items.length >= 7
        ? items.take(7).toList(growable: false)
        : [
            ...items,
            ...List<WeeklyTimelineItem>.generate(
              7 - items.length,
              (_) => const WeeklyTimelineItem(
                label: '-',
                pendingCount: 0,
                state: WeeklyDayState.empty,
              ),
            ),
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final pillWidth = (constraints.maxWidth / 7)
            .clamp(28.0, 44.0)
            .toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in safeItems)
              SizedBox(
                width: pillWidth,
                height: 56,
                child: _WeekdayPill(item: item, themeColor: themeColor),
              ),
          ],
        );
      },
    );
  }
}

class _WeekdayPill extends StatelessWidget {
  final WeeklyTimelineItem item;
  final Color themeColor;

  const _WeekdayPill({required this.item, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final isEmpty = item.state == WeeklyDayState.empty;
    final isPending = item.state == WeeklyDayState.pending;
    final isDone = item.state == WeeklyDayState.done;

    final backgroundColor = isDone
        ? Colors.white
        : (isPending
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1));

    final textColor = isDone
        ? themeColor
        : (isPending ? Colors.white : Colors.white.withValues(alpha: 0.5));

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          if (isDone)
            Icon(Icons.check_rounded, size: 14, color: themeColor)
          else
            Text(
              isEmpty ? '–' : '${item.pendingCount}',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}
