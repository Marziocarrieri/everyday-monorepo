// TODO migrate to features/personnel
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import '../../features/personnel/data/models/household_member.dart';
// IMPORTA IL NUOVO WIDGET CONDIVISO
import 'package:everyday_app/shared/widgets/avatar_image.dart';

enum FamilyMemberSelectionFlowMode { addTask, viewActivity }

void openFamilyMemberSelectionSheet(
  BuildContext context,
  AsyncValue<List<HouseholdMember>> members, {
  FamilyMemberSelectionFlowMode flowMode =
      FamilyMemberSelectionFlowMode.addTask,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) =>
        SelectFamilyMemberSheet(members: members, flowMode: flowMode),
  );
}

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = AppContext.instance.userId;
    final membersAsync = ref.watch(householdMembersStreamProvider);

    // --- CONTROLLO RUOLI ---
    final role = AppContext.instance.activeMembership?.role.toUpperCase() ?? '';
    final isHost = role == 'HOST';

    // Pulisco la stringa per controllare il Personnel con sicurezza
    final cleanRole = role
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    final isPersonnel = cleanRole == 'PERSONNEL';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // HEADER PREMIUM DINAMICO IN BASE AL RUOLO
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tasto Sinistro: Pets (se Host), Back (se Cohost/Personnel)
                    _buildHeaderIcon(
                      isHost ? Icons.pets : Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (isHost) {
                          Navigator.of(context).pushNamed(AppRouteNames.pets);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),

                    Text(
                      'Family',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A8B9E),
                        letterSpacing: 0.5,
                      ),
                    ),

                    // Tasto Destro: Add (se Host), Pets (se Cohost/Personnel)
                    _buildHeaderIcon(
                      isHost ? Icons.add_rounded : Icons.pets,
                      onTap: () {
                        if (isHost) {
                          openFamilyMemberSelectionSheet(context, membersAsync);
                        } else {
                          Navigator.of(context).pushNamed(AppRouteNames.pets);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // LISTA CARD PREMIUM (MODIFICATA PER IL CLICK E L'AVATAR)
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (members) {
                    final familyMembers = members.where((member) {
                      final memberRole = member.role.toUpperCase();
                      final isFamilyRole =
                          memberRole == 'HOST' || memberRole == 'COHOST';
                      final isCurrentUser =
                          currentUserId != null &&
                          member.userId == currentUserId;
                      return isFamilyRole && !isCurrentUser;
                    }).toList();

                    if (familyMembers.isEmpty) {
                      return const Center(child: Text('No members found'));
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: familyMembers.length,
                      itemBuilder: (context, index) {
                        final member = familyMembers[index];

                        // --- LOGICA DI FALLBACK NICKNAME -> NOME PROFILO ---
                        final displayName =
                            (member.nickname != null &&
                                member.nickname!.trim().isNotEmpty)
                            ? member.nickname!
                            : (member.profile?.name ?? 'Unknown');

                        final displayInitial = displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?';

                        // Recuperiamo l'avatar (priorità a quello del membro, poi a quello del profilo)
                        final avatarUrl =
                            member.avatarUrl ?? member.profile?.avatarUrl;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildPremiumFamilyCard(
                            context: context,
                            memberId: member.id,
                            userId: member.userId,
                            name: displayName,
                            initial: displayInitial,
                            avatarUrl: avatarUrl, // PASSATO ALLA CARD
                            color: const Color(0xFFF4A261),
                            role: member.role,
                            isPersonnel: isPersonnel,
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

  Widget _buildHeaderIcon(
    IconData icon, {
    VoidCallback? onTap,
    Color? activeColor,
  }) {
    final iconColor = activeColor ?? const Color(0xFF5A8B9E);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: iconColor.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  // --- CARD FAMILY PREMIUM AGGIORNATA ---
  Widget _buildPremiumFamilyCard({
    required BuildContext context,
    required String memberId,
    required String userId,
    required String name,
    required String role,
    required String initial,
    required Color color,
    required bool isPersonnel,
    String? avatarUrl, // NUOVO PARAMETRO
  }) {
    // Il widget base della Card (separato dal GestureDetector)
    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Container(
          height: 120,
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
                            const SizedBox(height: 2),
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

              // SE NON È PERSONNEL: Mostra la linea e la scritta "View Activity"
              if (!isPersonnel) ...[
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
            ],
          ),
        ),
      ),
    );

    // SE È PERSONNEL: Restituisci la card NON CLICCABILE
    if (isPersonnel) {
      return cardContent;
    }

    // ALTRIMENTI: Restituisci la card con il GestureDetector
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouteNames.userTaskHistory,
          arguments: UserTaskHistoryRouteArgs(
            targetMemberId: memberId,
            targetUserId: userId,
          ),
        );
      },
      child: cardContent,
    );
  }
}

// ==========================================
// BOTTOM SHEET: SELEZIONA MEMBRI PER TASK
// ==========================================
class SelectFamilyMemberSheet extends StatefulWidget {
  final AsyncValue<List<HouseholdMember>> members;
  final FamilyMemberSelectionFlowMode flowMode;

  const SelectFamilyMemberSheet({
    super.key,
    required this.members,
    this.flowMode = FamilyMemberSelectionFlowMode.addTask,
  });

  @override
  State<SelectFamilyMemberSheet> createState() =>
      _SelectFamilyMemberSheetState();
}

class _SelectFamilyMemberSheetState extends State<SelectFamilyMemberSheet> {
  final Set<String> _selectedMemberIds = {};

  bool get _isViewActivityMode {
    return widget.flowMode == FamilyMemberSelectionFlowMode.viewActivity;
  }

  bool _isAssignableRole(String role) {
    final normalized = role.toUpperCase().replaceAll(RegExp(r'[-_\s]'), '');
    return normalized == 'HOST' ||
        normalized == 'COHOST' ||
        normalized == 'PERSONNEL';
  }

  List<HouseholdMember> _assignableMembers(List<HouseholdMember> members) {
    return members
        .where((member) => _isAssignableRole(member.role))
        .toList(growable: false);
  }

  bool get _isAllSelected {
    if (_isViewActivityMode) return false;

    final list = _assignableMembers(widget.members.value ?? []);
    final assignableIds = list.map((member) => member.id).toSet();
    final selectedAssignableCount = _selectedMemberIds
        .where((memberId) => assignableIds.contains(memberId))
        .length;
    return list.isNotEmpty && selectedAssignableCount == list.length;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_isViewActivityMode) {
        if (_selectedMemberIds.contains(id)) {
          _selectedMemberIds.clear();
        } else {
          _selectedMemberIds
            ..clear()
            ..add(id);
        }
        return;
      }

      if (_selectedMemberIds.contains(id)) {
        _selectedMemberIds.remove(id);
      } else {
        _selectedMemberIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    if (_isViewActivityMode) return;

    final list = widget.members.value;

    if (list == null) return;

    final assignable = _assignableMembers(list);

    setState(() {
      if (_isAllSelected) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds
          ..clear()
          ..addAll(assignable.map((m) => m.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color titleInk = const Color(0xFF1F3A44);
    final Color brandBlue = const Color(0xFF5A8B9E);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF7F3EF).withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: widget.members.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error loading members: $err'),
            ),
            data: (membersList) {
              final assignableMembers = _assignableMembers(membersList);
              final assignableIds = assignableMembers
                  .map((member) => member.id)
                  .toSet();
              final selectedAssignableIds = _selectedMemberIds
                  .where((memberId) => assignableIds.contains(memberId))
                  .toSet();
              final canContinue = _isViewActivityMode
                  ? selectedAssignableIds.length == 1
                  : selectedAssignableIds.isNotEmpty;
              final title = _isViewActivityMode
                  ? 'View Activity For...'
                  : 'Assign Task To...';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: brandBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: titleInk,
                        ),
                      ),
                      if (_isViewActivityMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: brandBlue.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Single select',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: brandBlue,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _toggleSelectAll,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isAllSelected
                                  ? brandBlue
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isAllSelected
                                    ? brandBlue.withValues(alpha: 0.7)
                                    : brandBlue.withValues(alpha: 0.25),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              _isAllSelected ? 'Deselect All' : 'Select All',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isAllSelected
                                    ? Colors.white
                                    : brandBlue,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ...assignableMembers.map((member) {
                    final isSelected = selectedAssignableIds.contains(
                      member.id,
                    );

                    // --- LOGICA DI FALLBACK ---
                    final displayName =
                        (member.nickname != null &&
                            member.nickname!.trim().isNotEmpty)
                        ? member.nickname!
                        : (member.profile?.name ?? 'Unknown Member');
                    final displayInitial = displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?';
                    final avatarUrl =
                        member.avatarUrl ?? member.profile?.avatarUrl;

                    return GestureDetector(
                      onTap: () => _toggleSelection(member.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [
                                    const Color(0xFFE3EFF4),
                                    const Color(0xFFF7FAFC),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.88),
                                    Colors.white.withValues(alpha: 0.56),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? brandBlue.withValues(alpha: 0.42)
                                : Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // SOSTITUITO IL CONTAINER CON IL NUOVO WIDGET
                            AvatarImage(
                              avatarUrl: avatarUrl,
                              initial: displayInitial,
                              size: 44,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                displayName,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: titleInk,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? brandBlue
                                  : titleInk.withValues(alpha: 0.35),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (assignableMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No host/cohost/personnel members available',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.withValues(alpha: 0.8),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: !canContinue
                        ? null
                        : () {
                            if (_isViewActivityMode) {
                              final selectedMemberId =
                                  selectedAssignableIds.first;

                              String? selectedUserId;
                              for (final member in assignableMembers) {
                                if (member.id == selectedMemberId) {
                                  selectedUserId = member.userId;
                                  break;
                                }
                              }

                              Navigator.pop(context);
                              Navigator.of(context).pushNamed(
                                AppRouteNames.userTaskHistory,
                                arguments: UserTaskHistoryRouteArgs(
                                  targetMemberId: selectedMemberId,
                                  targetUserId: selectedUserId,
                                ),
                              );
                              return;
                            }

                            String? preselectedAssigneeUserId;
                            if (selectedAssignableIds.length == 1) {
                              for (final member in assignableMembers) {
                                if (selectedAssignableIds.contains(member.id)) {
                                  preselectedAssigneeUserId = member.userId;
                                  break;
                                }
                              }
                            }

                            Navigator.pop(context);
                            Navigator.of(context).pushNamed(
                              AppRouteNames.addTask,
                              arguments: AddTaskRouteArgs(
                                assignedMemberIds: selectedAssignableIds,
                                multiAssignMode: true,
                                preselectedAssigneeUserId:
                                    preselectedAssigneeUserId,
                              ),
                            );
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: !canContinue
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF5A8B9E), Color(0xFF3E6D81)],
                              ),
                        color: !canContinue
                            ? Colors.grey.withValues(alpha: 0.5)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !canContinue
                              ? Colors.white.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.7),
                          width: 1,
                        ),
                        boxShadow: !canContinue
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3E6D81,
                                  ).withValues(alpha: 0.32),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
