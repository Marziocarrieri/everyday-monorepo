import 'package:flutter/material.dart';
import 'screens/main_layout.dart'; // Colleghiamo la tua schermata

// Questa è la tua "porta di servizio"
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainLayout(), // Mostra subito il tuo capolavoro
    ),
  );
}