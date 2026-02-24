import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Colleghiamo la tua schermata

// Questa è la tua "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // Mostra subito il tuo capolavoro
    ),
  );
}