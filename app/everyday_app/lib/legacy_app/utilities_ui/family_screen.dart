// TODO migrate to features/personnel
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import '../../features/personnel/data/models/household_member.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  void _openMemberSelectionSheet(
    BuildContext context,
    AsyncValue<List<HouseholdMember>> members,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SelectFamilyMemberSheet(members: members),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = AppContext.instance.userId;
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderIcon(
                      Icons.pets,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouteNames.pets);
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
                    _buildHeaderIcon(
                      Icons.add_rounded,
                      onTap: () =>
                          _openMemberSelectionSheet(context, membersAsync),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // LISTA CARD PREMIUM (MODIFICATA PER IL CLICK)
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (members) {
                    final familyMembers = members.where((member) {
                      final role = member.role.toUpperCase();
                      final isFamilyRole = role == 'HOST' || role == 'COHOST';
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildPremiumFamilyCard(
                            context: context,
                            userId: member.userId,
                            name: member.profile?.name ?? 'Unknown',
                            initial: (member.profile?.name ?? '?').isNotEmpty
                                ? (member.profile?.name ?? '?')[0].toUpperCase()
                                : '?',
                            color: const Color(0xFFF4A261),
                            role: member.role,
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
    required String userId,
    required String name,
    required String role,
    required String initial,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouteNames.userTaskHistory,
          arguments: UserTaskHistoryRouteArgs(targetUserId: userId),
        );
      },
      child: ClipRRect(
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D342C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF3D342C,
                                ).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
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
      ),
    );
  }
}

// ==========================================
// BOTTOM SHEET: SELEZIONA MEMBRI PER TASK
// ==========================================
class SelectFamilyMemberSheet extends StatefulWidget {
  final AsyncValue<List<HouseholdMember>> members;

  const SelectFamilyMemberSheet({super.key, required this.members});

  @override
  State<SelectFamilyMemberSheet> createState() =>
      _SelectFamilyMemberSheetState();
}

class _SelectFamilyMemberSheetState extends State<SelectFamilyMemberSheet> {
  final Set<String> _selectedMemberIds = {};

  bool get _isAllSelected {
    final list = widget.members.value ?? [];
    return _selectedMemberIds.length == list.length;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMemberIds.contains(id)) {
        _selectedMemberIds.remove(id);
      } else {
        _selectedMemberIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    final list = widget.members.value;

    if (list == null) return;

    setState(() {
      if (_isAllSelected) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds.addAll(list.map((m) => m.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color brandBlue = const Color(0xFF5A8B9E);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          // Use .when to handle the AsyncValue state
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
              // 'membersList' is now your actual List<HouseholdMember>
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
                        'Assign Task To...',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: brandBlue,
                        ),
                      ),
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
                                : brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _isAllSelected ? 'Deselect All' : 'Select All',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isAllSelected ? Colors.white : brandBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Map through the actual membersList objects
                  ...membersList.map((member) {
                    final isSelected = _selectedMemberIds.contains(
                      member.id,
                    ); // Changed from member['id']
                    return GestureDetector(
                      onTap: () => _toggleSelection(
                        member.id,
                      ), // Changed from member['id']
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? brandBlue.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? brandBlue.withValues(alpha: 0.5)
                                : Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3D342C),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  member.profile?.name?[0].toUpperCase() ??
                                      '?', // Changed from member['initial']
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                member.profile?.name ??
                                    'Unknown Member', // Changed from member['name']
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D342C),
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? brandBlue
                                  : Colors.grey.withValues(alpha: 0.4),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: _selectedMemberIds.isEmpty
                        ? null
                        : () {
                            String? preselectedAssigneeUserId;
                            if (_selectedMemberIds.length == 1) {
                              for (final member in membersList) {
                                if (_selectedMemberIds.contains(member.id)) {
                                  preselectedAssigneeUserId = member.userId;
                                  break;
                                }
                              }
                            }

                            Navigator.pop(context);
                            Navigator.of(context).pushNamed(
                              AppRouteNames.addTask,
                              arguments: AddTaskRouteArgs(
                                assignedMemberIds: _selectedMemberIds,
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
                        color: _selectedMemberIds.isEmpty
                            ? Colors.grey.withValues(alpha: 0.5)
                            : brandBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedMemberIds.isEmpty
                            ? []
                            : [
                                BoxShadow(
                                  color: brandBlue.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
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
