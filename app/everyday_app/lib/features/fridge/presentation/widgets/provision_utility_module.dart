import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Assicurati che questi import combacino con la struttura delle tue cartelle!
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';

class ProvisionUtilityModule extends ConsumerWidget {
  final VoidCallback onTap;

  const ProvisionUtilityModule({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const brightOrange = Color(0xFFF08A5D);
    const deepOrange = Color(0xFFE07A4F);

    // 1. Recuperiamo l'ID della casa attiva
    final householdId = ref.watch(currentHouseholdIdProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: brightOrange,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: brightOrange.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brightOrange,
              deepOrange,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Provision List',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
              _buildText('Household context missing...', Colors.white.withValues(alpha: 0.7))
            else
              ref.watch(activeShoppingItemsProvider(householdId)).when(
                    loading: () => _buildText('Loading your list...', Colors.white.withValues(alpha: 0.7)),
                    error: (err, stack) => _buildText('Unable to load list.', Colors.white.withValues(alpha: 0.7)),
                    data: (items) {
                      final count = items.length;
                      if (count == 0) {
                        return _buildText('Your list is empty. You are all set! ✨', Colors.white.withValues(alpha: 0.95));
                      } else if (count == 1) {
                        return _buildText('You have 1 item to buy. Tap to open the list.', Colors.white.withValues(alpha: 0.95));
                      } else {
                        // Creiamo un effetto grassetto sul numero per farlo risaltare
                        return RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            children: [
                              const TextSpan(text: 'You have '),
                              TextSpan(
                                text: '$count items',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              const TextSpan(text: ' to buy. Tap to open the list.'),
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
    );
  }

  // Helper per non ripetere lo styling del testo
  Widget _buildText(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}