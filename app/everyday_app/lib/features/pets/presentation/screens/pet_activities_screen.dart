// TODO migrate to features/pets
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:everyday_app/features/pets/data/repositories/pets_activities_repository.dart'; 
import 'package:everyday_app/features/pets/data/models/pet_activity.dart'; 
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/features/pets/presentation/providers/pets_providers.dart';
import 'package:everyday_app/shared/utils/date_utils.dart';

class PetActivitiesScreen extends ConsumerStatefulWidget {
  final String petId;
  final Color petColor; 
  const PetActivitiesScreen({super.key, required this.petId, required this.petColor});

  @override
  ConsumerState<PetActivitiesScreen> createState() => _PetActivitiesScreenState();
}

class _PetActivitiesScreenState extends ConsumerState<PetActivitiesScreen> {
  final Color brandBlue = const Color(0xFF5A8B9E);

  // --- CONTROLLO RUOLO ---
  bool get _isPersonnel {
    final role = AppContext.instance.activeMembership?.role.toUpperCase() ?? '';
    final cleanRole = role.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
    return cleanRole == 'PERSONNEL';
  }

  Future<bool> _confirmDeleteActivity(PetActivity activity) async {
    // Sicurezza: blocca l'eliminazione se è Personnel
    if (_isPersonnel) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF28482).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF28482).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF28482), size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Delete Activity',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF3D342C)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${activity.description ?? 'this activity'}"?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C).withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(false),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF3D342C).withValues(alpha: 0.1), width: 1.5),
                            ),
                            child: Center(
                              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C).withValues(alpha: 0.7))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(true),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF28482),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFFF28482).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Center(
                              child: Text('Delete', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _deleteActivityInBackground({
    required String petId,
    required PetActivity activity,
  }) async {
    try {
      final repository = ref.read(petActivitiesRepositoryProvider);
      await repository.deleteActivity(activity.id);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'PET ACTIVITY UI DISMISS DELETE_FAILED id=${activity.id} error=$error',
        );
      }

      ref
          .read(petActivitiesLocalRemovalProvider(petId).notifier)
          .restoreActivityLocally(activity.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting activity', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFF28482),
        ),
      );
    }
  }

  void _handleActivityDismissed(PetActivity activity) {
    final removalNotifier = ref.read(
      petActivitiesLocalRemovalProvider(widget.petId).notifier,
    );
    removalNotifier.removeActivityLocally(activity.id);

    if (kDebugMode) {
      final pendingCount = ref.read(
        petActivitiesLocalRemovalProvider(widget.petId),
      ).length;
      debugPrint(
        'PET ACTIVITY UI DISMISS LOCAL REMOVE id=${activity.id} pending=$pendingCount',
      );
    }

    unawaited(
      _deleteActivityInBackground(
        petId: widget.petId,
        activity: activity,
      ),
    );
  }

  void _reconcileOptimisticRemovals(List<PetActivity> activities) {
    final snapshotIds = activities
        .map((activity) => activity.id)
        .toList(growable: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref
          .read(petActivitiesLocalRemovalProvider(widget.petId).notifier)
          .reconcileWithSnapshot(snapshotIds);
    });
  }

  void _openAddActivitySheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddPetActivitySheet(petColor: brandBlue, petId: widget.petId,),
    );

    if (result == true) {
      debugPrint('Add activity completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(petActivitiesStreamProvider(widget.petId));
    final locallyRemovedActivityIds = ref.watch(
      petActivitiesLocalRemovalProvider(widget.petId),
    );

    return Scaffold(
      backgroundColor: brandBlue,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _buildHeaderIcon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Text(
                    'Activities', 
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)
                  ),
                  // Mostra il tasto '+' SOLO se NON è personnel
                  if (!_isPersonnel)
                    GestureDetector(
                      onTap: _openAddActivitySheet,
                      child: _buildHeaderIcon(Icons.add_rounded),
                    )
                  else
                    // Spazio vuoto per mantenere il titolo "Activities" al centro
                    const SizedBox(width: 48), 
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: activitiesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (error, _) => Center(
                  child: Text(
                    'Error: $error',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                data: (activities) {
                  _reconcileOptimisticRemovals(activities);

                  final visibleActivities = activities
                      .where(
                        (activity) =>
                            !locallyRemovedActivityIds.contains(activity.id),
                      )
                      .toList(growable: false);

                  if (visibleActivities.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      bottom: 40.0,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: visibleActivities.length,
                    itemBuilder: (context, index) {
                      final activity = visibleActivities[index];

                      return Dismissible(
                        key: Key(activity.id),
                        direction: _isPersonnel
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await _confirmDeleteActivity(activity);
                        },
                        onDismissed: (_) {
                          _handleActivityDismissed(activity);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF28482),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        child: ExpandableInvertedDateCard(
                          activity: activity,
                          color: brandBlue,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15), 
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(
              // Cambia icona se è personnel
              _isPersonnel ? Icons.pets : Icons.add_rounded, 
              size: 64, 
              color: Colors.white.withValues(alpha: 0.5)
            ),
          ),
          const SizedBox(height: 24),
          Text('No Activities Yet', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            // Cambia testo se è personnel
            _isPersonnel 
              ? 'There are no recorded activities\nfor this pet yet.'
              : 'Track walks, vet visits,\nor feeding times here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7)),
          ),
          // Nascondi la freccia e il testo "+ button" se è personnel
          if (!_isPersonnel) ...[
            const SizedBox(height: 40),
            Icon(Icons.arrow_upward_rounded, color: Colors.white.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            Text('Tap the + button to add one', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5))),
          ]
        ],
      ),
    );
  }
}

