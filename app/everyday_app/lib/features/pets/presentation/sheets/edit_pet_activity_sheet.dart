import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:everyday_app/features/pets/data/models/pet_activity.dart';
import 'package:everyday_app/features/pets/presentation/providers/pets_providers.dart';
import 'package:everyday_app/shared/utils/date_utils.dart';

Future<void> openEditActivitySheet(
  BuildContext context,
  PetActivity activity,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => EditPetActivitySheet(activity: activity),
  );
}

class EditPetActivitySheet extends ConsumerStatefulWidget {
  final PetActivity activity;

  const EditPetActivitySheet({
    super.key,
    required this.activity,
  });

  @override
  ConsumerState<EditPetActivitySheet> createState() =>
      _EditPetActivitySheetState();
}

class _EditPetActivitySheetState extends ConsumerState<EditPetActivitySheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.activity.description ?? '';
    _descriptionController.text = widget.activity.notes ?? '';
    _selectedDate = widget.activity.date;
    _startTime = widget.activity.time;
    _endTime = widget.activity.endTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showIOSPicker({required Widget child, required VoidCallback onConfirm}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                      color: Colors.grey.withValues(alpha: 0.2),
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
                          color: const Color(0xFF5A8B9E),
                          fontWeight: FontWeight.bold,
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
    TimeOfDay seed = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));

    DateTime tempTime = DateTime(
      2026,
      1,
      1,
      seed.hour,
      seed.minute,
    );

    _showIOSPicker(
      child: CupertinoDatePicker(
        initialDateTime: tempTime,
        mode: CupertinoDatePickerMode.time,
        onDateTimeChanged: (newTime) => tempTime = newTime,
      ),
      onConfirm: () {
        final selected = TimeOfDay(
          hour: tempTime.hour,
          minute: tempTime.minute,
        );
        setState(() {
          if (isStart) {
            _startTime = selected;
          } else {
            _endTime = selected;
          }
        });
      },
    );
  }

  String _formatDate(DateTime date) => formatDate(date);

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final updatedData = <String, dynamic>{
      'description': _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      'notes': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'time': _startTime == null ? null : _formatTime(_startTime!),
      'end_time': _endTime == null ? null : _formatTime(_endTime!),
      if (_selectedDate != null)
        'date': _selectedDate!.toIso8601String().split('T')[0],
    };

    try {
      await ref
          .read(petsActivitiesRepositoryProvider)
          .updateActivity(widget.activity.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating activity: $error',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFF28482),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D342C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Edit Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A8B9E),
                  ),
                ),
                const SizedBox(height: 30),
                _buildActionPill(
                  icon: Icons.calendar_today_rounded,
                  text: _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : 'Select Date',
                  color: const Color(0xFF5A8B9E),
                  onTap: _selectDate,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A8B9E).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5A8B9E).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D342C),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Title',
                        hintStyle: GoogleFonts.poppins(
                          color: const Color(0xFF3D342C).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionPill(
                        icon: Icons.access_time_rounded,
                        text: _startTime != null
                            ? _startTime!.format(context)
                            : 'Start',
                        color: const Color(0xFF5A8B9E),
                        onTap: () => _selectTime(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionPill(
                        icon: Icons.access_time_filled_rounded,
                        text:
                            _endTime != null ? _endTime!.format(context) : 'End',
                        color: const Color(0xFF5A8B9E),
                        onTap: () => _selectTime(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A8B9E).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5A8B9E).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D342C),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Description / notes',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF3D342C).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A8B9E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5A8B9E).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
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
