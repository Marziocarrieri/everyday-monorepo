import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_empty_state.dart';

class HomeDailyTaskCard extends StatelessWidget {
  final int totalTasks;
  final double completion;
  final String subtitle;
  final Future<void> Function() onTap;

  const HomeDailyTaskCard({
    super.key,
    required this.totalTasks,
    required this.completion,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF4A261).withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF4A261).withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3D342C),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3D342C).withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'A',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Daily Task',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3D342C),
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 54),
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3D342C).withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: totalTasks == 0
                        ? const HomeEmptyState(message: 'No tasks assigned today')
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: completion,
                                  strokeWidth: 6,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.5),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF4A261),
                                  ),
                                ),
                              ),
                              Text(
                                '${(completion * 100).round()}%',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF4A261),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
