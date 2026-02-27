import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // Colleghiamo la tua schermata

// Questa è  "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(), // Mostra subito il tuo capolavoro
    ),
  );
}