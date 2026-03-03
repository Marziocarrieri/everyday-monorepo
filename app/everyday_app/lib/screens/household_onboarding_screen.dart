import 'dart:typed_data';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HouseholdOnboardingScreen extends StatefulWidget {
  const HouseholdOnboardingScreen({super.key});

  @override
  State<HouseholdOnboardingScreen> createState() =>
      _HouseholdOnboardingScreenState();
}

class _HouseholdOnboardingScreenState extends State<HouseholdOnboardingScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  bool _isSaving = false;
  Uint8List? _selectedAvatarBytes;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedAvatarBytes = bytes;
    });
  }

  Future<String?> _uploadAvatarIfNeeded() async {
    final bytes = _selectedAvatarBytes;
    if (bytes == null) return null;

    final householdId = AppContext.instance.householdId;
    final membershipId = AppContext.instance.membershipId;
    if (householdId == null || membershipId == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$householdId/$membershipId/$timestamp.jpg';

    await Supabase.instance.client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );

    return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> _continue() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final nickname = _nicknameController.text.trim();
      final avatarUrl = await _uploadAvatarIfNeeded();

      final payload = <String, dynamic>{'nickname': nickname};
      if (avatarUrl != null) {
        payload['avatar_url'] = avatarUrl;
      }

      await Supabase.instance.client
          .from('household_member')
          .update(payload)
          .eq('id', membershipId);

      await AppContext.instance.reloadMemberContext();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Set up your profile for this home',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'You can skip and edit later',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: _isSaving ? null : _pickAvatar,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF5A8B9E).withValues(
                      alpha: 0.15,
                    ),
                    backgroundImage: _selectedAvatarBytes != null
                        ? MemoryImage(_selectedAvatarBytes!)
                        : null,
                    child: _selectedAvatarBytes == null
                        ? const Icon(
                            Icons.camera_alt_rounded,
                            color: Color(0xFF5A8B9E),
                            size: 28,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nicknameController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _continue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : _skip,
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
