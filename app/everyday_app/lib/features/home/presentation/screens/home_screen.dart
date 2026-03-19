import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:everyday_app/shared/widgets/main_tab_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:everyday_app/features/tasks/presentation/providers/task_providers.dart';

// --- IMPORT AGGIUNTO PER LEGGERE I DATI DELLA CASA ---
import 'package:everyday_app/core/providers/app_state_providers.dart';

// --- IMPORTIAMO I MODULI PULITI DALLA CARTELLA WIDGETS ---
import '../widgets/home_daily_module.dart';
import '../widgets/home_weekly_module.dart';

const _homeInk = Color(0xFF1F3A44);

// Fridge Keeping visual reference values reused for top-card sizing rhythm.
const _fridgeShortcutTileHeight = 46.0;
const _dailyCardReferenceHeight =
    (22.0 * 2) + 44.0 + 24.0 + (_fridgeShortcutTileHeight * 3) + (12.0 * 2);
const _weeklyCardCompactHeight = 224.0;
const _dashboardTopSpacing = 32.0;
const _dashboardCardsSpacing = 24.0;

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
      backgroundColor: Colors.transparent,
      body: MainTabScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passiamo "ref" all'header per fargli leggere i dati
                SizedBox(height: 46, child: _buildHeader(context, ref)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final targetTotalHeight =
                          _dashboardTopSpacing +
                          _dailyCardReferenceHeight +
                          _dashboardCardsSpacing +
                          _weeklyCardCompactHeight;
                      final scale = constraints.maxHeight < targetTotalHeight
                          ? constraints.maxHeight / targetTotalHeight
                          : 1.0;
                      final topSpacing = _dashboardTopSpacing * scale;
                      final dailyHeight = _dailyCardReferenceHeight * scale;
                      final cardsSpacing = _dashboardCardsSpacing * scale;
                      final weeklyHeight = _weeklyCardCompactHeight * scale;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: topSpacing),
                          SizedBox(
                            height: dailyHeight,
                            child: _buildDailyTaskLogic(
                              context,
                              dailyTasksAsync,
                              currentUserId,
                            ),
                          ),
                          SizedBox(height: cardsSpacing),
                          SizedBox(
                            height: weeklyHeight,
                            child: _buildWeeklyTaskLogic(
                              context,
                              weeklyTasksAsync,
                              currentUserId,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HEADER DINAMICO ---
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    // Leggiamo i dati della casa dal provider che mi hai inviato
    final householdAsync = ref.watch(currentHouseholdProvider);

    // Gestiamo lo stato di caricamento e i fallback in modo sicuro
    final String titleText = householdAsync.when(
      data: (household) => household?.name ?? 'My Space',
      loading: () => 'Loading...',
      error: (_, _) => 'My Space',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconBtn(
          Icons.calendar_today_outlined,
          () => _showCalendarPopup(context),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _homeInk,
              ),
            ),
          ),
        ),

        _buildIconBtn(
          Icons.settings_rounded,
          () =>
              AppRouter.navigate<void>(context, AppRouteNames.profileSettings),
        ),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 26, color: const Color(0xFF1F3A44)),
      ),
    );
  }

  // --- LOGICA E COLLEGAMENTO: DAILY MODULE ---
  Widget _buildDailyTaskLogic(
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
      loading: () => HomeDailyModule(
        completion: 0,
        previewItems: const [],
        emptyLabel: 'Loading your assignments...',
        onTap: openDailyTasks,
      ),
      error: (_, _) => HomeDailyModule(
        completion: 0,
        previewItems: const [],
        emptyLabel: 'Unable to load assignments',
        onTap: openDailyTasks,
      ),
      data: (tasks) {
        final totalTasks = tasks.length;
        final previewItems = tasks
            .map(
              (task) => HomeDailyPreviewItem(
                title: task.task.title,
                isCompleted: _isTaskCompletedForUser(task, currentUserId),
              ),
            )
            .toList();
        final completedTasks = tasks
            .where((task) => _isTaskCompletedForUser(task, currentUserId))
            .length;
        final completion = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        return HomeDailyModule(
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
        .where((a) => a.member?.userId == currentUserId)
        .toList();
    final assignmentDone =
        ownAssignment.isNotEmpty &&
        ownAssignment.first.status.toUpperCase() == 'DONE';
    final subtasksDone =
        task.subtasks.isNotEmpty && task.subtasks.every((s) => s.isDone);
    return assignmentDone || subtasksDone;
  }

  // --- LOGICA E COLLEGAMENTO: WEEKLY MODULE ---
  Widget _buildWeeklyTaskLogic(
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
      loading: () => HomeWeeklyModule(
        timelineItems: _buildWeeklyTimelineItems(const [], currentUserId),
        statusLabel: 'Loading upcoming tasks...',
        onTap: openWeeklyTasks,
      ),
      error: (_, _) => HomeWeeklyModule(
        timelineItems: _buildWeeklyTimelineItems(const [], currentUserId),
        statusLabel: 'Unable to load weekly tasks',
        onTap: openWeeklyTasks,
      ),
      data: (tasks) {
        final timelineItems = _buildWeeklyTimelineItems(tasks, currentUserId);
        final nextTask = _findNextUpcomingWeeklyTask(tasks, currentUserId);
        final nextPreview = nextTask == null
            ? null
            : NextWeeklyTaskPreviewData(
                title: nextTask.task.title,
                isCompleted: _isTaskCompletedForUser(nextTask, currentUserId),
              );

        String? statusLabel = nextPreview == null
            ? (tasks.isEmpty
                  ? 'No upcoming tasks this week'
                  : 'All weekly tasks completed')
            : null;
        return HomeWeeklyModule(
          timelineItems: timelineItems,
          nextTask: nextPreview,
          statusLabel: statusLabel,
          onTap: openWeeklyTasks,
        );
      },
    );
  }

  List<WeeklyTimelineItem> _buildWeeklyTimelineItems(
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

    return List<WeeklyTimelineItem>.generate(7, (index) {
      final weekday = index + 1;
      final total = totalsByWeekday[weekday];
      final completed = completedByWeekday[weekday];

      if (total == 0) {
        return WeeklyTimelineItem(
          label: _weekdayShortLabel(weekday),
          state: WeeklyDayState.empty,
          pendingCount: 0,
        );
      }
      if (completed >= total) {
        return WeeklyTimelineItem(
          label: _weekdayShortLabel(weekday),
          state: WeeklyDayState.done,
          pendingCount: 0,
        );
      }
      return WeeklyTimelineItem(
        label: _weekdayShortLabel(weekday),
        state: WeeklyDayState.pending,
        pendingCount: total - completed,
      );
    });
  }

  TaskWithDetails? _findNextUpcomingWeeklyTask(
    List<TaskWithDetails> tasks,
    String? currentUserId,
  ) {
    final incomplete = tasks
        .where((t) => !_isTaskCompletedForUser(t, currentUserId))
        .toList();
    if (incomplete.isEmpty) return null;
    incomplete.sort(
      (a, b) =>
          _scheduledMomentForTask(a).compareTo(_scheduledMomentForTask(b)),
    );

    final now = DateTime.now();
    for (final task in incomplete) {
      if (!_scheduledMomentForTask(task).isBefore(now)) return task;
    }
    return incomplete.first;
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

    return DateTime(
      day.year,
      day.month,
      day.day,
      parsedHour.clamp(0, 23),
      parsedMinute.clamp(0, 59),
    );
  }

  String _weekdayShortLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (weekday >= 1 && weekday <= 7) ? labels[weekday - 1] : 'Sun';
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
    barrierColor: colorAzzurro.withValues(alpha: 0.15),
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
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorAzzurro.withValues(alpha: 0.12),
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
                      selectedDayPredicate: (day) =>
                          isSameDay(selectedDay, day),
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
                            color: colorAzzurro.withValues(alpha: 0.5),
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
                              color: colorAzzurro.withValues(alpha: 0.3),
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
      border: Border.all(color: color.withValues(alpha: 0.1)),
    ),
    child: Icon(icon, color: color, size: 24),
  );
}
