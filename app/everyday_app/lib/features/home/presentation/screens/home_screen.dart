import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:everyday_app/features/tasks/presentation/providers/task_providers.dart';

const _homeBackground = Color(0xFFF4F1ED);
const _homeInk = Color(0xFF1F3A44);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTasksAsync = ref.watch(homeDailyTasksProvider);
    final now = DateTime.now();
    final currentWeek = DateTime(now.year, now.month, now.day);
    final weeklyTasksAsync = ref.watch(weeklyTasksFamilyProvider(currentWeek));
    final currentUserId = AppContext.instance.userId;

    return Scaffold(
      backgroundColor: _homeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 46, child: _buildHeader(context)),
              const SizedBox(height: 14),
              Expanded(
                child: _buildDailyTaskModule(
                  context,
                  dailyTasksAsync,
                  currentUserId,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _buildWeeklyTaskModule(
                  context,
                  weeklyTasksAsync,
                  currentUserId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER PREMIUM ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconBtn(
          Icons.calendar_today_outlined,
          () => _showCalendarPopup(context),
        ),

        Text(
          'Home',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _homeInk,
          ),
        ),

        _buildIconBtn(Icons.notifications_none_rounded, () {}),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 26,
          color: const Color(0xFF1F3A44),
        ),
      ),
    );
  }

  // --- MODULE: DAILY TASK ---
  Widget _buildDailyTaskModule(
    BuildContext context,
    AsyncValue<List<TaskWithDetails>> tasksAsync,
    String? currentUserId,
  ) {
    Future<void> openDailyTasks() async {
      await AppRouter.navigate<void>(
        context,
        AppRouteNames.dailyTask,
        arguments: DailyTaskRouteArgs(date: DateTime.now()),
      );
    }

    return tasksAsync.when(
      loading: () => _HomeDailyPreviewTile(
        completion: 0,
        previewItems: const [],
        emptyLabel: 'Loading your assignments...',
        onTap: openDailyTasks,
      ),
      error: (error, stackTrace) => _HomeDailyPreviewTile(
        completion: 0,
        previewItems: const [],
        emptyLabel: 'Unable to load assignments',
        onTap: openDailyTasks,
      ),
      data: (tasks) {
        final totalTasks = tasks.length;
        final previewItems = tasks
            .take(3)
            .map(
              (task) => _TaskPreviewItem(
                title: task.task.title,
                isCompleted: _isTaskCompletedForUser(task, currentUserId),
              ),
            )
            .toList(growable: false);
        final completedTasks = tasks
            .where((task) => _isTaskCompletedForUser(task, currentUserId))
            .length;
        final completion = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        return _HomeDailyPreviewTile(
          completion: completion,
          previewItems: previewItems,
          emptyLabel: "You're free today ✨",
          onTap: openDailyTasks,
        );
      },
    );
  }

  bool _isTaskCompletedForUser(TaskWithDetails task, String? currentUserId) {
    final ownAssignment = task.assignments
        .where((assignment) => assignment.member?.userId == currentUserId)
        .toList();
    final assignmentDone =
        ownAssignment.isNotEmpty &&
        ownAssignment.first.status.toUpperCase() == 'DONE';
    final subtasksDone =
        task.subtasks.isNotEmpty &&
        task.subtasks.every((subtask) => subtask.isDone);
    return assignmentDone || subtasksDone;
  }

  // --- MODULE: WEEKLY TASK ---
  Widget _buildWeeklyTaskModule(
    BuildContext context,
    AsyncValue<List<TaskWithDetails>> tasksAsync,
    String? currentUserId,
  ) {
    void openWeeklyTasks() {
      final memberId = (AppContext.instance.membershipId ?? '').trim();
      final userId = (currentUserId ?? '').trim();
      Navigator.of(context).pushNamed(
        AppRouteNames.weekTasks,
        arguments: WeekTasksRouteArgs(
          initialMemberId: memberId.isEmpty ? null : memberId,
          initialUserId: userId.isEmpty ? null : userId,
        ),
      );
    }

    return tasksAsync.when(
      loading: () => _HomeWeeklyPreviewTile(
        timelineItems: _buildWeeklyTimelineItems(
          const <TaskWithDetails>[],
          currentUserId,
        ),
        statusLabel: 'Loading upcoming tasks...',
        onTap: openWeeklyTasks,
      ),
      error: (error, stackTrace) => _HomeWeeklyPreviewTile(
        timelineItems: _buildWeeklyTimelineItems(
          const <TaskWithDetails>[],
          currentUserId,
        ),
        statusLabel: 'Unable to load weekly tasks',
        onTap: openWeeklyTasks,
      ),
      data: (tasks) {
        final timelineItems = _buildWeeklyTimelineItems(tasks, currentUserId);
        final nextTask = _findNextUpcomingWeeklyTask(tasks, currentUserId);
        final nextPreview = nextTask == null
            ? null
            : _NextWeeklyTaskPreviewData(
                title: nextTask.task.title,
                isCompleted: _isTaskCompletedForUser(nextTask, currentUserId),
              );

        String? statusLabel;
        if (nextPreview == null) {
          statusLabel = tasks.isEmpty
              ? 'No upcoming tasks this week'
              : 'All weekly tasks completed';
        }

        return _HomeWeeklyPreviewTile(
          timelineItems: timelineItems,
          nextTask: nextPreview,
          statusLabel: statusLabel,
          onTap: openWeeklyTasks,
        );
      },
    );
  }

  List<_WeeklyTimelineItem> _buildWeeklyTimelineItems(
    List<TaskWithDetails> tasks,
    String? currentUserId,
  ) {
    final totalsByWeekday = List<int>.filled(8, 0);
    final completedByWeekday = List<int>.filled(8, 0);

    for (final task in tasks) {
      final weekday = task.task.taskDate.weekday;
      if (weekday < DateTime.monday || weekday > DateTime.sunday) continue;

      totalsByWeekday[weekday] += 1;
      if (_isTaskCompletedForUser(task, currentUserId)) {
        completedByWeekday[weekday] += 1;
      }
    }

    return List<_WeeklyTimelineItem>.generate(7, (index) {
      final weekday = index + 1;
      final total = totalsByWeekday[weekday];
      final completed = completedByWeekday[weekday];

      if (total == 0) {
        return _WeeklyTimelineItem(
          label: _weekdayShortLabel(weekday),
          state: _WeeklyDayState.empty,
          pendingCount: 0,
        );
      }

      if (completed >= total) {
        return _WeeklyTimelineItem(
          label: _weekdayShortLabel(weekday),
          state: _WeeklyDayState.done,
          pendingCount: 0,
        );
      }

      return _WeeklyTimelineItem(
        label: _weekdayShortLabel(weekday),
        state: _WeeklyDayState.pending,
        pendingCount: total - completed,
      );
    }, growable: false);
  }

  TaskWithDetails? _findNextUpcomingWeeklyTask(
    List<TaskWithDetails> tasks,
    String? currentUserId,
  ) {
    final incomplete = tasks
        .where((task) => !_isTaskCompletedForUser(task, currentUserId))
        .toList(growable: false);
    if (incomplete.isEmpty) return null;

    final sorted = [...incomplete]
      ..sort(
        (a, b) => _scheduledMomentForTask(a).compareTo(
          _scheduledMomentForTask(b),
        ),
      );

    final now = DateTime.now();
    for (final task in sorted) {
      final scheduledAt = _scheduledMomentForTask(task);
      if (!scheduledAt.isBefore(now)) {
        return task;
      }
    }

    return sorted.first;
  }

  DateTime _scheduledMomentForTask(TaskWithDetails task) {
    final date = task.task.taskDate;
    final day = DateTime(date.year, date.month, date.day);
    final timeFrom = task.task.timeFrom;
    if (timeFrom == null || timeFrom.trim().isEmpty) {
      return day.add(const Duration(hours: 23, minutes: 59));
    }

    final parts = timeFrom.split(':');
    if (parts.length < 2) {
      return day.add(const Duration(hours: 23, minutes: 59));
    }

    final parsedHour = int.tryParse(parts[0]);
    final parsedMinute = int.tryParse(parts[1]);
    if (parsedHour == null || parsedMinute == null) {
      return day.add(const Duration(hours: 23, minutes: 59));
    }

    final hour = parsedHour < 0
        ? 0
        : (parsedHour > 23 ? 23 : parsedHour);
    final minute = parsedMinute < 0
        ? 0
        : (parsedMinute > 59 ? 59 : parsedMinute);

    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  String _weekdayShortLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
      default:
        return 'Sun';
    }
  }

}

