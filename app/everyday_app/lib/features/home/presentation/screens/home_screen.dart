import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/features/home/presentation/widgets/home_daily_task_card.dart';
import 'package:everyday_app/features/home/presentation/widgets/home_weekly_task_card.dart';
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
    final tasksAsync = ref.watch(homeDailyTasksProvider);
    final currentUserId = AppContext.instance.userId;
    
    final role = AppContext.instance.activeMembership?.role.toUpperCase() ?? '';
    final isCohostOrPersonnel = role == 'COHOST' || role == 'PERSONNEL';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48, child: _buildHeader(context)),
              const SizedBox(height: 40),
              
              // Card dei Task Giornalieri (Visibile a tutti)
              _buildDailyTaskCard(context, tasksAsync, currentUserId),
              
              const SizedBox(height: 20), // Spazio uniforme

              // Card Panoramica Settimanale
              HomeWeeklyTaskCard(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouteNames.weekTasks);
                },
              ),

              if (isCohostOrPersonnel) const SizedBox(height: 20), // Spazio uniforme
              
              // Card Family Hub (Visibile solo a Co-host e Personnel)
              if (isCohostOrPersonnel) _buildFamilyAccessCard(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAIButton(),
    );
  }

  // --- HEADER PREMIUM ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showCalendarPopup(context),
          child: _buildIconBtn(Icons.calendar_today_outlined),
        ),

        Text(
          'Home',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5A8B9E),
            letterSpacing: 0.5,
          ),
        ),

        GestureDetector(
          onTap: () {},
          child: _buildIconBtn(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF5A8B9E).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A8B9E).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5A8B9E), size: 22),
    );
  }

  // --- CARD PREMIUM TASK ---
  Widget _buildDailyTaskCard(
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
      loading: () => HomeDailyTaskCard(
        totalTasks: 0,
        completion: 0,
        subtitle: 'Loading your assignments...',
        onTap: openDailyTasks,
      ),
      error: (error, stackTrace) => HomeDailyTaskCard(
        totalTasks: 0,
        completion: 0,
        subtitle: 'Unable to load assignments',
        onTap: openDailyTasks,
      ),
      data: (tasks) {
        final totalTasks = tasks.length;
        final completedTasks = tasks.where((task) {
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
        }).length;
        final completion = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        final subtitle = totalTasks == 0
            ? "You're free today ✨"
            : '$totalTasks assigned task${totalTasks == 1 ? '' : 's'}';

        return HomeDailyTaskCard(
          totalTasks: totalTasks,
          completion: completion,
          subtitle: subtitle,
          onTap: openDailyTasks,
        );
      },
    );
  }

  // --- CARD: FAMILY HUB ---
  Widget _buildFamilyAccessCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AppRouteNames.cohostFamily);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            height: 110, 
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4A261).withOpacity(0.12), // Sfondo Arancio
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), 
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF4A261).withOpacity(0.08), 
                  blurRadius: 20, 
                  offset: const Offset(0, 10)
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54, height: 54, 
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05), 
                        blurRadius: 10, 
                        offset: const Offset(0, 4)
                      )
                    ]
                  ),
                  // Icona rimasta Azzurra
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF5A8B9E), size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Hub', 
                        style: GoogleFonts.poppins(
                          fontSize: 19, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF3D342C),
                          letterSpacing: -0.5, 
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage members & roles', 
                        style: GoogleFonts.poppins(
                          fontSize: 13, 
                          fontWeight: FontWeight.w500, 
                          color: const Color(0xFF3D342C).withOpacity(0.6),
                        )
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded, 
                  // --- MODIFICA: Freccina diventata BLU ---
                  color: const Color(0xFF5A8B9E).withOpacity(0.5), 
                  size: 32
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              Icons.lightbulb_outline,
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