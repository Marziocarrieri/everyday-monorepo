import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/app_router.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/shared/widgets/main_tab_screen_background.dart';
// IMPORTA IL NUOVO WIDGET CONDIVISO
import 'package:everyday_app/shared/widgets/avatar_image.dart';

const _personnelInk = Color(0xFF1F3A44);
const _personnelAccent = Color(0xFF5A8B9E);
const _personnelCardTintPalette = <Color>[
  Color(0xFF9FC8E8),
  Color(0xFF9FD8CF),
  Color(0xFFD8C4AE),
  Color(0xFFB7D5A5),
];

class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(householdMembersStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MainTabScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                _buildPersonnelHeader(),
                const SizedBox(height: 24),

                Expanded(
                  child: membersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        'Error: $error',
                        style: GoogleFonts.manrope(
                          color: _personnelInk.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    data: (members) {
                      final personnelMembers = members
                          .where(
                            (member) =>
                                member.role.toUpperCase() == 'PERSONNEL',
                          )
                          .toList();

                      if (personnelMembers.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: personnelMembers.length,
                        itemBuilder: (context, index) {
                          final member = personnelMembers[index];

                          // --- LOGICA DI FALLBACK NICKNAME -> NOME PROFILO ---
                          final displayName =
                              (member.nickname != null &&
                                  member.nickname!.trim().isNotEmpty)
                              ? member.nickname!
                              : (member.profile?.name ?? 'Unknown');

                          final displayInitial = displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?';

                          final avatarUrl =
                              member.avatarUrl ?? member.profile?.avatarUrl;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == personnelMembers.length - 1
                                  ? 8
                                  : 14,
                            ),
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
                                color:
                                    _personnelCardTintPalette[index %
                                        _personnelCardTintPalette.length],
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
      ),
    );
  }

  Widget _buildPersonnelHeader() {
    return SizedBox(
      height: 46,
      child: Center(
        child: Text(
          'Personnel',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _personnelInk,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_2_rounded,
            size: 52,
            color: _personnelAccent.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            'No personnel found',
            style: GoogleFonts.manrope(
              color: _personnelInk.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 116,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.34),
                Colors.white.withValues(alpha: 0.92),
                color.withValues(alpha: 0.2),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(-1, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // SOSTITUITO IL CONTAINER CON IL NUOVO WIDGET
                      AvatarImage(
                        avatarUrl: avatarUrl,
                        initial: initial,
                        size: 62,
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
                                color: _personnelInk,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                color: _personnelInk.withValues(alpha: 0.58),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
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
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _personnelInk,
                          size: 18,
                        ),
                        Text(
                          'View\nActivity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: _personnelInk,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
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
