import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_task_preview_tile.dart';

class HomeWeeklyModule extends StatelessWidget {
  final List<String> previewTitles;
  final String emptyLabel;
  final VoidCallback onTap;

  const HomeWeeklyModule({
    super.key,
    required this.previewTitles,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6FAE95);
    const surfaceColor = Color(0xFFEDF6F2);
    final preview = previewTitles.take(4).toList(growable: false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.24),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Tasks',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D342C),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: preview.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        emptyLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3D342C).withValues(alpha: 0.72),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var index = 0; index < preview.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == preview.length - 1 ? 0 : 8,
                            ),
                            child: HomeTaskPreviewTile(
                              title: preview[index],
                              accentColor: primaryColor,
                              variant: HomeTaskPreviewVariant.weekly,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
