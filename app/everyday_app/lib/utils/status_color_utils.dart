import 'package:flutter/material.dart';

Color getStatusColor(String expiryStatus) {
  if (expiryStatus == 'warning') return const Color(0xFFFFB347);
  if (expiryStatus == 'expired') return const Color(0xFFF28482);
  return const Color(0xFF7CB9E8);
}
