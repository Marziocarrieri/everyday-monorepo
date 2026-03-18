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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTasksAsync = ref.watch(homeDailyTasksProvider);
    final weeklyTasksAsync = ref.watch(homeWeeklyTasksProvider);
    final currentUserId = AppContext.instance.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const headerHeight = 46.0;
              const topSpacing = 16.0;
              const betweenTiles = 20.0;
              final availableTilesHeight =
                  constraints.maxHeight - headerHeight - topSpacing - betweenTiles;
                final tileHeight = availableTilesHeight > 0
                  ? (availableTilesHeight / 2).clamp(0.0, 260.0)
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: headerHeight, child: _buildHeader(context)),
                  const SizedBox(height: topSpacing),
                  SizedBox(
                    height: tileHeight,
                    child: _buildDailyTaskModule(
                      context,
                      dailyTasksAsync,
                      currentUserId,
                    ),
                  ),
                  const SizedBox(height: betweenTiles),
                  SizedBox(
                    height: tileHeight,
                    child: _buildWeeklyTaskModule(context, weeklyTasksAsync),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildAIButton(),
    );
  }

  // --- HEADER PREMIUM ---
  Widget _buildHeader(BuildContext context) {
    const headerColor = Color(0xFF2F4858);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showCalendarPopup(context),
          child: _buildIconBtn(Icons.calendar_month_rounded),
        ),

        Text(
          'Home',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: headerColor,
            letterSpacing: 0.5,
          ),
        ),

        GestureDetector(
          onTap: () {},
          child: _buildIconBtn(Icons.notifications_rounded),
        ),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon) {
    const headerColor = Color(0xFF2F4858);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: headerColor.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: headerColor, size: 22),
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
              (task) => _DailyPreviewItem(
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
  ) {
    void openWeeklyTasks() {
      Navigator.of(context).pushNamed(AppRouteNames.weekTasks);
    }

    return tasksAsync.when(
      loading: () => _HomeWeeklyPreviewTile(
        previewTitles: const [],
        emptyLabel: 'Loading upcoming tasks...',
        onTap: openWeeklyTasks,
      ),
      error: (error, stackTrace) => _HomeWeeklyPreviewTile(
        previewTitles: const [],
        emptyLabel: 'Unable to load weekly tasks',
        onTap: openWeeklyTasks,
      ),
      data: (tasks) {
        final today = _toDay(DateTime.now());
        final upcomingTasks = tasks
            .where((task) => !_toDay(task.task.taskDate).isBefore(today))
            .toList()
          ..sort((left, right) {
            final dateCompare = left.task.taskDate.compareTo(right.task.taskDate);
            if (dateCompare != 0) return dateCompare;

            final leftTime = left.task.timeFrom;
            final rightTime = right.task.timeFrom;

            if (leftTime == null && rightTime == null) return 0;
            if (leftTime == null) return 1;
            if (rightTime == null) return -1;

            return leftTime.compareTo(rightTime);
          });

        return _HomeWeeklyPreviewTile(
          previewTitles: upcomingTasks
              .take(3)
              .map((task) => task.task.title)
              .toList(growable: false),
          emptyLabel: 'No upcoming tasks this week',
          onTap: openWeeklyTasks,
        );
      },
    );
  }

  DateTime _toDay(DateTime date) => DateTime(date.year, date.month, date.day);

  // --- TASTO AI PREMIUM ---
  Widget _buildAIButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF4A261).withOpacity(0.3),
                Colors.white.withOpacity(0.4),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A261).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF5A8B9E),
              size: 26,
            ),
            onPressed: () => debugPrint("AI Clicked"),
          ),
        ),
      ),
    );
  }
}

class _DailyPreviewItem {
  final String title;
  final bool isCompleted;

  const _DailyPreviewItem({
    required this.title,
    required this.isCompleted,
  });
}

class _HomeDailyPreviewTile extends StatelessWidget {
  final double completion;
  final List<_DailyPreviewItem> previewItems;
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
    const darkBlue = Color(0xFF2F4858);
    final normalizedCompletion = completion.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF08A5D),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF08A5D).withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF08A5D),
              Color(0xFFE07A4F),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Tasks',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(normalizedCompletion * 100).round()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: previewItems.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        emptyLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < previewItems.length && i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == previewItems.length - 1 || i == 2
                                  ? 0
                                  : 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 17,
                                  height: 17,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: previewItems[i].isCompleted
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.95),
                                      width: 1.6,
                                    ),
                                  ),
                                  child: previewItems[i].isCompleted
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 11,
                                          color: darkBlue,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    previewItems[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                color: Colors.white.withOpacity(0.28),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: normalizedCompletion,
                    child: Container(
                      color: Colors.white.withOpacity(0.94),
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

class _HomeWeeklyPreviewTile extends StatelessWidget {
  final List<String> previewTitles;
  final String emptyLabel;
  final VoidCallback onTap;

  const _HomeWeeklyPreviewTile({
    required this.previewTitles,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF2F4858);
    final limitedPreview = previewTitles.take(3).toList(growable: false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF7FB77E),
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7FB77E),
              Color(0xFF6FAF6E),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7FB77E).withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Tasks',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: limitedPreview.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        emptyLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < limitedPreview.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == limitedPreview.length - 1 ? 0 : 10,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7FB77E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      limitedPreview[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: darkBlue.withOpacity(0.92),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
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