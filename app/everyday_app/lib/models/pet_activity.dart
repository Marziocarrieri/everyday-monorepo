import 'package:flutter/material.dart';

class PetActivity {
  final String id;
  final String householdId;
  final String petId;
  final DateTime? date;
  final TimeOfDay? time;
  final String? description;
  
  PetActivity({
    required this.id,
    required this.householdId,
    required this.petId,
    this.date,
    this.time,
    this.description,
  });

  factory PetActivity.fromJson(Map<String, dynamic> json) {
  return PetActivity(
    id: json['id'] as String? ?? '',
    // Note: Use 'houseHoldId' to match your JSON log exactly
    householdId: json['houseHoldId'] as String? ?? '', 
    petId: json['petId'] as String? ?? '',
    description: json['description'] as String?,
    
    // Parse the Date String ("2026-04-22") into a DateTime object
    date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    
    // Parse the Time String ("21:47:03") into a TimeOfDay object
    time: _parseTime(json['time']),
  );
  }

  // Helper method to turn "21:47:03" into TimeOfDay(hour: 21, minute: 47)
  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

}