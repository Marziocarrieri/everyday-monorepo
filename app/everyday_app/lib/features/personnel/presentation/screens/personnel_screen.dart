import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
// IMPORTA IL NUOVO WIDGET CONDIVISO
import 'package:everyday_app/shared/widgets/avatar_image.dart';

class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  // --- GENERATORE DI COLORI PASTELLO BASATO SULL'INIZIALE ---
  Color _getColorForMember(String name) {
    if (name.isEmpty) return const Color(0xFF5A8B9E); // Default Azzurro

    final List<Color> palette = [
      const Color(0xFFF4A261), // Arancio
      const Color(0xFF2A9D8F), // Verde Acqua
      const Color(0xFFE76F51), // Corallo
      const Color(0xFFE9C46A), // Giallo
      const Color(0xFF8AB17D), // Verde Salvia
      const Color(0xFF5A8B9E), // Azzurro
    ];

    int colorIndex = name.toUpperCase().codeUnitAt(0) % palette.length;
    return palette[colorIndex];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // HEADER PREMIUM BLOCCATO
              SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Personnel',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5A8B9E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // LISTA CARD PREMIUM
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (members) {
                    final personnelMembers = members
                        .where(
                          (member) => member.role.toUpperCase() == 'PERSONNEL',
                        )
                        .toList();

                    if (personnelMembers.isEmpty) {
                      return const Center(child: Text('No personnel found'));
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: personnelMembers.length,
                      itemBuilder: (context, index) {
                        final member = personnelMembers[index];
                        
                        // --- LOGICA DI FALLBACK NICKNAME -> NOME PROFILO ---
                        final displayName = (member.nickname != null && member.nickname!.trim().isNotEmpty)
                            ? member.nickname!
                            : (member.profile?.name ?? 'Unknown');
                            
                        final displayInitial = displayName.isNotEmpty 
                            ? displayName[0].toUpperCase() 
                            : '?';

                        final memberColor = _getColorForMember(displayName); 
                        final avatarUrl = member.avatarUrl ?? member.profile?.avatarUrl;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: GestureDetector(
                            onTap: () {
                              AppRouter.navigate<void>(
                                context,
                                AppRouteNames.userTaskHistory,
                                arguments: UserTaskHistoryRouteArgs(
                                  targetMemberId: member.id,
                                  targetUserId: member.userId,
                                ),
                              );
                            },
                            child: _buildPremiumPersonnelCard(
                              name: displayName,
                              role: member.role,
                              initial: displayInitial,
                              color: memberColor,
                              avatarUrl: avatarUrl, // PASSATO ALLA CARD
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD PERSONALE PREMIUM AGGIORNATA ---
  Widget _buildPremiumPersonnelCard({
    required String name,
    required String role,
    required String initial,
    required Color color,
    String? avatarUrl, // NUOVO PARAMETRO
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 135,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.2),
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
                color: color.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      // SOSTITUITO IL CONTAINER CON IL NUOVO WIDGET
                      AvatarImage(
                        avatarUrl: avatarUrl,
                        initial: initial,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3D342C),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              role,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3D342C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 20),
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
                  child: Text(
                    'View\nActivity',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF5A8B9E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}