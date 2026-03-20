import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// Assicurati che questi import combacino con la struttura delle tue cartelle!
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';

const _containerTitleColor = Color(0xFFF8F1E8);
const _containerTitleSize = 24.0;
const _containerTitleWeight = FontWeight.w700;
const _containerTitleLetterSpacing = 0.2;
const _containerTitleShadows = <Shadow>[
  Shadow(color: Color(0x33203038), offset: Offset(0, 1.5), blurRadius: 4),
];

class ProvisionUtilityModule extends ConsumerWidget {
  final VoidCallback onTap;

  const ProvisionUtilityModule({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const quickSurfaceColors = [Color(0xFFD8AD90), Color(0xFFB06F59)];

    // 1. Recuperiamo l'ID della casa attiva
    final householdId = ref.watch(currentHouseholdIdProvider);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: quickSurfaceColors.first,
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: quickSurfaceColors,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: quickSurfaceColors.first.withValues(alpha: 0.3),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Provision List',
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
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Costruiamo il testo dinamico basato sui dati di Supabase!
                if (householdId == null)
                  _buildText(
                    'Household context missing...',
                    Colors.white.withValues(alpha: 0.7),
                  )
                else
                  ref
                      .watch(activeShoppingItemsProvider(householdId))
                      .when(
                        loading: () => _buildText(
                          'Loading your list...',
                          Colors.white.withValues(alpha: 0.7),
                        ),
                        error: (err, stack) => _buildText(
                          'Unable to load list.',
                          Colors.white.withValues(alpha: 0.7),
                        ),
                        data: (items) {
                          final count = items.length;
                          if (count == 0) {
                            return _buildText(
                              'Your list is empty. You are all set! ✨',
                              Colors.white.withValues(alpha: 0.95),
                            );
                          } else if (count == 1) {
                            return _buildText(
                              'You have 1 item to buy. Tap to open the list.',
                              Colors.white.withValues(alpha: 0.95),
                            );
                          } else {
                            // Creiamo un effetto grassetto sul numero per farlo risaltare
                            return RichText(
                              text: TextSpan(
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                children: [
                                  const TextSpan(text: 'You have '),
                                  TextSpan(
                                    text: '$count items',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' to buy. Tap to open the list.',
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper per non ripetere lo styling del testo
  Widget _buildText(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
