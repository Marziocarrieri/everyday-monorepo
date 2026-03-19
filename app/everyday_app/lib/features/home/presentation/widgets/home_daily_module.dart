import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Richiama solo la righina dei task, nient'altro!
import 'home_task_preview_tile.dart'; 

class HomeDailyPreviewItem {
  final String title;
  final bool isCompleted;

  const HomeDailyPreviewItem({
    required this.title,
    required this.isCompleted,
  });
}

class HomeDailyModule extends StatelessWidget {
  final double completion;
  final List<HomeDailyPreviewItem> previewItems;
  final String emptyLabel;
  final VoidCallback onTap;

  const HomeDailyModule({
    super.key,
    required this.completion,
    required this.previewItems,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brightColor = Color(0xFF8C6AEC);
    const darkColor = Color(0xFF5D3FAD);
    
    final previewTasks = previewItems.take(3).toList(growable: false);
    final normalizedCompletion = completion.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brightColor, darkColor],
          ),
          boxShadow: [
            BoxShadow(
              color: brightColor.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Tasks',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                // --- BADGE DELLA PERCENTUALE DA SOLO ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(normalizedCompletion * 100).round()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16), 
            
            // --- LISTA SCORREVOLE ANTI-ERRORE ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: previewTasks.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          emptyLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < previewTasks.length; i++) ...[
                            HomeTaskPreviewTile(
                              title: previewTasks[i].title,
                              isCompleted: previewTasks[i].isCompleted,
                              variant: HomeTaskPreviewVariant.daily,
                              themeColor: brightColor, 
                            ),
                            if (i != previewTasks.length - 1) 
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
            ),
              
            const SizedBox(height: 12),
            
            // PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                color: Colors.white.withOpacity(0.25),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: normalizedCompletion,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}