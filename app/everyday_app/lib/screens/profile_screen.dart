import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_context.dart';
import 'login2_screen.dart';
import 'diet_screen.dart';
import 'your_home_screen.dart';

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
  String? _nickname;
  String? _avatarUrl;
  int? _avatarCacheBuster;
  String _role = 'Member';
  late TextEditingController _nicknameController;

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
      text: AppContext.instance.nickname ?? '',
    );
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
      final response = await Supabase.instance.client
          .from('household_member')
          .select('nickname, avatar_url, role')
          .eq('id', membershipId)
          .single();

      if (!mounted) return;
      setState(() {
        _nickname = response['nickname'] as String?;
        AppContext.instance.nickname = _nickname;
        _nicknameController.text = _nickname ?? '';
        _avatarUrl = response['avatar_url'] as String?;
        _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
        _role = (response['role'] as String?) ?? 'Member';
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
        _nickname = AppContext.instance.nickname;
        _nicknameController.text = _nickname ?? '';
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

  void _copyHomeId(String householdId) {
    Clipboard.setData(ClipboardData(text: householdId));
    _showSuccessSnackBar('HomeID copied');
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
    if (membershipId == null || _avatarUrl == null || _avatarUrl!.isEmpty) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final oldPath = _extractAvatarStoragePath(_avatarUrl);
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
        final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
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

    final displayName = (_nickname != null && _nickname!.trim().isNotEmpty)
        ? _nickname!
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
                                  _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      _cacheBustedAvatarUrl(_avatarUrl!),
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
                                    _nicknameController.text = _nickname ?? '';
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
                                          _nickname ?? '';
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
                          _role,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A8B9E),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'HomeID',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(
                                  0xFF5A8B9E,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _copyHomeId(householdId),
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: Color(0xFF5A8B9E),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
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
