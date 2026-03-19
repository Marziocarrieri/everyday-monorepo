// TODO migrate to features/household
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/core/runtime/household_runtime_controller.dart';
import 'package:everyday_app/legacy_app/services/profile_data_service.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/core/app_router.dart';

// --- COLORI ---
const _bgColor = Color(0xFFF4F1ED);
const _inkColor = Color(0xFF1F3A44);
const _appTeal = Color(0xFF5A8B9E);   // Teal originale
const _appCoral = Color(0xFFF28482);  // Rosso/Coral originale
const _orangeCardBright = Color(0xFFF4A261); // Arancione card
const _orangeCardDeep = Color(0xFFE76F51);   // Arancione card

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
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _appCoral.withOpacity(0.2),
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
                      color: _appCoral.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_rounded, color: _appCoral, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _inkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _inkColor.withOpacity(0.7),
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
                              border: Border.all(color: _inkColor.withOpacity(0.1), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _inkColor.withOpacity(0.7),
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
                              color: _appCoral,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _appCoral.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                confirmLabel,
                                style: GoogleFonts.manrope(
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

  static Future<void> _applyFallbackAfterActiveRemoval(BuildContext context, WidgetRef ref) async {
    final memberships = await _loadMembershipRows();

    if (memberships.isEmpty) {
      AppContext.instance.setMembership(null);
      AppContext.instance.setActiveHousehold(null);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(AppRouteNames.welcome, (route) => false);
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

    await ref.read(householdRuntimeControllerProvider).switchHousehold(ref, fallbackHouseholdId);
  }

  static Future<void> leaveActiveHousehold(BuildContext context, {required String householdName, required WidgetRef ref}) async {
    final userId = AppContext.instance.userId;
    final activeHouseholdId = AppContext.instance.householdId;
    if (userId == null || activeHouseholdId == null) return;

    final confirmed = await _showConfirmActionDialog(
      context,
      title: 'Leave household',
      message: 'Do you want to leave $householdName?',
      confirmLabel: 'Leave',
    );
    if (!context.mounted || !confirmed) return;

    await _profileDataService.removeMyMembership(householdId: activeHouseholdId, userId: userId);
    if (!context.mounted) return;
    await _applyFallbackAfterActiveRemoval(context, ref);
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Household left', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _appTeal, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static Future<void> deleteActiveHousehold(BuildContext context, {required String householdId, required String householdName, required WidgetRef ref}) async {
    final confirmed = await _showConfirmActionDialog(
      context,
      title: 'Delete household',
      message: 'This will permanently delete $householdName for all members. Continue?',
      confirmLabel: 'Delete',
    );
    if (!context.mounted || !confirmed) return;

    await _profileDataService.removeMembershipsByHousehold(householdId);
    await _profileDataService.deleteHousehold(householdId);
    if (!context.mounted) return;
    await _applyFallbackAfterActiveRemoval(context, ref);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Household deleted', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _appCoral, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ProfileHouseholdBottomSheet extends ConsumerStatefulWidget {
  const _ProfileHouseholdBottomSheet();
  @override
  ConsumerState<_ProfileHouseholdBottomSheet> createState() => _ProfileHouseholdBottomSheetState();
}

class _ProfileHouseholdBottomSheetState extends ConsumerState<_ProfileHouseholdBottomSheet> {
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
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _profileDataService.loadHouseholdsForUser(userId);
      final households = List<Map<String, dynamic>>.from(response).map((row) {
        final household = row['household'] as Map<String, dynamic>?;
        final householdId = row['household_id'] as String?;
        if (household == null || householdId == null) return null;
        final name = (household['name'] as String?)?.trim();
        return _HouseholdOption(
          id: householdId,
          name: (name == null || name.isEmpty) ? 'Unnamed Household' : name,
        );
      }).whereType<_HouseholdOption>().toList();

      if (!mounted) return;
      setState(() => _households = households);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load households', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _appCoral,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _profileDataService.signOut();
      AppContext.instance.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(AppRouteNames.login2, (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString(), style: GoogleFonts.manrope()),
          backgroundColor: _appCoral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoggingOut = false);
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
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: _inkColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Households',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _appTeal, 
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: _appTeal),
                  )
                else ...[
                  for (final household in _households)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: household.id == activeHouseholdId ? _appTeal.withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: household.id == activeHouseholdId ? _appTeal.withOpacity(0.2) : Colors.transparent,
                          width: 1.0,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        leading: Icon(
                          Icons.home_rounded,
                          color: household.id == activeHouseholdId ? _appTeal : _inkColor.withOpacity(0.5),
                          size: 20,
                        ),
                        title: Text(
                          household.name,
                          style: GoogleFonts.manrope(
                            fontWeight: household.id == activeHouseholdId ? FontWeight.w800 : FontWeight.w600,
                            color: _inkColor,
                            fontSize: 15,
                          ),
                        ),
                        trailing: household.id == activeHouseholdId
                            ? const Icon(Icons.check_circle_rounded, color: _appTeal, size: 20)
                            : null,
                        onTap: household.id == activeHouseholdId || isSwitchingHousehold
                            ? null
                            : () async {
                                await ref.read(householdRuntimeControllerProvider).switchHousehold(ref, household.id);
                                if (!mounted) return;
                                Navigator.of(context).pop();
                              },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isSwitchingHousehold
                              ? null
                              : () async {
                                  final rootNavigator = Navigator.of(context, rootNavigator: true);
                                  Navigator.of(context).pop();
                                  await rootNavigator.pushNamed(
                                    AppRouteNames.welcome,
                                    arguments: const WelcomeRouteArgs(fromProfile: true),
                                  );
                                },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _appTeal.withOpacity(0.3), width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_home_rounded, color: _appTeal, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Home',
                                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: _appTeal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoggingOut || isSwitchingHousehold ? null : _logout,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _appCoral.withOpacity(0.3), width: 1.2),
                            ),
                            child: Center(
                              child: _isLoggingOut
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _appCoral, strokeWidth: 2))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.logout_rounded, color: _appCoral, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Logout', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: _appCoral)),
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

  ActiveMembership? get _activeMembership => AppContext.instance.activeMembership;
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
        content: Text(message, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _appTeal, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: _activeMembership?.nickname ?? '');
    AppContext.instance.addListener(_handleAppContextChanged);
    _loadMemberContext();
  }

  Future<void> _loadMemberContext() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) {
      if (mounted) setState(() => _isLoadingMember = false);
      return;
    }
    if (mounted) setState(() => _isLoadingMember = true);
    try {
      await AppContext.instance.reloadMemberContext();
      if (!mounted) return;
      setState(() {
        _nicknameController.text = _activeMembership?.nickname ?? '';
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(), style: GoogleFonts.manrope()), backgroundColor: _appCoral, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoadingMember = false);
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

    if (mounted) setState(() => _isSavingNickname = true);
    try {
      await _profileDataService.updateNickname(membershipId: membershipId, nickname: newNickname);
      await AppContext.instance.reloadMemberContext();
      if (!mounted) return;
      setState(() => _nicknameController.text = _activeMembership?.nickname ?? '');
      _showSuccessSnackBar('Nickname updated');
      if (mounted) setState(() => _editingNickname = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(), style: GoogleFonts.manrope()), backgroundColor: _appCoral, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSavingNickname = false);
    }
  }

  String _generateInviteCode({int length = 8}) {
    final random = Random.secure();
    return List.generate(length, (_) => _inviteAlphabet[random.nextInt(_inviteAlphabet.length)]).join();
  }

  Future<String> _createInviteCode(String householdId, {bool replaceExisting = false}) async {
    if (replaceExisting) await _profileDataService.deleteInviteCodesForHousehold(householdId);
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _generateInviteCode();
      try {
        return await _profileDataService.createInviteCode(householdId: householdId, inviteCode: code);
      } catch (_) {
        if (attempt == 7) rethrow;
      }
    }
    throw Exception('Unable to generate invite code');
  }

  Future<void> _showInviteCodeDialog({required String householdId, required String initialCode}) async {
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
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: _appTeal.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(color: _appTeal.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.qr_code_2_rounded, color: _appTeal, size: 30),
                      ),
                      const SizedBox(height: 20),
                      Text('Invite Code', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: _inkColor)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _inkColor.withOpacity(0.05)),
                        ),
                        child: isRegenerating
                            ? const SizedBox(height: 36, width: 36, child: CircularProgressIndicator(color: _appTeal, strokeWidth: 3))
                            : SelectableText(code, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: _appTeal, letterSpacing: 4)),
                      ),
                      const SizedBox(height: 12),
                      Text('This code remains valid until a new one is generated.', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 13, color: _inkColor.withOpacity(0.5))),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isRegenerating
                                  ? null
                                  : () async {
                                      setDialogState(() => isRegenerating = true);
                                      try {
                                        final newCode = await _createInviteCode(householdId, replaceExisting: true);
                                        setDialogState(() => code = newCode);
                                      } catch (error) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(), style: GoogleFonts.manrope()), backgroundColor: _appCoral));
                                      } finally {
                                        if (dialogBuildContext.mounted) setDialogState(() => isRegenerating = false);
                                      }
                                    },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _inkColor.withOpacity(0.1), width: 1.5),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 18, color: _inkColor.withOpacity(0.7)),
                                      const SizedBox(width: 8),
                                      Text('New Code', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: _inkColor.withOpacity(0.7))),
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
                                    content: Text('Invite code copied!', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: _appTeal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                );
                                Navigator.of(dialogContext).pop();
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _appTeal,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: _appTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('Copy', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                        child: Text('Close', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: _inkColor.withOpacity(0.4))),
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
      final existingCode = await _profileDataService.getInviteCodeForHousehold(householdId);
      final code = (existingCode == null || existingCode.isEmpty) ? await _createInviteCode(householdId) : existingCode;
      if (code == null || code.isEmpty) throw Exception('Invite code is empty');
      await _showInviteCodeDialog(householdId: householdId, initialCode: code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(), style: GoogleFonts.manrope()), backgroundColor: _appCoral));
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
    return Uri.decodeComponent(encodedPath);
  }

  Future<void> _handleAvatarUpload() async {
    final householdId = AppContext.instance.householdId;
    final membershipId = AppContext.instance.membershipId;
    if (householdId == null || membershipId == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (mounted) setState(() => _isUploadingAvatar = true);
    try {
      final Uint8List fileBytes = await pickedFile.readAsBytes();
      final publicUrl = await _profileDataService.uploadAvatar(householdId: householdId, membershipId: membershipId, fileBytes: fileBytes);
      await _profileDataService.updateAvatarUrl(membershipId: membershipId, avatarUrl: publicUrl);
      await _loadMemberContext();
      _showSuccessSnackBar('Avatar updated');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(), style: GoogleFonts.manrope()), backgroundColor: _appCoral));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleAvatarRemove() async {
    final membershipId = AppContext.instance.membershipId;
    final avatarUrl = _activeMembership?.avatarUrl;
    if (membershipId == null || avatarUrl == null || avatarUrl.isEmpty) return;

    if (mounted) setState(() => _isUploadingAvatar = true);
    try {
      final oldPath = _extractAvatarStoragePath(avatarUrl);
      if (oldPath != null) {
        try { await _profileDataService.removeAvatarByPath(oldPath); } catch (_) {}
      }
      await _profileDataService.updateAvatarUrl(membershipId: membershipId, avatarUrl: null);
      await _loadMemberContext();
      _showSuccessSnackBar('Avatar removed');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(), style: GoogleFonts.manrope()), backgroundColor: _appCoral));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _showAvatarOptions() async {
    if (_isUploadingAvatar || !mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final currentAvatarUrl = _activeMembership?.avatarUrl;
        final hasAvatar = currentAvatarUrl != null && currentAvatarUrl.isNotEmpty;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 5, decoration: BoxDecoration(color: _inkColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.of(modalContext).pop('change'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _appTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _appTeal.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera_rounded, color: _appTeal),
                        const SizedBox(width: 16),
                        Text('Change photo', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: _appTeal)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: hasAvatar ? () => Navigator.of(modalContext).pop('remove') : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: hasAvatar ? _appCoral.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hasAvatar ? _appCoral.withOpacity(0.2) : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: hasAvatar ? _appCoral : Colors.grey),
                        const SizedBox(width: 16),
                        Text('Remove photo', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: hasAvatar ? _appCoral : Colors.grey)),
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
    } else if (action == 'remove') {
      await _handleAvatarRemove();
    }
  }

  Future<void> _handleHouseholdSettingsAction() async {
    final membership = _activeMembership;
    final householdId = AppContext.instance.householdId;
    if (membership == null || householdId == null) return;

    final householdName = AppContext.instance.household?.name ?? 'this household';
    final isHost = membership.role.toUpperCase() == 'HOST';

    if (isHost) {
      await _HouseholdRemovalActions.deleteActiveHousehold(context, householdId: householdId, householdName: householdName, ref: ref);
    } else {
      await _HouseholdRemovalActions.leaveActiveHousehold(context, householdName: householdName, ref: ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppContext.instance.profile;
    final householdId = AppContext.instance.householdId;
    if (householdId == null || profile == null) {
      return Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Session context not ready', style: GoogleFonts.manrope(color: _inkColor))));
    }
    if (_isLoadingMember) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: _appTeal)));
    }

    final nickname = _activeMembership?.nickname;
    final role = _activeMembership?.role ?? 'Member';
    final isPersonnel = role.toUpperCase() == 'PERSONNEL';
    final avatarUrl = _activeMembership?.avatarUrl;
    final globalName = profile.name ?? 'Unknown User';

    return Scaffold(
      backgroundColor: _bgColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _inkColor, size: 22),
          splashRadius: 24,
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _inkColor, 
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // --- 1. PROFILE CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_orangeCardBright, _orangeCardDeep],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _orangeCardBright.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                                  ),
                                  child: ClipOval(
                                    child: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? Image.network(
                                            _cacheBustedAvatarUrl(avatarUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildInitials(globalName, fontSize: 42),
                                          )
                                        : _buildInitials(globalName, fontSize: 42),
                                  ),
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isUploadingAvatar
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _orangeCardDeep))
                                        : const Icon(Icons.edit_rounded, color: _orangeCardDeep, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // --- FIX ALLINEAMENTO NICKNAME ---
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40), 
                                child: _editingNickname
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                                        ),
                                        child: TextField(
                                          controller: _nicknameController,
                                          autofocus: true,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                                            hintText: 'Nickname',
                                            hintStyle: TextStyle(color: Colors.white54),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        (nickname != null && nickname.isNotEmpty) ? nickname : 'Add Nickname',
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.manrope(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    if (_editingNickname) {
                                      if (!_isSavingNickname) _handleNicknameEdit();
                                    } else {
                                      setState(() => _editingNickname = true);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _editingNickname ? Colors.white : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                                    ),
                                    child: _editingNickname
                                        ? (_isSavingNickname
                                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _orangeCardBright))
                                            : const Icon(Icons.check_rounded, color: _orangeCardBright, size: 14))
                                        : const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role.toUpperCase(), // Rimossa la stringa col nome globale
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'Household Menu',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _inkColor.withOpacity(0.5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _inkColor.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!isPersonnel) ...[
                            _buildSettingsRow(
                              icon: Icons.fastfood_outlined,
                              iconColor: _appTeal, 
                              text: 'Your Diet',
                              onTap: () => Navigator.of(context).pushNamed(AppRouteNames.diet),
                            ),
                            Divider(height: 1, indent: 64, color: _inkColor.withOpacity(0.05)),
                          ],
                          _buildSettingsRow(
                            icon: Icons.other_houses_outlined,
                            iconColor: _appTeal,
                            text: 'Your Home',
                            onTap: () => AppRouter.navigate(context, AppRouteNames.yourHome),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30), 
                  ],
                ),
              ),
            ),

            // --- BOTTONI AZIONE ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              color: _bgColor, 
              child: Row(
                children: [
                  if (!isPersonnel) ...[
                    Expanded(
                      child: _buildActionPill(
                        icon: Icons.person_add_alt_1_rounded,
                        text: 'Invite',
                        color: _appTeal, // CAMBIATO IN AZZURRO TEAL
                        onTap: _handleInviteMember,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: _buildActionPill(
                      icon: Icons.exit_to_app_rounded,
                      text: (_activeMembership?.role.toUpperCase() == 'HOST') ? 'Delete' : 'Leave',
                      color: _appCoral, 
                      onTap: _handleHouseholdSettingsAction,
                      isOutline: true,
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

  Widget _buildInitials(String name, {double fontSize = 32}) {
    return Center(
      child: Text(
        _initialFromName(name),
        style: GoogleFonts.manrope(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSettingsRow({required IconData icon, required Color iconColor, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _inkColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _inkColor.withOpacity(0.3), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill({required IconData icon, required String text, required Color color, required VoidCallback onTap, bool isOutline = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isOutline ? [] : [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isOutline ? color : Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isOutline ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}