class ExpandableInvertedDateCard extends StatefulWidget {
  final PetActivity activity; 
  final Color color;
  
  const ExpandableInvertedDateCard({
    super.key, 
    required this.activity, 
    required this.color,
  });

  @override
  State<ExpandableInvertedDateCard> createState() => _ExpandableInvertedDateCardState();
}

class _ExpandableInvertedDateCardState extends State<ExpandableInvertedDateCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String dateStr = widget.activity.date != null 
        ? "${widget.activity.date!.day}/${widget.activity.date!.month}/${widget.activity.date!.year}" 
        : "No Date";

    // --- LOGICA ORARIO (Inizio - Fine uniti sulla stessa riga) ---
    String timeStr = "No Time";
    if (widget.activity.time != null) {
      timeStr = widget.activity.time!.format(context);
      if (widget.activity.endTime != null) {
         timeStr = "$timeStr - ${widget.activity.endTime!.format(context)}"; // Unisce i due orari
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 25),
              padding: const EdgeInsets.only(top: 70, bottom: 20, left: 20, right: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        timeStr, 
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.activity.description ?? 'No Description', 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                  ),
                  
                  // --- LOGICA NOTE ---
                  if (widget.activity.notes != null && widget.activity.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.activity.notes!,
                              style: GoogleFonts.poppins(
                                fontSize: 14, 
                                fontWeight: FontWeight.w500, 
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 75,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Icon(Icons.calendar_today_rounded, color: widget.color, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          dateStr, 
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                          color: Colors.white, size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPetActivitySheet extends StatefulWidget {
  final Color petColor;
  final String petId;
  const AddPetActivitySheet({super.key, required this.petColor, required this.petId});

  @override
  State<AddPetActivitySheet> createState() => _AddPetActivitySheetState();
}

class _AddPetActivitySheetState extends State<AddPetActivitySheet> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _notesController = TextEditingController(); 
  DateTime? _selectedDate;
  DateTime? _startTime;
  DateTime? _endTime;

  void _showIOSPicker({required Widget child, required VoidCallback onConfirm}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280, padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)), onPressed: () => Navigator.of(context).pop()),
                    CupertinoButton(child: Text('Done', style: GoogleFonts.poppins(color: widget.petColor, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: () { onConfirm(); Navigator.of(context).pop(); })
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
      child: CupertinoDatePicker(initialDateTime: tempDate, mode: CupertinoDatePickerMode.date, onDateTimeChanged: (newDate) => tempDate = newDate),
      onConfirm: () => setState(() => _selectedDate = tempDate),
    );
  }

  void _selectTime(bool isStart) {
    DateTime tempTime = isStart ? (_startTime ?? DateTime.now()) : (_endTime ?? DateTime.now().add(const Duration(hours: 1)));
    _showIOSPicker(
      child: CupertinoDatePicker(initialDateTime: tempTime, mode: CupertinoDatePickerMode.time, onDateTimeChanged: (newTime) => tempTime = newTime),
      onConfirm: () => setState(() {
        if (isStart) {
          _startTime = tempTime;
        } else {
          _endTime = tempTime;
        }
      }),
    );
  }

  String _formatDate(DateTime date) => formatDate(date);

  @override
  void dispose() {
    _taskController.dispose();
    _notesController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), border: Border.all(color: Colors.white, width: 1.5)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: const Color(0xFF3D342C).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text('Add Activity', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: widget.petColor)),
                const SizedBox(height: 30),
                
                _buildActionPill(
                  icon: Icons.calendar_today_rounded, 
                  text: _selectedDate != null ? _formatDate(_selectedDate!) : 'Select Date', 
                  color: widget.petColor, 
                  onTap: _selectDate,
                  fullWidth: true
                ),
                const SizedBox(height: 16),

                Container(
                  height: 60, padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: widget.petColor.withValues(alpha: 0.05), 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: widget.petColor.withValues(alpha: 0.2), width: 1.5), 
                  ),
                  child: Center(
                    child: TextField(
                      controller: _taskController, 
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
                      decoration: InputDecoration(border: InputBorder.none, hintText: 'Activity details...', hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.3))),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _buildActionPill(icon: Icons.access_time_rounded, text: _startTime != null ? TimeOfDay.fromDateTime(_startTime!).format(context) : 'Start', color: widget.petColor, onTap: () => _selectTime(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionPill(icon: Icons.access_time_filled_rounded, text: _endTime != null ? TimeOfDay.fromDateTime(_endTime!).format(context) : 'End', color: widget.petColor, onTap: () => _selectTime(false))),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.petColor.withValues(alpha: 0.05), 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: widget.petColor.withValues(alpha: 0.2), width: 1.5), 
                  ),
                  child: TextField(
                    controller: _notesController, 
                    maxLines: 3, 
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF3D342C)),
                    decoration: InputDecoration(
                      border: InputBorder.none, 
                      hintText: 'Additional notes (optional)...', 
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.3))
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                GestureDetector(
                  onTap: () async {
                    final description = _taskController.text.trim();
                    final notes = _notesController.text.trim();
                    
                    if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a date', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFF28482),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    try {
                      final householdId = AppContext.instance.requireHouseholdId();
                      final petId = widget.petId; 
                      final memberId =
                          AppContext.instance.activeMembership?.id ??
                          AppContext.instance.membershipId;
                      final createdBy = AppContext.instance.userId;

                      String formatTime(DateTime dt) {
                        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00";
                      }

                      final repo = PetActivitiesRepository();
                      
                      await repo.insertActivity(
                        householdId: householdId,
                        petId: petId,
                        date: _selectedDate!,
                        description: description.isNotEmpty ? description : null,
                        startTime: _startTime != null ? formatTime(_startTime!) : null,
                        endTime: _endTime != null ? formatTime(_endTime!) : null,
                        notes: notes.isNotEmpty ? notes : null, 
                        memberId: memberId,
                        createdBy: createdBy,
                      );
                    
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      debugPrint('Errore durante l\'inserimento attività: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving activity: $e', style: GoogleFonts.poppins()),
                            backgroundColor: const Color(0xFFF28482),
                          ),
                        );
                      }
                    }
                  },

                  child: Container(
                    width: double.infinity, height: 60, 
                    decoration: BoxDecoration(
                      color: widget.petColor, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: widget.petColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ), 
                    child: Center(
                      child: Text('Save Activity', style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({required IconData icon, required String text, required Color color, required VoidCallback onTap, bool fullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5), 
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          mainAxisAlignment: fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20), 
            const SizedBox(width: 12), 
            Text(text, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: color))
          ]
        ),
      ),
    );
  }
}