import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:everyday_app/features/legacy/screens/PERSONNEL/personnel_main_layout.dart'; // Colleghiamo la tua schermata
=======
import 'package:everyday_app/legacy_app/screens/CO-HOST/cohost_main_layout.dart'; // Colleghiamo la tua schermata
>>>>>>> b80b79c (Architecture refactor)

// Questa è  "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersonnelMainLayout(), // Mostra subito il tuo capolavoro
    ),
  );
}