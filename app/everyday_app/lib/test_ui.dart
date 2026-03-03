import 'package:flutter/material.dart';
import 'screens/your_home_screen.dart'; // Colleghiamo la tua schermata

// Questa è  "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: YourHomeScreen(), // Mostra subito il tuo capolavoro
    ),
  );
}