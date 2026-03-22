// TODO migrate to features/personnel
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/shared/widgets/main_tab_screen_background.dart';
import '../../features/personnel/data/models/household_member.dart';
// IMPORTA IL NUOVO WIDGET CONDIVISO
import 'package:everyday_app/shared/widgets/avatar_image.dart';

enum FamilyMemberSelectionFlowMode { addTask, viewActivity }

const _familyInk = Color(0xFF1F3A44);
const _familyAccent = Color(0xFF5A8B9E);
const _familyActionInk = Color(0xFF1F3A44);
const _memberCardSurfacePalette = <List<Color>>[
  [Color(0xFF6794AA), Color(0xFF2F4858)],
  [Color(0xFFD8AD90), Color(0xFFB06F59)],
  [Color(0xFF78A7A3), Color(0xFF56817D)],
  [Color(0xFFD8AD90), Color(0xFFB06F59)],
  [Color(0xFFC7A15A), Color(0xFF8F6A33)],
  [Color(0xFF8D79A6), Color(0xFF5C4A78)],
];

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
                _buildFamilyHeader(context: context, isHost: isHost),
                const SizedBox(height: 24),

                Expanded(
                  child: membersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        'Error: $error',
                        style: GoogleFonts.manrope(
                          color: _familyInk.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                        return _buildEmptyState(message: 'No members found');
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
                            padding: EdgeInsets.only(
                              bottom: index == familyMembers.length - 1
                                  ? 8
                                  : 14,
                            ),
                            child: _buildPremiumFamilyCard(
                              context: context,
                              memberId: member.id,
                              userId: member.userId,
                              name: displayName,
                              initial: displayInitial,
                              avatarUrl: avatarUrl, // PASSATO ALLA CARD
                              surfaceColors:
                                  _memberCardSurfacePalette[index %
                                      _memberCardSurfacePalette.length],
                              role: member.role,
                              isPersonnel: isPersonnel,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (isHost) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: _buildMultiassignButton(
                      onTap: () {
                        openFamilyMemberSelectionSheet(context, membersAsync);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyHeader({
    required BuildContext context,
    required bool isHost,
  }) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          _buildHeaderIcon(
            icon: isHost
                ? Icons.pets_rounded
                : Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (isHost) {
                Navigator.of(context).pushNamed(AppRouteNames.pets);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                'Family',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _familyInk,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: _familyInk, size: 26),
      splashRadius: 22,
      tooltip: tooltip,
    );
  }

  Widget _buildMultiassignButton({VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _familyActionInk.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_ind_rounded,
                size: 18,
                color: _familyActionInk,
              ),
              const SizedBox(width: 7),
              Text(
                'Multiassign',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _familyActionInk,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_2_rounded,
            size: 52,
            color: _familyAccent.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.manrope(
              color: _familyInk.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
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
    required List<Color> surfaceColors,
    required bool isPersonnel,
    String? avatarUrl,
  }) {
    Widget cardContent = ClipRRect(
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
              colors: surfaceColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: surfaceColors.first.withValues(alpha: 0.3),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                color: Colors.white, // <-- MODIFICATO IN BIANCO
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                color: Colors.white.withValues(alpha: 0.75), // <-- MODIFICATO IN BIANCO OPACO
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
              if (!isPersonnel) ...[
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  color: const Color(0xFFF8F1E8).withValues(alpha: 0.22),
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
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white, // <-- MODIFICATO IN BIANCO
                            size: 18,
                          ),
                          Text(
                            'View\nActivity',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: Colors.white, // <-- MODIFICATO IN BIANCO
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
            ],
          ),
        ),
      ),
    );

    if (isPersonnel) {
      return cardContent;
    }

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