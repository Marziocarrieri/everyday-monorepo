import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_context.dart';
import 'login2_screen.dart';
import 'diet_screen.dart';
import 'your_home_screen.dart';
import 'welcome_screen.dart';

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

  const _HouseholdOption({
    required this.id,
    required this.name,
  });
}

class _HouseholdRemovalActions {
  static Future<List<Map<String, dynamic>>> _loadMembershipRows() async {
    final userId = AppContext.instance.userId;
    if (userId == null) return const [];

    final response = await Supabase.instance.client
        .from('household_member')
        .select('id, household_id, role')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
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
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  static Future<void> _applyFallbackAfterActiveRemoval(
    BuildContext context,
  ) async {
    final memberships = await _loadMembershipRows();

    if (memberships.isEmpty) {
      AppContext.instance.setMembership(null);
      AppContext.instance.setActiveHousehold(null);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(fromProfile: false),
        ),
        (route) => false,
      );
      return;
    }

    final fallback = memberships.first;
    final fallbackMembershipId = fallback['id'] as String?;
    final fallbackHouseholdId = fallback['household_id'] as String?;

    AppContext.instance.setMembership(fallbackMembershipId);
    AppContext.instance.setActiveHousehold(fallbackHouseholdId);
    await AppContext.instance.reloadMemberContext();
  }

  static Future<void> leaveActiveHousehold(
    BuildContext context, {
    required String householdName,
  }) async {
    final membershipId = AppContext.instance.membershipId;
    final activeHouseholdId = AppContext.instance.householdId;

    if (membershipId == null || activeHouseholdId == null) return;

    final confirmed = await _showConfirmActionDialog(
      context,
      title: 'Leave household',
      message: 'Do you want to leave $householdName?',
      confirmLabel: 'Leave',
    );
    if (!context.mounted) return;
    if (!confirmed) return;

    await Supabase.instance.client
        .from('household_member')
        .delete()
        .eq('id', membershipId);

    if (!context.mounted) return;
    await _applyFallbackAfterActiveRemoval(context);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Household left'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> deleteActiveHousehold(
    BuildContext context, {
    required String householdId,
    required String householdName,
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

    await Supabase.instance.client
        .from('household_member')
        .delete()
        .eq('household_id', householdId);

    await Supabase.instance.client
        .from('household')
        .delete()
        .eq('id', householdId);

    if (!context.mounted) return;
    await _applyFallbackAfterActiveRemoval(context);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Household deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProfileHouseholdBottomSheet extends StatefulWidget {
  const _ProfileHouseholdBottomSheet();

  @override
  State<_ProfileHouseholdBottomSheet> createState() =>
      _ProfileHouseholdBottomSheetState();
}

class _ProfileHouseholdBottomSheetState
    extends State<_ProfileHouseholdBottomSheet> {
  List<_HouseholdOption> _households = const [];
  bool _isLoading = true;

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
      final response = await Supabase.instance.client
          .from('household_member')
          .select('household_id, household(id, name)')
          .eq('user_id', userId);

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
        const SnackBar(
          content: Text('Unable to load households'),
          behavior: SnackBarBehavior.floating,
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


  @override
  Widget build(BuildContext context) {
    final activeHouseholdId = AppContext.instance.householdId;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Households',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5A8B9E),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                )
              else ...[
                for (final household in _households)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: household.id == activeHouseholdId
                          ? const Color(0xFF5A8B9E).withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.home_rounded,
                        color: Color(0xFF5A8B9E),
                      ),
                      title: Text(
                        household.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      trailing: household.id == activeHouseholdId
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF5A8B9E),
                            )
                          : null,
                      onTap: household.id == activeHouseholdId
                          ? null
                          : () {
                              AppContext.instance.setActiveHousehold(
                                household.id,
                              );
                              Navigator.of(context).pop();
                            },
                    ),
                  ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final rootNavigator = Navigator.of(
                        context,
                        rootNavigator: true,
                      );
                      Navigator.of(context).pop();
                      await rootNavigator.push(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(fromProfile: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text('Add Home'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      AppContext.instance.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login2Screen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
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
      await Supabase.instance.client
          .from('household_member')
          .update({'nickname': newNickname})
          .eq('id', membershipId);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
      await Supabase.instance.client
          .from('household_invite')
          .delete()
          .eq('household_id', householdId);
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _generateInviteCode();
      try {
        final inserted = await Supabase.instance.client
            .from('household_invite')
            .insert({'household_id': householdId, 'invite_code': code})
            .select('invite_code')
            .single();

        final inviteCode = inserted['invite_code'] as String?;
        if (inviteCode == null || inviteCode.isEmpty) {
          throw Exception('Invite code creation failed');
        }
        return inviteCode;
      } catch (_) {
        if (attempt == 7) rethrow;
      }
    }

    throw Exception('Unable to generate invite code');
  }

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
            return AlertDialog(
              title: const Text('Invite code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(
                    code,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This code remains valid until a new one is generated.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite code copied'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: isRegenerating
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error.toString()),
                                      behavior: SnackBarBehavior.floating,
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
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Regenerate'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
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
      final existing = await Supabase.instance.client
          .from('household_invite')
          .select('invite_code')
          .eq('household_id', householdId)
          .maybeSingle();

      final code = existing == null
          ? await _createInviteCode(householdId)
          : (Map<String, dynamic>.from(existing)['invite_code'] as String?);

      if (code == null || code.isEmpty) {
        throw Exception('Invite code is empty');
      }

      await _showInviteCodeDialog(householdId: householdId, initialCode: code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$householdId/$membershipId/$timestamp.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      await Supabase.instance.client
          .from('household_member')
          .update({'avatar_url': publicUrl})
          .eq('id', membershipId);

      await _loadMemberContext();
      if (!mounted) return;
      setState(() {
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
      _showSuccessSnackBar('Avatar updated');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
          await Supabase.instance.client.storage.from('avatars').remove([
            oldPath,
          ]);
        } catch (_) {}
      }

      await Supabase.instance.client
          .from('household_member')
          .update({'avatar_url': null})
          .eq('id', membershipId);

      await _loadMemberContext();
      if (!mounted) return;
      setState(() {
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
      _showSuccessSnackBar('Avatar removed');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _showAvatarOptions() async {
    if (_isUploadingAvatar || !mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (modalContext) {
        final currentAvatarUrl = _activeMembership?.avatarUrl;
        final hasAvatar =
            currentAvatarUrl != null && currentAvatarUrl.isNotEmpty;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Change photo'),
                onTap: () => Navigator.of(modalContext).pop('change'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                enabled: hasAvatar,
                onTap: hasAvatar
                    ? () => Navigator.of(modalContext).pop('remove')
                    : null,
              ),
            ],
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
    final householdId = AppContext.instance.householdId;
    if (membership == null || householdId == null) return;

    final householdName = AppContext.instance.household?.name ?? 'this household';
    final isHost = membership.role.toUpperCase() == 'HOST';

    if (isHost) {
      await _HouseholdRemovalActions.deleteActiveHousehold(
        context,
        householdId: householdId,
        householdName: householdName,
      );
      return;
    }

    await _HouseholdRemovalActions.leaveActiveHousehold(
      context,
      householdName: householdName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppContext.instance.profile;
    final householdId = AppContext.instance.householdId;
    if (householdId == null || profile == null) {
      return const Scaffold(
        body: Center(child: Text('Session context not ready')),
      );
    }

    if (_isLoadingMember) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nickname = _activeMembership?.nickname;
    final role = _activeMembership?.role ?? 'Member';
    final avatarUrl = _activeMembership?.avatarUrl;

    final displayName = (nickname != null && nickname.trim().isNotEmpty)
      ? nickname
        : (profile.name ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER PREMIUM BLOCCATO
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A8B9E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isLoggingOut ? null : _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFF5A8B9E)),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // INFO UTENTE PREMIUM
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                    child: Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D342C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3D342C,
                            ).withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child:
                                  avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                    _cacheBustedAvatarUrl(avatarUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stackTrace) =>
                                          Center(
                                            child: Text(
                                              _initialFromName(displayName),
                                              style: GoogleFonts.poppins(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                    )
                                  : Center(
                                      child: Text(
                                        _initialFromName(displayName),
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
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
                                  ),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF5A8B9E,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Color(0xFF5A8B9E),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _editingNickname
                              ? null
                              : () {
                                  setState(() {
                                    _editingNickname = true;
                                    _nicknameController.text =
                                        _activeMembership?.nickname ?? '';
                                  });
                                },
                          child: Row(
                            children: [
                              Expanded(
                                child: _editingNickname
                                    ? TextField(
                                        controller: _nicknameController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF3D342C),
                                          letterSpacing: -0.5,
                                        ),
                                      )
                                    : Text(
                                        displayName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF3D342C),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                              ),
                              if (_editingNickname)
                                IconButton(
                                  onPressed: _isSavingNickname
                                      ? null
                                      : _handleNicknameEdit,
                                  icon: _isSavingNickname
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.check_rounded,
                                          color: Color(0xFF5A8B9E),
                                        ),
                                )
                              else
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingNickname = true;
                                      _nicknameController.text =
                                          _activeMembership?.nickname ?? '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF5A8B9E),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A8B9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 45, height: 45),
                ],
              ),
              const SizedBox(height: 50),

              // BOTTONI PREMIUM
              _buildPremiumMenuButton(
                icon: Icons.fastfood_outlined,
                text: 'Your Diet',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DietScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildPremiumMenuButton(
                icon: Icons.receipt_long_rounded,
                text: 'Your Home',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const YourHomeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Household Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A8B9E).withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _handleInviteMember,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5A8B9E),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Invite Member',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  TextButton(
                    onPressed: _handleHouseholdSettingsAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      (_activeMembership?.role.toUpperCase() == 'HOST')
                          ? 'Delete household'
                          : 'Leave household',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
  }

  // --- BOTTONI GRANDI PREMIUM ---
  Widget _buildPremiumMenuButton({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Aggiunto qui!
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 110,
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
