import 'dart:typed_data';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/app_route_names.dart';
import 'package:everyday_app/features/household/services/household_onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HouseholdOnboardingScreen extends StatefulWidget {
  const HouseholdOnboardingScreen({super.key});

  @override
  State<HouseholdOnboardingScreen> createState() =>
      _HouseholdOnboardingScreenState();
}

class _HouseholdOnboardingScreenState extends State<HouseholdOnboardingScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final HouseholdOnboardingService _onboardingService =
      HouseholdOnboardingService();

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
    return _onboardingService.uploadAvatarIfNeeded(
      bytes: _selectedAvatarBytes,
      householdId: AppContext.instance.householdId,
      membershipId: AppContext.instance.membershipId,
    );
  }

  Future<void> _continue() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouteNames.mainLayout);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final nickname = _nicknameController.text.trim();
      final avatarUrl = await _uploadAvatarIfNeeded();
      await _onboardingService.saveMemberProfile(
        membershipId: membershipId,
        nickname: nickname,
        avatarUrl: avatarUrl,
      );

      await AppContext.instance.reloadMemberContext();

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouteNames.mainLayout);
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
    Navigator.of(context).pushReplacementNamed(AppRouteNames.mainLayout);
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