class _TaskPreviewItem {
  final String title;
  final bool isCompleted;

  const _TaskPreviewItem({
    required this.title,
    required this.isCompleted,
  });
}

Widget _buildPreviewChip({
  required String title,
  required bool isDone,
  required Color containerColor,
}) {
  return Container(
    height: 42,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: containerColor.withOpacity(0.14),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          offset: const Offset(0, 8),
          blurRadius: 18,
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.10),
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: -2,
        ),
      ],
    ),
    child: Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: isDone
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white.withOpacity(0.95),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CardPreviewList extends StatelessWidget {
  final List<_TaskPreviewItem> items;
  final int maxRows;
  final String emptyLabel;
  final Color containerColor;

  const _CardPreviewList({
    required this.items,
    required this.maxRows,
    required this.emptyLabel,
    required this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    final cappedItems = items.take(maxRows).toList(growable: false);
    final previewTasks = cappedItems.take(3).toList();

    if (cappedItems.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          emptyLabel,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < previewTasks.length; i++) ...[
          _buildPreviewChip(
            title: previewTasks[i].title,
            isDone: previewTasks[i].isCompleted,
            containerColor: containerColor,
          ),
          if (i != previewTasks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HomeDailyPreviewTile extends StatelessWidget {
  final double completion;
  final List<_TaskPreviewItem> previewItems;
  final String emptyLabel;
  final VoidCallback onTap;

  const _HomeDailyPreviewTile({
    required this.completion,
    required this.previewItems,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedCompletion = completion.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF8FD14F),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(-6, -6),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8FD14F),
              Color(0xFF6BCB3C),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Tasks',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              _CardPreviewList(
                items: previewItems,
                maxRows: 3,
                emptyLabel: emptyLabel,
                containerColor: const Color(0xFF8FD14F),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        color: Colors.white.withOpacity(0.35),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: normalizedCompletion,
                            child: Container(
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(normalizedCompletion * 100).round()}%',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWeeklyPreviewTile extends StatelessWidget {
  final List<_WeeklyTimelineItem> timelineItems;
  final _NextWeeklyTaskPreviewData? nextTask;
  final String? statusLabel;
  final VoidCallback onTap;

  const _HomeWeeklyPreviewTile({
    required this.timelineItems,
    this.nextTask,
    this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF5ED0C4),
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5ED0C4),
              Color(0xFF43B8AD),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(-6, -6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Tasks',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _WeeklyTimelineRow(items: timelineItems),
                const SizedBox(height: 16),
                Text(
                  'Next',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.92),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (nextTask != null)
                  _NextWeeklyTaskPreview(task: nextTask!)
                else
                  SizedBox(
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
                          color: Colors.white.withOpacity(0.96),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _WeeklyDayState { empty, pending, done }

class _WeeklyTimelineItem {
  final String label;
  final int pendingCount;
  final _WeeklyDayState state;

  const _WeeklyTimelineItem({
    required this.label,
    required this.pendingCount,
    required this.state,
  });
}

class _NextWeeklyTaskPreviewData {
  final String title;
  final bool isCompleted;

  const _NextWeeklyTaskPreviewData({
    required this.title,
    required this.isCompleted,
  });
}

class _WeeklyTimelineRow extends StatelessWidget {
  final List<_WeeklyTimelineItem> items;

  const _WeeklyTimelineRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final safeItems = items.length >= 7
        ? items.take(7).toList(growable: false)
        : [
            ...items,
            ...List<_WeeklyTimelineItem>.generate(
              7 - items.length,
              (_) => const _WeeklyTimelineItem(
                label: '-',
                pendingCount: 0,
                state: _WeeklyDayState.empty,
              ),
            ),
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final pillWidth = (constraints.maxWidth / 7).clamp(28.0, 44.0).toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in safeItems)
              SizedBox(
                width: pillWidth,
                height: 56,
                child: _WeekdayPill(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _WeekdayPill extends StatefulWidget {
  final _WeeklyTimelineItem item;

  const _WeekdayPill({required this.item});

  @override
  State<_WeekdayPill> createState() => _WeekdayPillState();
}

class _WeekdayPillState extends State<_WeekdayPill> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    if (!mounted) return;
    setState(() {
      _scale = pressed ? 0.96 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.item.state;
    final isEmpty = state == _WeeklyDayState.empty;
    final isPending = state == _WeeklyDayState.pending;
    final isDone = state == _WeeklyDayState.done;

    final backgroundColor = isDone
        ? _homeInk
        : (isPending
              ? Colors.white.withOpacity(0.9)
              : Colors.white.withOpacity(0.25));
    final textColor = isDone
        ? Colors.white
        : (isPending ? _homeInk : _homeInk.withOpacity(0.7));

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPending
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.item.label,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              if (isDone)
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              else
                Text(
                  isEmpty ? '–' : '${widget.item.pendingCount}',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextWeeklyTaskPreview extends StatelessWidget {
  final _NextWeeklyTaskPreviewData task;

  const _NextWeeklyTaskPreview({required this.task});

  @override
  Widget build(BuildContext context) {
    return _buildPreviewChip(
      title: task.title,
      isDone: task.isCompleted,
      containerColor: const Color(0xFF5ED0C4),
    );
  }
}

// --- POPUP CALENDARIO STILE LIQUID GLASS ---
void _showCalendarPopup(BuildContext context) {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay = DateTime.now();

  final Color colorAzzurro = const Color(0xFF5A8B9E); 
  final Color colorOrange = const Color(0xFFF4A261); 

  showDialog(
    context: context,
    barrierColor: colorAzzurro.withOpacity(0.15), 
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), 
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85), 
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorAzzurro.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: focusedDay,
                      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: _buildCalNavBtn(
                          Icons.chevron_left_rounded,
                          colorAzzurro,
                        ),
                        rightChevronIcon: _buildCalNavBtn(
                          Icons.chevron_right_rounded,
                          colorAzzurro,
                        ),
                        titleTextStyle: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3D342C),
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: GoogleFonts.poppins(
                          color: colorOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        weekendStyle: GoogleFonts.poppins(
                          color: colorOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: GoogleFonts.poppins(
                          color: const Color(0xFF3D342C),
                          fontWeight: FontWeight.w600,
                        ),
                        weekendTextStyle: GoogleFonts.poppins(
                          color: const Color(0xFF3D342C),
                          fontWeight: FontWeight.w600,
                        ),
                        todayDecoration: BoxDecoration(
                          border: Border.all(
                            color: colorAzzurro.withOpacity(0.5),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: GoogleFonts.poppins(
                          color: colorAzzurro,
                          fontWeight: FontWeight.w800,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: colorAzzurro,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorAzzurro.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        markerDecoration: BoxDecoration(
                          color: colorOrange,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                      onDaySelected: (selected, focused) {
                        setDialogState(() {
                          selectedDay = selected;
                          focusedDay = focused;
                        });

                        final rootNavigator = Navigator.of(context);

                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (!rootNavigator.mounted) return;
                          rootNavigator.pop(); 
                          AppRouter.navigate<void>(
                            rootNavigator.context,
                            AppRouteNames.dailyTask,
                            arguments: DailyTaskRouteArgs(date: selected),
                          );
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Widget _buildCalNavBtn(IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: color.withOpacity(0.1)),
    ),
    child: Icon(icon, color: color, size: 24),
  );
}