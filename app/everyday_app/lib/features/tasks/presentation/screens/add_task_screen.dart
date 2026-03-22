import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:everyday_app/core/app_context.dart';
import '../../data/models/task_with_details.dart';
import '../../domain/services/task_service.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import 'package:everyday_app/shared/widgets/main_tab_screen_background.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/utils/status_color_utils.dart';
import '../providers/task_providers.dart';

const _addTaskInk = Color(0xFF1F3A44);
const _addTaskWarmGrey = Color(0xFF3D342C);
const _templateCategoryColors = <Color>[
  Color(0xFF78A7A3), // teal milk
  Color(0xFFD8AD90), // peach latte
  Color(0xFF6794AA), // blue steel
  Color(0xFFC0AF9E), // warm sand
  Color(0xFF8D79A6), // soft violet
  Color(0xFFC7A15A), // warm yellow
];

// ==========================================
// 1. SCHERMATA PRINCIPALE (LIBRERIA TASK)
// ==========================================
class AddTaskScreen extends StatefulWidget {
  final Set<String>? assignedMemberIds;
  final String? preselectedAssigneeUserId;
  final bool supervisionCreationMode;
  final bool multiAssignMode;
  final bool personalOnly;
  final TaskWithDetails? initialTask;
  final DateTime? initialDate;

  const AddTaskScreen({
    super.key,
    this.assignedMemberIds,
    this.preselectedAssigneeUserId,
    this.supervisionCreationMode = false,
    this.multiAssignMode = false,
    this.initialDate,
    this.personalOnly = false,
    this.initialTask,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _pressedTemplateKey;

  final Map<String, List<String>> _suggestedTasks = {
    'Daily Chores': [
      'Make the beds',
      'Wash dishes',
      'Load dishwasher',
      'Unload dishwasher',
      'Wipe kitchen counters',
      'Sweep the floors',
      'Take out the trash',
      'Tidy up the living room',
      'Sort the mail',
      'Set the table',
      'Clear the table',
    ],
    'Weekly Cleaning': [
      'Vacuum all rooms',
      'Mop the floors',
      'Clean the bathrooms',
      'Scrub the toilets',
      'Clean the mirrors',
      'Dust the furniture',
      'Change bed sheets',
      'Do the laundry (Colors)',
      'Do the laundry (Whites)',
      'Do the laundry (Delicates)',
      'Fold laundry',
      'Put away laundry',
      'Iron clothes',
      'Take out recycling',
    ],
    'Deep Cleaning & Seasonal': [
      'Defrost the freezer',
      'Clean the oven',
      'Wash the windows',
      'Wash the curtains',
      'Organize the pantry',
      'Organize the wardrobe',
      'Clean the carpets',
      'Clean the fridge',
      'Descale coffee maker',
      'Clean dishwasher filter',
    ],
    'Kitchen & Meals': [
      'Grocery shopping',
      'Order groceries online',
      'Plan weekly meals',
      'Meal prep',
      'Cook breakfast',
      'Cook lunch',
      'Cook dinner',
      'Bake a cake / dessert',
      'Check for expired food',
      'Buy fresh bread',
      'Restock water/beverages',
    ],
    'Kids Management': [
      'School Drop-off',
      'School Pick-up',
      'Pack school lunches',
      'Pack the backpack',
      'Homework help',
      'After-school activities',
      'Bathtime routine',
      'Bedtime routine',
      'Pediatrician check-up',
      'Buy school supplies',
      'Organize toys',
    ],
    'Pet Care': [
      'Walk the dog (Morning)',
      'Walk the dog (Evening)',
      'Feed the pets',
      'Clean the litter box',
      'Bathe the pet',
      'Vet appointment',
      'Buy pet food',
      'Brush the pet',
      'Wash pet bedding',
    ],
    'Home Maintenance & Car': [
      'Change lightbulbs',
      'Check smoke detectors',
      'Pay utility bills',
      'Pay condo fees',
      'Call the plumber/electrician',
      'Fix broken items',
      'Wash the car',
      'Clean the garage',
      'Refuel the car',
      'Schedule car service',
    ],
    'Garden & Outdoor': [
      'Water the plants (Indoor)',
      'Water the plants (Outdoor)',
      'Mow the lawn',
      'Rake leaves',
      'Clean the patio / balcony',
      'Take out the yard waste',
    ],
    'Personal & Health': [
      'Workout / Gym',
      'Doctor appointment',
      'Dentist appointment',
      'Buy medicines at pharmacy',
      'Haircut appointment',
      'Beauty/Spa appointment',
      'Meditate / Relax',
      'Read a book',
    ],
    'Admin & Organization': [
      'Pay taxes',
      'Renew insurance',
      'Review monthly budget',
      'File receipts / documents',
      'Backup computer/phone',
      'Plan family holidays',
      'Organize family calendar',
      'Call parents/relatives',
      'Buy a gift',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openTaskSheet(initialTitle: widget.initialTask!.task.title);
      });
    }
  }

