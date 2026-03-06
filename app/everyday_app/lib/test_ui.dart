import 'package:flutter/material.dart';
import 'package:everyday_app/features/legacy/screens/PERSONNEL/personnel_main_layout.dart'; // Colleghiamo la tua schermata

// Questa è  "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersonnelMainLayout(), // Mostra subito il tuo capolavoro
    ),
  );
}