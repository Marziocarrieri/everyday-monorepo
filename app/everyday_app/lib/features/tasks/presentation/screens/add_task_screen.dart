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
import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/utils/status_color_utils.dart';
import '../providers/task_providers.dart';

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
      'Clear the table'
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
      'Take out recycling'
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
      'Clean dishwasher filter'
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
      'Restock water/beverages'
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
      'Organize toys'
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
      'Wash pet bedding'
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
      'Schedule car service'
    ],
    'Garden & Outdoor': [
      'Water the plants (Indoor)',
      'Water the plants (Outdoor)',
      'Mow the lawn',
      'Rake leaves',
      'Clean the patio / balcony',
      'Take out the yard waste'
    ],
    'Personal & Health': [
      'Workout / Gym',
      'Doctor appointment',
      'Dentist appointment',
      'Buy medicines at pharmacy',
      'Haircut appointment',
      'Beauty/Spa appointment',
      'Meditate / Relax',
      'Read a book'
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
      'Buy a gift'
    ]
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

  @override
  Widget build(BuildContext context) {
    final Color colorSafeAzzurro = getStatusColor('safe');
    
    // --- LOGICA DI FILTRAGGIO RICERCA ---
    final query = _searchController.text.trim().toLowerCase();
    
    final filteredEntries = _suggestedTasks.entries.map((entry) {
      final matchedTasks = entry.value
          .where((task) => task.toLowerCase().contains(query))
          .toList();
      return MapEntry(entry.key, matchedTasks);
    }).where((entry) => entry.value.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER PREMIUM ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorSafeAzzurro.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorSafeAzzurro.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colorSafeAzzurro,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'Add a Task',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorSafeAzzurro,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openTaskSheet(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorSafeAzzurro.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorSafeAzzurro.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colorSafeAzzurro,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- BARRA DI RICERCA GLASS BIANCA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {}); 
                            },
                            decoration: InputDecoration(
                              hintText: 'Search templates...',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(
                                  0xFF3D342C,
                                ).withOpacity(0.4),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF3D342C),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.search_rounded,
                          color: colorSafeAzzurro,
                          size: 24,
                        ),
                      ],
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
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF3D342C).withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: filteredEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3D342C),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...entry.value.map(
                                  (taskName) => _buildSuggestionPill(
                                    taskName,
                                    colorSafeAzzurro,
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
    );
  }

  Widget _buildSuggestionPill(String taskName, Color colorSafeAzzurro) {
    return GestureDetector(
      onTap: () => _openTaskSheet(initialTitle: taskName),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorSafeAzzurro.withOpacity(0.15),
                    Colors.white.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorSafeAzzurro.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorSafeAzzurro.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: colorSafeAzzurro,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      taskName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D342C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  final Color colorOrange = const Color(0xFFF4A261);
  final Color colorRed = const Color(0xFFF28482);

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    final now = DateTime.now();
    final localToday = DateTime(now.year, now.month, now.day);
    _titleController = TextEditingController(
      text: initialTask?.task.title ?? widget.initialTitle ?? '',
    );
    _selectedDate = initialTask?.task.taskDate ?? widget.initialDate ?? localToday;

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
          style: GoogleFonts.poppins(
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
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
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
                      color: Colors.grey.withOpacity(0.2),
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
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                          color: colorOrange,
                          fontWeight: FontWeight.w700,
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
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Room',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D342C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: color.withOpacity(0.2)),

                  ListTile(
                    title: Text(
                      'None',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _selectedRoomId == null
                            ? color
                            : const Color(0xFF3D342C).withOpacity(0.5),
                        fontWeight: _selectedRoomId == null
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedRoomId = null);
                      Navigator.pop(context);
                    },
                  ),
                  Divider(color: color.withOpacity(0.1)),

                  ..._rooms.map((room) {
                    final isSelected = room.id == _selectedRoomId;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            room.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? color
                                  : const Color(0xFF3D342C),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedRoomId = room.id);
                            Navigator.pop(context);
                          },
                        ),
                        Divider(color: color.withOpacity(0.1)),
                      ],
                    );
                  }),
                ],
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
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color colorSafeAzzurro = getStatusColor('safe');
    final selectedRoomExists =
        _selectedRoomId != null &&
        _rooms.any((room) => room.id == _selectedRoomId);

    final currentTargetDate = _selectedDate ?? DateTime.now();
    final weekdayName = _getWeekdayName(currentTargetDate.weekday);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
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
            color: Colors.white.withOpacity(0.95),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: colorSafeAzzurro.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              if (!widget.supervisionCreationMode &&
                  widget.assignedMemberIds != null &&
                  widget.assignedMemberIds!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Assigning to ${widget.assignedMemberIds!.length} member(s)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorOrange,
                    ),
                  ),
                ),

              if (_isLoadingAccess)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: colorSafeAzzurro.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorSafeAzzurro,
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
                    color: colorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorRed.withOpacity(0.3),
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
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                widget.initialTask == null ? 'Task Details' : 'Edit Task',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorSafeAzzurro,
                  letterSpacing: -0.5,
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
                      const SizedBox(height: 20),

                      // STANZA
                      _buildRoomSelector(colorSafeAzzurro, selectedRoomExists),
                      const SizedBox(height: 24),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildActionPill(
                              icon: Icons.calendar_today_rounded,
                              text: _selectedDate != null
                                  ? _formatDate(_selectedDate!)
                                  : 'Set Date',
                              color: colorOrange,
                              onTap: _selectDate,
                            ),
                            const SizedBox(width: 10),
                            _buildActionPill(
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
                      const SizedBox(height: 30),

                      // --- NUOVO DESIGN: TOGGLE RIPETIZIONE MENSILE (VETRO ROTONDO) ---
                      if (widget.initialTask == null) ...[
                        GestureDetector(
                          onTap: () => setState(() => _repeatWeeklyInMonth = !_repeatWeeklyInMonth),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colorSafeAzzurro.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorSafeAzzurro.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      // Testo prima
                                      Text(
                                        'Add task on every $weekdayName of the month',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3D342C).withOpacity(0.7),
                                        ),
                                      ),
                                      // Icona rotonda dopo a destra
                                      Icon(
                                        _repeatWeeklyInMonth 
                                          ? Icons.check_circle_rounded 
                                          : Icons.radio_button_unchecked_rounded,
                                        color: colorSafeAzzurro,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        'Sub-tasks',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D342C),
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
                              GestureDetector(
                                onTap: () => _removeSubTask(entry.key),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: colorRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorRed.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    color: colorRed,
                                    size: 24,
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorSafeAzzurro,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: colorSafeAzzurro.withOpacity(0.4),
                  ),
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
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
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
    return Container(
      height: isTitle ? 65 : 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isTitle
            ? color.withOpacity(0.1)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(isTitle ? 24 : 16),
        border: Border.all(
          color: isTitle
              ? color.withOpacity(0.4)
              : color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: isTitle
            ? [
                BoxShadow(
                  color: color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          style: GoogleFonts.poppins(
            fontSize: isTitle ? 20 : 16,
            fontWeight: isTitle ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF3D342C),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF3D342C).withOpacity(0.4),
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
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.meeting_room_outlined, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.poppins(
                  color: roomExists
                      ? const Color(0xFF3D342C)
                      : const Color(0xFF3D342C).withOpacity(0.5),
                  fontWeight: roomExists ? FontWeight.w600 : FontWeight.w500,
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
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
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