  void _openTaskSheet({String? initialTitle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x2A3A271E),
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(
        initialTitle: initialTitle,
        assignedMemberIds: widget.assignedMemberIds,
        preselectedAssigneeUserId: widget.preselectedAssigneeUserId,
        supervisionCreationMode: widget.supervisionCreationMode,
        multiAssignMode: widget.multiAssignMode,
        personalOnly: widget.personalOnly,
        initialTask: widget.initialTask,
        initialDate: widget.initialDate,
        closeParentOnSave: true,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _categoryColorForGroup(String groupName) {
    final groupKeys = _suggestedTasks.keys.toList(growable: false);
    final index = groupKeys.indexOf(groupName);
    final safeIndex = index < 0 ? 0 : index;
    return _templateCategoryColors[safeIndex % _templateCategoryColors.length];
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGICA DI FILTRAGGIO RICERCA ---
    final query = _searchController.text.trim().toLowerCase();

    final filteredEntries = _suggestedTasks.entries
        .map((entry) {
          final matchedTasks = entry.value
              .where((task) => task.toLowerCase().contains(query))
              .toList();
          return MapEntry(entry.key, matchedTasks);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MainTabScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER PREMIUM ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.transparent,
                            alignment: Alignment.centerLeft,
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _addTaskInk,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Add a Task',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _addTaskInk,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _openTaskSheet(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: _addTaskInk,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- BARRA DI RICERCA GLASS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _addTaskInk.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: _addTaskInk.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.7),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Search templates...',
                                  hintStyle: GoogleFonts.manrope(
                                    color: _addTaskWarmGrey.withOpacity(0.45),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: GoogleFonts.manrope(
                                  color: _addTaskInk,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.search_rounded,
                              color: _addTaskInk.withOpacity(0.4),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- LISTA DELLE CATEGORIE ---
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: filteredEntries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Center(
                            child: Text(
                              'No templates found',
                              style: GoogleFonts.manrope(
                                color: _addTaskWarmGrey.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: filteredEntries.map((entry) {
                            final categoryColor = _categoryColorForGroup(
                              entry.key,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 30.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _addTaskWarmGrey.withOpacity(0.66),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...entry.value.map(
                                    (taskName) => _buildSuggestionPill(
                                      taskName,
                                      categoryColor,
                                      '${entry.key}|$taskName',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionPill(
    String taskName,
    Color categoryColor,
    String tileKey,
  ) {
    final isPressed = _pressedTemplateKey == tileKey;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedTemplateKey = tileKey),
      onTapUp: (_) {
        if (_pressedTemplateKey == tileKey) {
          setState(() => _pressedTemplateKey = null);
        }
      },
      onTapCancel: () {
        if (_pressedTemplateKey == tileKey) {
          setState(() => _pressedTemplateKey = null);
        }
      },
      onTap: () => _openTaskSheet(initialTitle: taskName),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.14),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isPressed)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor.withOpacity(0.28),
                          categoryColor.withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _templateIconForTask(taskName),
                        color: categoryColor.withOpacity(0.93),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        taskName,
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _addTaskInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _templateIconForTask(String taskName) {
    final normalized = taskName.toLowerCase();

    if (normalized.contains('bed')) return Icons.bed_outlined;
    if (normalized.contains('dish') ||
        normalized.contains('cook') ||
        normalized.contains('meal') ||
        normalized.contains('bread')) {
      return Icons.restaurant_outlined;
    }
    if (normalized.contains('laundry') || normalized.contains('iron')) {
      return Icons.local_laundry_service_outlined;
    }
    if (normalized.contains('trash') ||
        normalized.contains('recycling') ||
        normalized.contains('yard waste')) {
      return Icons.delete_outline_rounded;
    }
    if (normalized.contains('sweep') ||
        normalized.contains('vacuum') ||
        normalized.contains('mop') ||
        normalized.contains('clean')) {
      return Icons.cleaning_services_outlined;
    }
    if (normalized.contains('pet') ||
        normalized.contains('dog') ||
        normalized.contains('vet') ||
        normalized.contains('litter')) {
      return Icons.pets_outlined;
    }
    if (normalized.contains('school') ||
        normalized.contains('homework') ||
        normalized.contains('backpack')) {
      return Icons.school_outlined;
    }
    if (normalized.contains('doctor') ||
        normalized.contains('dentist') ||
        normalized.contains('pharmacy') ||
        normalized.contains('health')) {
      return Icons.medical_services_outlined;
    }
    if (normalized.contains('car') ||
        normalized.contains('garage') ||
        normalized.contains('refuel') ||
        normalized.contains('service')) {
      return Icons.directions_car_outlined;
    }
    if (normalized.contains('plant') ||
        normalized.contains('garden') ||
        normalized.contains('lawn')) {
      return Icons.local_florist_outlined;
    }
    if (normalized.contains('tax') ||
        normalized.contains('insurance') ||
        normalized.contains('budget') ||
        normalized.contains('document') ||
        normalized.contains('bill')) {
      return Icons.receipt_long_outlined;
    }
    return Icons.home_outlined;
  }
}

// ==========================================
// 2. BOTTOM SHEET AGGIORNATO (DESIGN PREMIUM)
// ==========================================
class AddTaskSheet extends ConsumerStatefulWidget {
  final String? initialTitle;
  final Set<String>? assignedMemberIds;
  final String? preselectedAssigneeUserId;
  final bool supervisionCreationMode;
  final bool multiAssignMode;
  final bool personalOnly;
  final TaskWithDetails? initialTask;
  final DateTime? initialDate;
  final bool closeParentOnSave;

  const AddTaskSheet({
    super.key,
    this.initialTitle,
    this.assignedMemberIds,
    this.preselectedAssigneeUserId,
    this.supervisionCreationMode = false,
    this.multiAssignMode = false,
    this.initialDate,
    this.personalOnly = false,
    this.initialTask,
    this.closeParentOnSave = false,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _titleController;
  final List<_ChecklistDraft> _checklistItems = [_ChecklistDraft()];
  TaskService get _taskService => ref.read(taskServiceProvider);

  DateTime? _selectedDate;
  DateTime? _startTime;
  DateTime? _endTime;
  List<HouseholdRoom> _rooms = const [];
  bool _isLoadingRooms = false;
  bool _isLoadingAccess = false;
  bool _isSaving = false;
  String? _selectedRoomId;
  TaskCreationAccess? _creationAccess;
  final Set<String> _selectedMemberIds = <String>{};

  // --- VARIAIBILE PER LA RIPETIZIONE MENSILE ---
  bool _repeatWeeklyInMonth = false;
  String? _pressedActionKey;

  static const Color _sheetAccent = Color(0xFF78A7A3);
  static const Color _sheetAccentDeep = Color(0xFF5F8EA4);
  static const Color _sheetAccentPrimary = _sheetAccentDeep;
  static const Color _sheetDanger = Color(0xFFE08A86);

  final Color colorOrange = _sheetAccentPrimary;
  final Color colorRed = _sheetDanger;

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    final now = DateTime.now();
    final localToday = DateTime(now.year, now.month, now.day);
    _titleController = TextEditingController(
      text: initialTask?.task.title ?? widget.initialTitle ?? '',
    );
    _selectedDate =
        initialTask?.task.taskDate ?? widget.initialDate ?? localToday;

    if (initialTask != null) {
      _selectedRoomId = initialTask.task.roomId;
      _startTime = _parseTaskTime(initialTask.task.timeFrom);
      _endTime = _parseTaskTime(initialTask.task.timeTo);

      _checklistItems.clear();
      if (initialTask.subtasks.isEmpty) {
        _checklistItems.add(_ChecklistDraft());
      } else {
        for (final subtask in initialTask.subtasks) {
          _checklistItems.add(_ChecklistDraft(text: subtask.title));
        }
      }
    }

    _loadRooms();
    _loadCreationAccess();
  }

  // --- Premium SnackBar Helper ---
  void _showPremiumSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorRed : getStatusColor('safe'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  DateTime? _parseTaskTime(String? timeValue) {
    if (timeValue == null || timeValue.isEmpty) return null;
    final chunks = timeValue.split(':');
    if (chunks.length < 2) return null;

    final hour = int.tryParse(chunks[0]);
    final minute = int.tryParse(chunks[1]);
    if (hour == null || minute == null) return null;

    final baseDate = _selectedDate ?? DateTime.now();
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
    });

    try {
      final rooms = await _taskService.getAvailableRooms();
      if (!mounted) return;

      setState(() {
        _rooms = rooms;
        if (_selectedRoomId != null &&
            _rooms.every((room) => room.id != _selectedRoomId)) {
          _selectedRoomId = null;
        }
      });
    } catch (error) {
      debugPrint('Error loading task rooms: $error');
      if (!mounted) return;
      setState(() {
        _rooms = const [];
        _selectedRoomId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
      }
    }
  }

  void _addSubTask() {
    setState(() => _checklistItems.add(_ChecklistDraft()));
  }

  void _removeSubTask(int index) {
    setState(() {
      _checklistItems[index].controller.dispose();
      _checklistItems.removeAt(index);
    });
  }

  Future<void> _loadCreationAccess() async {
    setState(() {
      _isLoadingAccess = true;
    });

    final access = await _taskService.getTaskCreationAccess();
    if (!mounted) return;

    setState(() {
      _creationAccess = access;
      _selectedMemberIds.clear();

      final preselectedAssigneeUserId = widget.preselectedAssigneeUserId;

      if (widget.supervisionCreationMode) {
        if (preselectedAssigneeUserId != null &&
            preselectedAssigneeUserId.isNotEmpty) {
          for (final member in access.assignableMembers) {
            if (member.userId == preselectedAssigneeUserId) {
              _selectedMemberIds.add(member.id);
              break;
            }
          }
        }

        _isLoadingAccess = false;
        return;
      }

      if (widget.multiAssignMode) {
        final initialSet = widget.assignedMemberIds;
        if (initialSet != null && initialSet.isNotEmpty) {
          for (final member in access.assignableMembers) {
            if (initialSet.contains(member.id)) {
              _selectedMemberIds.add(member.id);
            }
          }
        }

        _isLoadingAccess = false;
        return;
      }

      if (preselectedAssigneeUserId != null &&
          preselectedAssigneeUserId.isNotEmpty) {
        for (final member in access.assignableMembers) {
          if (member.userId == preselectedAssigneeUserId) {
            _selectedMemberIds.add(member.id);
          }
        }
      }

      if (access.canAssignMultiple) {
        final initialSet = widget.assignedMemberIds;
        if (_selectedMemberIds.isEmpty &&
            initialSet != null &&
            initialSet.isNotEmpty) {
          for (final member in access.assignableMembers) {
            if (initialSet.contains(member.id)) {
              _selectedMemberIds.add(member.id);
            }
          }
        }
      } else if (access.assignableMembers.isNotEmpty) {
        if (_selectedMemberIds.isEmpty) {
          _selectedMemberIds.add(access.assignableMembers.first.id);
        }
      }

      if (widget.personalOnly && access.assignableMembers.isNotEmpty) {
        final currentMembershipId = AppContext.instance.membershipId;
        String? fallbackMembershipId;

        for (final member in access.assignableMembers) {
          if (member.id == currentMembershipId) {
            fallbackMembershipId = member.id;
            break;
          }
        }

        _selectedMemberIds
          ..clear()
          ..add(fallbackMembershipId ?? access.assignableMembers.first.id);
      }

      _isLoadingAccess = false;
    });
  }

  Future<void> _submitTask() async {
    final access = _creationAccess;
    if (access == null || !access.canCreate) {
      _showPremiumSnackBar('You are not allowed to create tasks');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showPremiumSnackBar('Task name is required');
      return;
    }

    final targetDate = _selectedDate ?? DateTime.now();

    final checklistTitles = _checklistItems
        .map((item) => item.controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final memberIds = widget.personalOnly
        ? const <String>[]
        : widget.supervisionCreationMode
        ? _selectedMemberIds.toList()
        : access.canAssignMultiple
        ? _selectedMemberIds.toList()
        : access.assignableMembers.map((member) => member.id).toList();

    if (widget.supervisionCreationMode && memberIds.length != 1) {
      _showPremiumSnackBar('Unable to resolve supervised assignee');
      return;
    }

    if (!widget.personalOnly && memberIds.isEmpty) {
      _showPremiumSnackBar('Select at least one assignee');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final editingTask = widget.initialTask;

      if (editingTask == null) {
        // --- CREAZIONE ---
        List<DateTime> datesToCreate = [];

        if (_repeatWeeklyInMonth) {
          final year = targetDate.year;
          final month = targetDate.month;
          final weekday = targetDate.weekday;

          final daysInMonth = DateTime(year, month + 1, 0).day;

          for (int i = 1; i <= daysInMonth; i++) {
            final d = DateTime(year, month, i);
            if (d.weekday == weekday) {
              datesToCreate.add(d);
            }
          }
        } else {
          datesToCreate.add(targetDate);
        }

        for (final date in datesToCreate) {
          await _taskService.createTaskWithDetails(
            title: title,
            date: date,
            timeFrom: _startTime != null
                ? TimeOfDay.fromDateTime(_startTime!)
                : null,
            timeTo: _endTime != null ? TimeOfDay.fromDateTime(_endTime!) : null,
            visibility: 'ALL',
            roomId: _selectedRoomId,
            assignedMemberIds: memberIds,
            checklistTitles: checklistTitles,
            personalOnly: widget.personalOnly,
          );
        }
      } else {
        // --- AGGIORNAMENTO ---
        await _taskService.updateTaskWithDetails(
          taskId: editingTask.task.id,
          title: title,
          date: targetDate,
          timeFrom: _startTime != null
              ? TimeOfDay.fromDateTime(_startTime!)
              : null,
          timeTo: _endTime != null ? TimeOfDay.fromDateTime(_endTime!) : null,
          visibility: editingTask.task.visibility,
          roomId: _selectedRoomId,
          checklistTitles: checklistTitles,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      if (widget.closeParentOnSave && mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      debugPrint('Error creating task: $error');
      _showPremiumSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --- Picker Customizzati Date/Time ---
  void _showIOSPicker({
    required Widget child,
    required VoidCallback onConfirm,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF4EDE3).withOpacity(0.97),
              const Color(0xFFE7DCCF).withOpacity(0.94),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.78), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _addTaskInk.withOpacity(0.16),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _addTaskInk.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(
                          color: _addTaskWarmGrey.withOpacity(0.72),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: Text(
                        'Done',
                        style: GoogleFonts.manrope(
                          color: _sheetAccentDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        onConfirm();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDate() {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    _showIOSPicker(
      child: CupertinoDatePicker(
        initialDateTime: tempDate,
        mode: CupertinoDatePickerMode.date,
        onDateTimeChanged: (newDate) => tempDate = newDate,
      ),
      onConfirm: () => setState(() => _selectedDate = tempDate),
    );
  }

  void _selectTime(bool isStart) {
    DateTime tempTime = isStart
        ? (_startTime ?? DateTime.now())
        : (_endTime ?? DateTime.now().add(const Duration(hours: 1)));
    _showIOSPicker(
      child: CupertinoDatePicker(
        initialDateTime: tempTime,
        mode: CupertinoDatePickerMode.time,
        onDateTimeChanged: (newTime) => tempTime = newTime,
      ),
      onConfirm: () => setState(() {
        if (isStart) {
          _startTime = tempTime;
        } else {
          _endTime = tempTime;
        }
      }),
    );
  }

  // --- POPUP STANZE PERSONALIZZATO ---
  void _showRoomPickerModal(Color color) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF5EFE6).withOpacity(0.9),
                        const Color(0xFFE7DCCF).withOpacity(0.86),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.76),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _addTaskInk.withOpacity(0.16),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Room',
                        style: GoogleFonts.manrope(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: _addTaskInk,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: color.withOpacity(0.24)),

                      ListTile(
                        title: Text(
                          'None',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: _selectedRoomId == null
                                ? color
                                : _addTaskWarmGrey.withOpacity(0.6),
                            fontWeight: _selectedRoomId == null
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedRoomId = null);
                          Navigator.pop(context);
                        },
                      ),
                      Divider(color: color.withOpacity(0.14)),

                      ..._rooms.map((room) {
                        final isSelected = room.id == _selectedRoomId;
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                room.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  color: isSelected ? color : _addTaskInk,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                              onTap: () {
                                setState(() => _selectedRoomId = room.id);
                                Navigator.pop(context);
                              },
                            ),
                            Divider(color: color.withOpacity(0.14)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) => formatDate(date);

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorSafeAzzurro = _sheetAccentPrimary;
    final selectedRoomExists =
        _selectedRoomId != null &&
        _rooms.any((room) => room.id == _selectedRoomId);

    final currentTargetDate = _selectedDate ?? DateTime.now();
    final weekdayName = _getWeekdayName(currentTargetDate.weekday);
    final canCreateTasks = _creationAccess?.canCreate ?? true;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.12, 1.0],
              colors: [
                const Color(0xFFFFFBF6).withOpacity(0.68),
                const Color(0xFFF9F1E7).withOpacity(0.62),
                const Color(0xFFF1E6D8).withOpacity(0.56),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.42),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: _addTaskInk.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      colorSafeAzzurro.withOpacity(0.74),
                      colorOrange.withOpacity(0.72),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (!widget.supervisionCreationMode &&
                  widget.assignedMemberIds != null &&
                  widget.assignedMemberIds!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorOrange.withOpacity(0.10),
                        colorOrange.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorOrange.withOpacity(0.26),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Assigning to ${widget.assignedMemberIds!.length} member(s)',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorOrange,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

              if (_isLoadingAccess)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: colorSafeAzzurro.withOpacity(0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _sheetAccentDeep,
                      ),
                    ),
                  ),
                )
              else if (_creationAccess != null && !_creationAccess!.canCreate)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorRed.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorRed.withOpacity(0.34),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: colorRed,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Personnel members cannot create tasks.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                widget.initialTask == null ? 'Task Details' : 'Edit Task',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _addTaskInk,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlassTextField(
                        controller: _titleController,
                        hint: 'Task Name',
                        color: colorSafeAzzurro,
                        isTitle: true,
                      ),
                      const SizedBox(height: 18),

                      _buildRoomSelector(colorSafeAzzurro, selectedRoomExists),
                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildActionPill(
                                actionKey: 'date',
                                icon: Icons.calendar_today_rounded,
                                text: _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Set Date',
                                color: colorOrange,
                                onTap: _selectDate,
                              ),
                              const SizedBox(width: 10),
                              _buildActionPill(
                                actionKey: 'start_time',
                                icon: Icons.access_time_rounded,
                                text: _startTime != null
                                    ? TimeOfDay.fromDateTime(
                                        _startTime!,
                                      ).format(context)
                                    : 'Start Time',
                                color: colorOrange,
                                onTap: () => _selectTime(true),
                              ),
                              const SizedBox(width: 10),
                              _buildActionPill(
                                actionKey: 'end_time',
                                icon: Icons.access_time_filled_rounded,
                                text: _endTime != null
                                    ? TimeOfDay.fromDateTime(
                                        _endTime!,
                                      ).format(context)
                                    : 'End Time',
                                color: colorOrange,
                                onTap: () => _selectTime(false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (widget.initialTask == null) ...[
                        GestureDetector(
                          onTap: () => setState(
                            () => _repeatWeeklyInMonth = !_repeatWeeklyInMonth,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.24),
                                  colorSafeAzzurro.withOpacity(0.10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorSafeAzzurro.withOpacity(0.20),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_repeat_rounded,
                                  color: colorSafeAzzurro,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Add task on every $weekdayName of the month',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _addTaskWarmGrey.withOpacity(0.78),
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _repeatWeeklyInMonth
                                        ? colorSafeAzzurro.withOpacity(0.22)
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: _repeatWeeklyInMonth
                                          ? colorSafeAzzurro.withOpacity(0.6)
                                          : colorSafeAzzurro.withOpacity(0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _repeatWeeklyInMonth
                                        ? Icons.check_rounded
                                        : Icons.add_rounded,
                                    color: colorSafeAzzurro,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        'Sub-tasks',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _addTaskWarmGrey.withOpacity(0.82),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._checklistItems.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildGlassTextField(
                                  controller: entry.value.controller,
                                  hint: 'Sub-task detail...',
                                  color: colorSafeAzzurro,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _removeSubTask(entry.key),
                                  splashColor: colorRed.withOpacity(0.18),
                                  highlightColor: colorRed.withOpacity(0.08),
                                  child: Ink(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: colorRed.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorRed.withOpacity(0.3),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      color: colorRed,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      Align(
                        alignment: Alignment.center,
                        child: _buildActionPill(
                          actionKey: 'add_subtask',
                          icon: Icons.add_rounded,
                          text: 'Sub-task',
                          color: colorSafeAzzurro,
                          onTap: _addSubTask,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: Opacity(
                  opacity: canCreateTasks ? 1 : 0.65,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: canCreateTasks
                            ? [_sheetAccentDeep, _sheetAccent]
                            : const [Color(0xFFB4BCC0), Color(0xFFA8AFB3)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (canCreateTasks ? _sheetAccentDeep : Colors.black)
                                  .withOpacity(0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: (_isSaving || !canCreateTasks)
                            ? null
                            : _submitTask,
                        splashColor: Colors.white.withOpacity(0.2),
                        highlightColor: Colors.black.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Task',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required Color color,
    bool isTitle = false,
  }) {
    final borderRadius = BorderRadius.circular(isTitle ? 22 : 18);

    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius),
      child: TextField(
        controller: controller,
        cursorColor: color,
        style: GoogleFonts.manrope(
          fontSize: isTitle ? 21 : 15,
          fontWeight: isTitle ? FontWeight.w800 : FontWeight.w600,
          color: _addTaskInk,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTitle ? 20 : 16,
            vertical: isTitle ? 20 : 16,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            color: _addTaskWarmGrey.withOpacity(0.36),
            fontWeight: FontWeight.w600,
            fontSize: isTitle ? 20 : 15,
          ),
          filled: true,
          fillColor: isTitle
              ? const Color(0xFFFFFBF7).withOpacity(0.22)
              : const Color(0xFFFFFBF7).withOpacity(0.17),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.32),
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.32),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: _sheetAccentPrimary.withOpacity(0.6),
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomSelector(Color color, bool roomExists) {
    String displayText = 'Room (optional)';
    if (roomExists && _selectedRoomId != null) {
      final foundRoom = _rooms.firstWhere((r) => r.id == _selectedRoomId);
      displayText = foundRoom.name;
    }

    return GestureDetector(
      onTap: () => _showRoomPickerModal(color),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFFBF7).withOpacity(0.22),
              const Color(0xFFFFFBF7).withOpacity(0.17),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(Icons.meeting_room_outlined, color: color, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.manrope(
                  color: roomExists
                      ? _addTaskInk
                      : _addTaskWarmGrey.withOpacity(0.52),
                  fontWeight: roomExists ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (_isLoadingRooms)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required String actionKey,
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedActionKey == actionKey;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedActionKey = actionKey),
      onTapUp: (_) {
        if (_pressedActionKey == actionKey) {
          setState(() => _pressedActionKey = null);
        }
      },
      onTapCancel: () {
        if (_pressedActionKey == actionKey) {
          setState(() => _pressedActionKey = null);
        }
      },
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: isPressed ? 0.985 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPressed
                  ? [Colors.white.withOpacity(0.40), color.withOpacity(0.16)]
                  : [Colors.white.withOpacity(0.32), color.withOpacity(0.12)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: actionKey == 'add_subtask'
                  ? color.withOpacity(0.40)
                  : isPressed
                  ? color.withOpacity(0.24)
                  : color.withOpacity(0.20),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistDraft {
  final TextEditingController controller;

  _ChecklistDraft({String text = ''})
    : controller = TextEditingController(text: text);
}
