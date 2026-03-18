// TODO migrate to features/fridge
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:everyday_app/core/app_route_names.dart';
// TODO: Verifica che questi import puntino alla cartella corretta dove hai salvato i widget
import 'package:everyday_app/features/fridge/presentation/widgets/fridge_utility_module.dart';
import 'package:everyday_app/features/fridge/presentation/widgets/provision_utility_module.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF6F7F9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              // Modulo: Fridge Keeping (Gestisce la navigazione internamente tramite i chip)
              const FridgeUtilityModule(),
              
              const SizedBox(height: 24),
              
              // Modulo: Provision List (Naviga sull'intera card)
              ProvisionUtilityModule(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouteNames.provisionList);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return SizedBox(
      height: 46,
      child: Center(
        child: Text(
          'Utilities',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2F4858),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}