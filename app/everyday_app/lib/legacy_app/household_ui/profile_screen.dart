// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/runtime/household_runtime_controller.dart';
import 'package:everyday_app/legacy_app/services/profile_data_service.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/core/app_router.dart';

void showProfileHouseholdBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ProfileHouseholdBottomSheet(),
  );
}

class _HouseholdOption {
  final String id;
  final String name;

  const _HouseholdOption({required this.id, required this.name});
}

class _HouseholdRemovalActions {
  static final ProfileDataService _profileDataService = ProfileDataService();

  static Future<List<Map<String, dynamic>>> _loadMembershipRows() async {
    final userId = AppContext.instance.userId;
    if (userId == null) return const [];

    return _profileDataService.loadMembershipRows(userId);
  }

  // --- DIALOG DI CONFERMA PREMIUM ---
  static Future<bool> _showConfirmActionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF28482).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF28482).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFF28482),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D342C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D342C).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(false),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF3D342C,
                                ).withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(
                                    0xFF3D342C,
                                  ).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(true),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF28482),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF28482,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                confirmLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return confirmed ?? false;
  }

  static Future<void> _applyFallbackAfterActiveRemoval(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final memberships = await _loadMembershipRows();

    if (memberships.isEmpty) {
      AppContext.instance.setMembership(null);
      AppContext.instance.setActiveHousehold(null);

      if (!context.mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(AppRouteNames.welcome, (route) => false);
      return;
    }

    final fallback = memberships.first;
    final fallbackMembershipId = fallback['id'] as String?;
    final fallbackHouseholdId = fallback['household_id'] as String?;

    AppContext.instance.setMembership(fallbackMembershipId);
    if (fallbackHouseholdId == null || fallbackHouseholdId.isEmpty) {
      AppContext.instance.setActiveHousehold(null);
      return;
    }

    await ref
        .read(householdRuntimeControllerProvider)
        .switchHousehold(ref, fallbackHouseholdId);
  }

  static Future<void> leaveActiveHousehold(
    BuildContext context, {
    required String householdName,
    required WidgetRef ref,
  }) async {
    final userId = AppContext.instance.userId;
    final activeHouseholdId = AppContext.instance.householdId;

    if (userId == null || activeHouseholdId == null) {
      return;
    }

    final confirmed = await _showConfirmActionDialog(
      context,
      title: 'Leave household',
      message: 'Do you want to leave $householdName?',
      confirmLabel: 'Leave',
    );
    if (!context.mounted) return;
    if (!confirmed) return;

    await _profileDataService.removeMyMembership(
      householdId: activeHouseholdId,
      userId: userId,
    );

    if (!context.mounted) return;
    await _applyFallbackAfterActiveRemoval(context, ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Household left',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5A8B9E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static Future<void> deleteActiveHousehold(
    BuildContext context, {
    required String householdId,
    required String householdName,
    required WidgetRef ref,
  }) async {
    final confirmed = await _showConfirmActionDialog(
      context,
      title: 'Delete household',
      message:
          'This will permanently delete $householdName for all members. Continue?',
      confirmLabel: 'Delete',
    );
    if (!context.mounted) return;
    if (!confirmed) return;

    await _profileDataService.removeMembershipsByHousehold(householdId);
    await _profileDataService.deleteHousehold(householdId);

    if (!context.mounted) return;
    await _applyFallbackAfterActiveRemoval(context, ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Household deleted',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFF28482),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ProfileHouseholdBottomSheet extends ConsumerStatefulWidget {
  const _ProfileHouseholdBottomSheet();

  @override
  ConsumerState<_ProfileHouseholdBottomSheet> createState() =>
      _ProfileHouseholdBottomSheetState();
}

class _ProfileHouseholdBottomSheetState
    extends ConsumerState<_ProfileHouseholdBottomSheet> {
  final ProfileDataService _profileDataService = ProfileDataService();

  List<_HouseholdOption> _households = const [];
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    AppContext.instance.addListener(_handleAppContextChanged);
    _loadHouseholds();
  }

  @override
  void dispose() {
    AppContext.instance.removeListener(_handleAppContextChanged);
    super.dispose();
  }

  void _handleAppContextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadHouseholds() async {
    final userId = AppContext.instance.userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _profileDataService.loadHouseholdsForUser(userId);

      final households = List<Map<String, dynamic>>.from(response)
          .map((row) {
            final household = row['household'] as Map<String, dynamic>?;
            final householdId = row['household_id'] as String?;

            if (household == null || householdId == null) {
              return null;
            }

            final name = (household['name'] as String?)?.trim();
            return _HouseholdOption(
              id: householdId,
              name: (name == null || name.isEmpty) ? 'Unnamed Household' : name,
            );
          })
          .whereType<_HouseholdOption>()
          .toList();

      if (!mounted) return;
      setState(() {
        _households = households;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load households',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF28482),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGICA DI LOGOUT ---
  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _profileDataService.signOut();
      AppContext.instance.clear();

      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(AppRouteNames.login2, (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFF28482),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeHouseholdId = AppContext.instance.householdId;
    final isSwitchingHousehold = ref.watch(isSwitchingHouseholdProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D342C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Households',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A8B9E),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: Color(0xFF5A8B9E)),
                  )
                else ...[
                  for (final household in _households)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: household.id == activeHouseholdId
                            ? const Color(0xFF5A8B9E).withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: household.id == activeHouseholdId
                              ? const Color(0xFF5A8B9E).withValues(alpha: 0.2)
                              : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        leading: Icon(
                          Icons.home_rounded,
                          color: household.id == activeHouseholdId
                              ? const Color(0xFF5A8B9E)
                              : const Color(0xFF3D342C).withValues(alpha: 0.5),
                          size: 20,
                        ),
                        title: Text(
                          household.name,
                          style: GoogleFonts.poppins(
                            fontWeight: household.id == activeHouseholdId
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: const Color(0xFF3D342C),
                            fontSize: 15,
                          ),
                        ),
                        trailing: household.id == activeHouseholdId
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF5A8B9E),
                                size: 20,
                              )
                            : null,
                        onTap:
                            household.id == activeHouseholdId ||
                                    isSwitchingHousehold
                                ? null
                                : () async {
                                    await ref
                                        .read(householdRuntimeControllerProvider)
                                        .switchHousehold(ref, household.id);
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // --- BOTTONI AFFIANCATI: ADD HOME & LOGOUT ---
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isSwitchingHousehold
                              ? null
                              : () async {
                                  final rootNavigator = Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  );
                                  Navigator.of(context).pop();
                                  await rootNavigator.pushNamed(
                                    AppRouteNames.welcome,
                                    arguments: const WelcomeRouteArgs(
                                      fromProfile: true,
                                    ),
                                  );
                                },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF5A8B9E,
                                ).withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_home_rounded,
                                  color: Color(0xFF5A8B9E),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Home',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5A8B9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoggingOut || isSwitchingHousehold
                              ? null
                              : _logout,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFF28482,
                                ).withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: _isLoggingOut
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFF28482),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.logout_rounded,
                                          color: Color(0xFFF28482),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Logout',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFF28482),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ProfileDataService _profileDataService = ProfileDataService();

  bool _isLoadingMember = true;
  bool _isUploadingAvatar = false;
  bool _editingNickname = false;
  bool _isSavingNickname = false;
  int? _avatarCacheBuster;
  late TextEditingController _nicknameController;

  ActiveMembership? get _activeMembership =>
      AppContext.instance.activeMembership;

  static const String _inviteAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  void _handleAppContextChanged() {
    if (!mounted) return;

    if (!_editingNickname) {
      final nickname = _activeMembership?.nickname;
      _nicknameController.text = nickname ?? '';
    }

    setState(() {});
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5A8B9E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: _activeMembership?.nickname ?? '',
    );
    AppContext.instance.addListener(_handleAppContextChanged);
    _loadMemberContext();
  }

  Future<void> _loadMemberContext() async {
    final membershipId = AppContext.instance.membershipId;

    if (membershipId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingMember = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingMember = true;
      });
    }

    try {
      await AppContext.instance.reloadMemberContext();

      if (!mounted) return;
      setState(() {
        _nicknameController.text = _activeMembership?.nickname ?? '';
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFF28482),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMember = false;
        });
      }
    }
  }

  @override
  void dispose() {
    AppContext.instance.removeListener(_handleAppContextChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  String _initialFromName(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

  Future<void> _handleNicknameEdit() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) return;

    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isSavingNickname = true;
    });

    try {
      await _profileDataService.updateNickname(
        membershipId: membershipId,
        nickname: newNickname,
      );

      await AppContext.instance.reloadMemberContext();
      if (!mounted) return;
      setState(() {
        _nicknameController.text = _activeMembership?.nickname ?? '';
      });
      _showSuccessSnackBar('Nickname updated');
      if (!mounted) return;
      setState(() {
        _editingNickname = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFF28482),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNickname = false;
        });
      }
    }
  }

  String _generateInviteCode({int length = 8}) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _inviteAlphabet[random.nextInt(_inviteAlphabet.length)],
    ).join();
  }

  Future<String> _createInviteCode(
    String householdId, {
    bool replaceExisting = false,
  }) async {
    if (replaceExisting) {
      await _profileDataService.deleteInviteCodesForHousehold(householdId);
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _generateInviteCode();
      try {
        return await _profileDataService.createInviteCode(
          householdId: householdId,
          inviteCode: code,
        );
      } catch (_) {
        if (attempt == 7) rethrow;
      }
    }

    throw Exception('Unable to generate invite code');
  }

  // --- DIALOG INVITE CODE PREMIUM ---
  Future<void> _showInviteCodeDialog({
    required String householdId,
    required String initialCode,
  }) async {
    var code = initialCode;
    var isRegenerating = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A8B9E).withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: Color(0xFF5A8B9E),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Invite Code',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3D342C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.05),
                          ),
                        ),
                        child: isRegenerating
                            ? const SizedBox(
                                height: 36,
                                width: 36,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF5A8B9E),
                                  strokeWidth: 3,
                                ),
                              )
                            : SelectableText(
                                code,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF5A8B9E),
                                  letterSpacing: 4,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This code remains valid until a new one is generated.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF3D342C).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isRegenerating
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isRegenerating = true;
                                      });
                                      try {
                                        final newCode = await _createInviteCode(
                                          householdId,
                                          replaceExisting: true,
                                        );
                                        setDialogState(() {
                                          code = newCode;
                                        });
                                      } catch (error) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              error.toString(),
                                              style: GoogleFonts.poppins(),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: const Color(
                                              0xFFF28482,
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (dialogBuildContext.mounted) {
                                          setDialogState(() {
                                            isRegenerating = false;
                                          });
                                        }
                                      }
                                    },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF3D342C,
                                    ).withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                        color: const Color(
                                          0xFF3D342C,
                                        ).withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'New Code',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(
                                            0xFF3D342C,
                                          ).withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invite code copied!',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF5A8B9E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                );
                                Navigator.of(dialogContext).pop();
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A8B9E),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF5A8B9E,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.copy_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Copy',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleInviteMember() async {
    final householdId = AppContext.instance.householdId;
    if (householdId == null) return;

    try {
      final existingCode = await _profileDataService.getInviteCodeForHousehold(
        householdId,
      );

      final code = (existingCode == null || existingCode.isEmpty)
          ? await _createInviteCode(householdId)
          : existingCode;

      if (code == null || code.isEmpty) {
        throw Exception('Invite code is empty');
      }

      await _showInviteCodeDialog(householdId: householdId, initialCode: code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF28482),
        ),
      );
    }
  }

  String _cacheBustedAvatarUrl(String url) {
    final timestamp = _avatarCacheBuster;
    if (timestamp == null) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$timestamp';
  }

  String? _extractAvatarStoragePath(String? publicUrl) {
    if (publicUrl == null || publicUrl.isEmpty) return null;

    const marker = '/object/public/avatars/';
    final markerIndex = publicUrl.indexOf(marker);
    if (markerIndex == -1) return null;

    final start = markerIndex + marker.length;
    final queryIndex = publicUrl.indexOf('?', start);
    final end = queryIndex == -1 ? publicUrl.length : queryIndex;
    final encodedPath = publicUrl.substring(start, end);
    if (encodedPath.isEmpty) return null;

    return Uri.decodeComponent(encodedPath);
  }

  Future<void> _handleAvatarUpload() async {
    final householdId = AppContext.instance.householdId;
    final membershipId = AppContext.instance.membershipId;

    if (householdId == null || membershipId == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final Uint8List fileBytes = await pickedFile.readAsBytes();
      final publicUrl = await _profileDataService.uploadAvatar(
        householdId: householdId,
        membershipId: membershipId,
        fileBytes: fileBytes,
      );
      await _profileDataService.updateAvatarUrl(
        membershipId: membershipId,
        avatarUrl: publicUrl,
      );

      await _loadMemberContext();
      if (!mounted) return;
      setState(() {
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
      _showSuccessSnackBar('Avatar updated');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFF28482),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleAvatarRemove() async {
    final membershipId = AppContext.instance.membershipId;
    final avatarUrl = _activeMembership?.avatarUrl;
    if (membershipId == null || avatarUrl == null || avatarUrl.isEmpty) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final oldPath = _extractAvatarStoragePath(avatarUrl);
      if (oldPath != null) {
        try {
          await _profileDataService.removeAvatarByPath(oldPath);
        } catch (_) {}
      }

      await _profileDataService.updateAvatarUrl(
        membershipId: membershipId,
        avatarUrl: null,
      );

      await _loadMemberContext();
      if (!mounted) return;
      setState(() {
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
      _showSuccessSnackBar('Avatar removed');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFF28482),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  // --- OPZIONI AVATAR PREMIUM ---
  Future<void> _showAvatarOptions() async {
    if (_isUploadingAvatar || !mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final currentAvatarUrl = _activeMembership?.avatarUrl;
        final hasAvatar =
            currentAvatarUrl != null && currentAvatarUrl.isNotEmpty;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D342C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.of(modalContext).pop('change'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A8B9E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5A8B9E).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_rounded,
                          color: Color(0xFF5A8B9E),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Change photo',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A8B9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: hasAvatar
                      ? () => Navigator.of(modalContext).pop('remove')
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: hasAvatar
                          ? const Color(0xFFF28482).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasAvatar
                            ? const Color(0xFFF28482).withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: hasAvatar
                              ? const Color(0xFFF28482)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Remove photo',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: hasAvatar
                                ? const Color(0xFFF28482)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'change') {
      await _handleAvatarUpload();
      return;
    }

    if (action == 'remove') {
      await _handleAvatarRemove();
    }
  }

  Future<void> _handleHouseholdSettingsAction() async {
    final membership = _activeMembership;
    final membershipId = AppContext.instance.membershipId;
    final userId = AppContext.instance.userId;
    final householdId = AppContext.instance.householdId;
    if (membership == null || householdId == null) return;

    debugPrint(
      'LEAVE UI MEMBERSHIP ID: membership_id=$membershipId user_id=$userId household_id=$householdId',
    );

    final householdName =
        AppContext.instance.household?.name ?? 'this household';
    final isHost = membership.role.toUpperCase() == 'HOST';

    if (isHost) {
      await _HouseholdRemovalActions.deleteActiveHousehold(
        context,
        householdId: householdId,
        householdName: householdName,
        ref: ref,
      );
      return;
    }

    await _HouseholdRemovalActions.leaveActiveHousehold(
      context,
      householdName: householdName,
      ref: ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppContext.instance.profile;
    final householdId = AppContext.instance.householdId;
    if (householdId == null || profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Session context not ready',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }

    if (_isLoadingMember) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5A8B9E)),
        ),
      );
    }

    final nickname = _activeMembership?.nickname;
    final role = _activeMembership?.role ?? 'Member';
    final isHost = role.toUpperCase() == 'HOST';
    
    // --- VARIABILE AGGIUNTA PER IL PERSONNEL ---
    final isPersonnel = role.toUpperCase() == 'PERSONNEL'; 
    
    final avatarUrl = _activeMembership?.avatarUrl;

    // --- MODIFICA NOME VISUALIZZATO ---
    // NOME GLOBALE
    final globalName = profile.name ?? 'Unknown User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // HEADER PREMIUM BLOCCATO
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5A8B9E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // CORPO DELLA PAGINA SCROLLABILE
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10.0,
                ),
                child: Column(
                  children: [
                    // --- 🌟 CARD INFO UTENTE SUPER PREMIUM (STILE FLUTTUANTE) 🌟 ---
                    // Aggiungiamo un padding top per far spazio all'avatar che esce
                    Padding(
                      padding: const EdgeInsets.only(top: 35.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // 1. LA CARD BIANCA (Sfondo)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                width: double
                                    .infinity, // Occupa tutta la larghezza disponibile
                                padding: const EdgeInsets.only(
                                  top: 50,
                                  bottom: 24,
                                  left: 16,
                                  right: 16,
                                ), // Padding top grande per l'avatar
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.95),
                                      Colors.white.withValues(alpha: 0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF5A8B9E,
                                      ).withValues(alpha: 0.10),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // 1. NOME GLOBALE (Fisso)
                                    Text(
                                      globalName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF3D342C),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // 2. NICKNAME (Modificabile inline)
                                    _editingNickname
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF5A8B9E,
                                                ).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _nicknameController,
                                              autofocus: true,
                                              textAlign: TextAlign
                                                  .center, // Centra il testo mentre scrivi
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                                hintText: 'Enter nickname...',
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF3D342C),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            (nickname != null && nickname.isNotEmpty)
                                                ? '"$nickname"'
                                                : 'Tap edit to add nickname',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.italic,
                                              color: const Color(0xFF3D342C).withValues(alpha: 0.6),
                                            ),
                                          ),

                                    const SizedBox(height: 12),

                                    // 3. RUOLO CENTRATO SOTTO TUTTO
                                    Text(
                                      role.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(
                                          0xFF5A8B9E,
                                        ), // Blu premium
                                        letterSpacing:
                                            2.0, // Molto spaziato per l'eleganza
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // L'AVATAR FLUTTUANTE (Centrato in alto)
                          Positioned(
                            top:
                                -35, // Metà dell'altezza (70/2) per farlo sbordare perfettamente
                            child: GestureDetector(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _showAvatarOptions,
                              child: Container(
                                width: 70, // Dimensione ridotta come richiesto
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3D342C),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5A8B9E).withValues(
                                        alpha: 0.4,
                                      ), // Glow azzurrino
                                      blurRadius: 20,
                                      spreadRadius: 2, // Espande un po' il glow
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: ClipOval(
                                        child:
                                            avatarUrl != null &&
                                                    avatarUrl.isNotEmpty
                                                ? Image.network(
                                                    _cacheBustedAvatarUrl(
                                                      avatarUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          error,
                                                          stackTrace,
                                                        ) => Center(
                                                          child: Text(
                                                            _initialFromName(
                                                              globalName, // Usiamo globalName qui
                                                            ),
                                                            style:
                                                                GoogleFonts.poppins(
                                                              fontSize: 26,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                      _initialFromName(globalName), // Usiamo globalName qui
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 26,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    if (_isUploadingAvatar)
                                      const Positioned.fill(
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // LA MATITA DI MODIFICA (In alto a destra della card)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                if (_editingNickname) {
                                  if (!_isSavingNickname) _handleNicknameEdit();
                                } else {
                                  setState(() {
                                    _editingNickname = true;
                                    _nicknameController.text =
                                        _activeMembership?.nickname ?? '';
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _editingNickname
                                      ? const Color(0xFF5A8B9E)
                                      : Colors.white.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _editingNickname
                                        ? const Color(0xFF5A8B9E)
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    if (_editingNickname)
                                      BoxShadow(
                                        color: const Color(
                                          0xFF5A8B9E,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: _editingNickname
                                    ? (_isSavingNickname
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ))
                                    : const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF3D342C),
                                        size: 16,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // BOTTONI PREMIUM
                    // --- LOGICA NASCOSTA PER PERSONNEL ---
                    if (!isPersonnel) ...[
                      _buildPremiumMenuButton(
                        icon: Icons.fastfood_outlined,
                        text: 'Your Diet',
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouteNames.diet);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildPremiumMenuButton(
                      icon: Icons.receipt_long_rounded,
                      text: 'Your Home',
                      onTap: () {
                        showProfileHouseholdBottomSheet(context); 
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- HOUSEHOLD SETTINGS (INVITE & DELETE AFFIANCATI) ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                        child: Text(
                          'Household Settings',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Bottone Invite (MOSTRATO SOLO SE NON SEI PERSONNEL)
                        if (!isPersonnel) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleInviteMember,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF5A8B9E,
                                    ).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF5A8B9E,
                                      ).withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      color: Color(0xFF5A8B9E),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Invite',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5A8B9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        
                        // Bottone Leave/Delete (MOSTRATO A TUTTI)
                        Expanded(
                          child: GestureDetector(
                            onTap: _handleHouseholdSettingsAction,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF28482,
                                  ).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF28482,
                                    ).withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.exit_to_app_rounded,
                                    color: Color(0xFFF28482),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (_activeMembership?.role.toUpperCase() ==
                                            'HOST')
                                        ? 'Delete'
                                        : 'Leave',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF28482),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // --- TRUCCHETTO: Spazio vuoto per il Personnel ---
                        // Previene che il bottone Leave si allarghi su tutta la riga
                        if (isPersonnel) ...[
                          const SizedBox(width: 16),
                          const Spacer(),
                        ],
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ), // Margine inferiore per lo scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTONI GRANDI PREMIUM ---
  Widget _buildPremiumMenuButton({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: const Color(0xFF5A8B9E), size: 28),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D342C),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF5A8B9E).withValues(alpha: 0.5),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}