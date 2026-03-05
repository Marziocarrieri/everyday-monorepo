import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../repositories/pets_activities_repository.dart';
import '../models/pet_activity.dart';


import 'package:everyday_app/shared/utils/date_utils.dart';

class PetActivitiesScreen extends StatefulWidget {
  final String petId;
  final Color petColor; // Useremo questo come colore di Sfondo!

  const PetActivitiesScreen({super.key, required this.petId, required this.petColor});

  @override
  State<PetActivitiesScreen> createState() => _PetActivitiesScreenState();
}

class _PetActivitiesScreenState extends State<PetActivitiesScreen> {
  List<PetActivity> _activities = [];

  final PetActivitiesRepository _activityRepository = PetActivitiesRepository();
  bool _isLoading = false;
  String? _error;


    @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activities = await _activityRepository.getActivities(widget.petId);

      if (!mounted) return;
      
      setState(() {
        _activities = activities;
      });
    } catch (error) {
      if (!mounted) return;
      
      setState(() {
        _error = error.toString();
      });
      debugPrint('UI Error loading members: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openAddActivitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddPetActivitySheet(petColor: widget.petColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.petColor, // MAGIA: Lo sfondo è del colore del cucciolo!
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER INVERTITO ---
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
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)
                  ),
                  GestureDetector(
                    onTap: _openAddActivitySheet,
                    child: _buildHeaderIcon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
                physics: const BouncingScrollPhysics(),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  return ExpandableInvertedDateCard(
                    activity: _activities[index], // Changed 'data' to 'activity'
                    color: widget.petColor, 
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
}


  class ExpandableInvertedDateCard extends StatefulWidget {
    // 1. Changed 'data' from Map to PetActivity
    final PetActivity activity; 
    final Color color;
    
    const ExpandableInvertedDateCard({
      super.key, 
      required this.activity, // Updated parameter name
      required this.color,
    });

    @override
    State<ExpandableInvertedDateCard> createState() => _ExpandableInvertedDateCardState();
  }

  class _ExpandableInvertedDateCardState extends State<ExpandableInvertedDateCard> {
    bool _isExpanded = false;

    @override
    Widget build(BuildContext context) {
      // 2. Helper to format the Date (e.g., "27/11")
      final String dateStr = widget.activity.date != null 
          ? "${widget.activity.date!.day}/${widget.activity.date!.month}" 
          : "No Date";

      // 3. Helper to format the Time (e.g., "08:00 AM")
      final String timeStr = widget.activity.time != null 
          ? widget.activity.time!.format(context) 
          : "No Time";

      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ESPANSIONE BIANCA TRASLUCIDA
            if (_isExpanded)
              Container(
                margin: const EdgeInsets.only(top: 25),
                padding: const EdgeInsets.only(top: 70, bottom: 20, left: 20, right: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr, // Using formatted time
                      style: GoogleFonts.poppins(
                        fontSize: 13, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.activity.description ?? 'No Title', // Using class property
                      style: GoogleFonts.poppins(
                        fontSize: 18, 
                        fontWeight: FontWeight.w700, 
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // PILLOLA PRINCIPALE IN VETRO BIANCO
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
                        colors: [
                          Colors.white.withValues(alpha: 0.25), 
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05), 
                          blurRadius: 20, 
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white, 
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today_rounded, color: widget.color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            dateStr, // Using formatted date
                            style: GoogleFonts.poppins(
                              fontSize: 17, 
                              fontWeight: FontWeight.w700, 
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Icon(
                          _isExpanded 
                              ? Icons.keyboard_arrow_up_rounded 
                              : Icons.keyboard_arrow_down_rounded, 
                          color: Colors.white, 
                          size: 28,
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








// --- BOTTOM SHEET PER AGGIUNGERE L'ATTIVITÀ (Bianco Puro per contrastare) ---
class AddPetActivitySheet extends StatefulWidget {
  final Color petColor;
  const AddPetActivitySheet({super.key, required this.petColor});

  @override
  State<AddPetActivitySheet> createState() => _AddPetActivitySheetState();
}

class _AddPetActivitySheetState extends State<AddPetActivitySheet> {
  final TextEditingController _taskController = TextEditingController();
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
          color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
      onConfirm: () => setState(() { if (isStart) _startTime = tempTime; else _endTime = tempTime; }),
    );
  }

  String _formatDate(DateTime date) => formatDate(date);

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Il Bottom Sheet resta bianco per garantire la massima leggibilità
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), border: Border.all(color: Colors.white, width: 1.5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: const Color(0xFF3D342C).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text('Add Activity', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: widget.petColor)),
              const SizedBox(height: 24),
              
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
                  color: widget.petColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: widget.petColor.withValues(alpha: 0.5), width: 1.5), 
                ),
                child: Center(
                  child: TextField(
                    controller: _taskController, 
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3D342C)),
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'Activity details...', hintStyle: GoogleFonts.poppins(color: const Color(0xFF3D342C).withValues(alpha: 0.4))),
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
              const SizedBox(height: 40),
              
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 70, height: 70, 
                  decoration: BoxDecoration(color: widget.petColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.petColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))], border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2)), 
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36)
                ),
              ),
              const SizedBox(height: 10),
            ],
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
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5), 
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
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