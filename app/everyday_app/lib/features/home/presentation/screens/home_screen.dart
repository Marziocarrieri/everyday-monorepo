import 'dart:ui';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/features/home/presentation/widgets/home_daily_task_card.dart';
import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';
import 'package:everyday_app/features/tasks/domain/services/task_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService _taskService = TaskService();
  bool _isLoadingAssignedTasks = true;
  List<TaskWithDetails> _assignedTasks = const [];

  @override
  void initState() {
    super.initState();

    debugPrint("USER: ${AppContext.instance.userId}");
    debugPrint("HOUSEHOLD: ${AppContext.instance.householdId}");
    _loadAssignedTasks();
  }

  Future<void> _loadAssignedTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAssignedTasks = true;
    });

    try {
      final tasks = await _taskService.getTasksAssignedToCurrentMember();
      if (!mounted) return;
      setState(() {
        _assignedTasks = tasks;
      });
    } catch (error) {
      debugPrint('Error loading personal dashboard tasks: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAssignedTasks = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: _buildHeader(),
              ),
              const SizedBox(height: 40),
              _buildDailyTaskCard(), 
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAIButton(), 
    );
  }

  // --- HEADER PREMIUM ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // TASTO CALENDARIO COLLEGATO!
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
          )
        ),
        
        // Tasto Notifiche (da collegare in futuro)
        GestureDetector(
          onTap: () { /* Futura pagina notifiche */ },
          child: _buildIconBtn(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5A8B9E).withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A8B9E).withValues(alpha: 0.08), 
            blurRadius: 20, 
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5A8B9E), size: 22),
    );
  }

  // --- CARD PREMIUM ---
  Widget _buildDailyTaskCard() {
    final today = DateTime.now();
    final todaysTasks = _assignedTasks
        .where((task) => _isSameDay(task.task.taskDate, today))
        .toList();

    final totalTasks = todaysTasks.length;
    final membershipId = AppContext.instance.membershipId;
    final completedTasks = todaysTasks
        .where(
        (task) {
        final ownAssignment = task.assignments
          .where((assignment) => assignment.memberId == membershipId)
          .toList();
        final assignmentDone = ownAssignment.isNotEmpty &&
          ownAssignment.first.status.toUpperCase() == 'DONE';
        final subtasksDone = task.subtasks.isNotEmpty &&
          task.subtasks.every((subtask) => subtask.isDone);
        return assignmentDone || subtasksDone;
        },
        )
        .length;
    final completion = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    final subtitle = _isLoadingAssignedTasks
        ? 'Loading your assignments...'
        : totalTasks == 0
      ? "You're free today ✨"
            : '$totalTasks assigned task${totalTasks == 1 ? '' : 's'}';

    return HomeDailyTaskCard(
      totalTasks: totalTasks,
      completion: completion,
      subtitle: subtitle,
      onTap: () async {
        await AppRouter.navigate<void>(
          context,
          AppRouteNames.dailyTask,
          arguments: DailyTaskRouteArgs(
            date: DateTime.now(),
          ),
        );
        await _loadAssignedTasks();
      },
    );
  }
  // --- TASTO AI PREMIUM ---
  Widget _buildAIButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: 60, height: 60, 
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF4A261).withValues(alpha: 0.3), 
                Colors.white.withValues(alpha: 0.4)
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4A261).withValues(alpha: 0.15), 
                blurRadius: 20, 
                offset: const Offset(0, 10)
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Color(0xFF5A8B9E), size: 26),
            onPressed: () => debugPrint("AI Clicked"),
          ),
        ),
      ),
    );
  }
}

// --- POPUP CALENDARIO STILE LIQUID GLASS (Design coerente) ---
  void _showCalendarPopup(BuildContext context) {
    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay = DateTime.now();

    final Color colorAzzurro = const Color(0xFF5A8B9E); // Il tuo azzurro core
    final Color colorOrange = const Color(0xFFF4A261); // L'arancione del progresso card

    showDialog(
      context: context,
      barrierColor: colorAzzurro.withValues(alpha: 0.15), // Overlay azzurrino leggero
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Sfoca la Home dietro
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85), // Vetro bianco
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: colorAzzurro.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 15)
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- CALENDARIO ---
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                        
                        // --- HEADER STILE FIGMA + APP ---
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: _buildCalNavBtn(Icons.chevron_left_rounded, colorAzzurro),
                          rightChevronIcon: _buildCalNavBtn(Icons.chevron_right_rounded, colorAzzurro),
                          titleTextStyle: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.w800, 
                            color: const Color(0xFF3D342C)
                          ),
                        ),

                        // --- GIORNI SETTIMANA (Arancio come su Figma) ---
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: GoogleFonts.poppins(color: colorOrange, fontSize: 13, fontWeight: FontWeight.w700),
                          weekendStyle: GoogleFonts.poppins(color: colorOrange, fontSize: 13, fontWeight: FontWeight.w700),
                        ),

                        // --- STILE NUMERI E SELEZIONE ---
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontWeight: FontWeight.w600),
                          weekendTextStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C), fontWeight: FontWeight.w600),
                          
                          // Oggi (Solo un cerchio vuoto azzurro)
                          todayDecoration: BoxDecoration(
                            border: Border.all(color: colorAzzurro.withValues(alpha: 0.5), width: 2),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: GoogleFonts.poppins(color: colorAzzurro, fontWeight: FontWeight.w800),

                          // Selezionato (Pillola Azzurra con Ombra Glow)
                          selectedDecoration: BoxDecoration(
                            color: colorAzzurro,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: colorAzzurro.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ]
                          ),

                          // Pallino Task (Arancio come nella Home Card)
                          markerDecoration: BoxDecoration(color: colorOrange, shape: BoxShape.circle),
                          markersMaxCount: 1,
                        ),

                        // --- AZIONE AL CLICK ---
                        onDaySelected: (selected, focused) {
                          setDialogState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });

                          final rootNavigator = Navigator.of(context);

                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (!rootNavigator.mounted) return;
                            rootNavigator.pop(); // Chiude Popup
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

  // Helper per i tastini di navigazione del calendario
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