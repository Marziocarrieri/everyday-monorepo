import 'package:flutter/material.dart';

class PetActivity {
  final String id;
  final String householdId;
  final String petId;
  final DateTime? date;
  final TimeOfDay? time;
  final TimeOfDay? endTime; // <-- AGGIUNTO
  final String? description;
  final String? notes;      // <-- AGGIUNTO
  
  PetActivity({
    required this.id,
    required this.householdId,
    required this.petId,
    this.date,
    this.time,
    this.endTime,           // <-- AGGIUNTO
    this.description,
    this.notes,             // <-- AGGIUNTO
  });

  factory PetActivity.fromJson(Map<String, dynamic> json) {
    final id = _asString(json['id']) ?? '';
    final householdId =
        _asString(json['houseHoldId']) ?? _asString(json['household_id']) ?? '';
    final petId = _asString(json['petId']) ?? _asString(json['pet_id']) ?? '';

    if (id.isEmpty || petId.isEmpty) {
      throw const FormatException('Invalid pet activity row');
    }

    return PetActivity(
      id: id,
      householdId: householdId,
      petId: petId,
      description: _asString(json['description']),
      notes: _asString(json['notes']),
      
      // Parse the Date String ("2026-04-22") into a DateTime object
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      
      // Parse the Time String ("21:47:03") into a TimeOfDay object
      time: _parseTime(json['time']?.toString()),
      
      // Parse the End Time String using the same helper
      endTime: _parseTime(json['end_time']?.toString()),
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // Helper method to turn "21:47:03" into TimeOfDay(hour: 21, minute: 47)
  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }
}