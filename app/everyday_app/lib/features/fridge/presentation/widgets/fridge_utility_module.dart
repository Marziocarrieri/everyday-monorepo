import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/fridge/data/models/area_type.dart';

const _containerTitleColor = Color(0xFFF8F1E8);
const _containerTitleSize = 24.0;
const _containerTitleWeight = FontWeight.w700;
const _containerTitleLetterSpacing = 0.2;
const _containerTitleShadows = <Shadow>[
  Shadow(color: Color(0x33203038), offset: Offset(0, 1.5), blurRadius: 4),
];

class FridgeUtilityModule extends StatelessWidget {
  const FridgeUtilityModule({super.key});

  @override
  Widget build(BuildContext context) {
    const agentSurfaceColors = [Color(0xFF6794AA), Color(0xFF2F4858)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: agentSurfaceColors.first,
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: agentSurfaceColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: agentSurfaceColors.first.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER CARD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fridge Keeping',
                    style: GoogleFonts.manrope(
                      fontSize: _containerTitleSize,
                      fontWeight: _containerTitleWeight,
                      letterSpacing: _containerTitleLetterSpacing,
                      shadows: _containerTitleShadows,
                      color: _containerTitleColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // GRIGLIA DEGLI SHORTCUTS (2 Colonne perfette)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildShortcutChip(
                          context,
                          AreaType.fridge,
                          Icons.kitchen_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShortcutChip(
                          context,
                          AreaType.freezer,
                          Icons.ac_unit_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildShortcutChip(
                          context,
                          AreaType.pantry,
                          Icons.inventory_2_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShortcutChip(
                          context,
                          AreaType.spirits,
                          Icons.wine_bar_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildShortcutChip(
                          context,
                          AreaType.household,
                          Icons.cleaning_services_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildShortcutChip(
                          context,
                          AreaType.personalCare,
                          Icons.spa_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChip(
    BuildContext context,
    AreaType area,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouteNames.fridgeKeeping,
          arguments: FridgeKeepingRouteArgs(initialArea: area),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), // Effetto vetro sul blu
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                area.label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
