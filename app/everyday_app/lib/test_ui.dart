import 'package:flutter/material.dart';
import 'screens/daily_task_screen.dart'; // Colleghiamo la tua schermata

// Questa è  "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DailyTaskScreen(), // Mostra subito il tuo capolavoro
    ),
  );
}