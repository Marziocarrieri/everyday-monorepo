import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileCard extends StatelessWidget {
  final String? nickname;
  final String role;
  final String? avatarUrl;
  final String initials;
  final bool isUploading;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nicknameController;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditToggle;

  const ProfileCard({
    super.key,
    required this.nickname,
    required this.role,
    this.avatarUrl,
    required this.initials,
    this.isUploading = false,
    this.isEditing = false,
    this.isSaving = false,
    required this.nicknameController,
    required this.onAvatarTap,
    required this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    const orangeBright = Color(0xFFF4A261);
    const orangeDeep = Color(0xFFE76F51);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [orangeBright, orangeDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: orangeBright.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isUploading ? null : onAvatarTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(avatarUrl!, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: isUploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: orangeDeep))
                        : const Icon(Icons.edit_rounded, color: orangeDeep, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: isEditing
                    ? TextField(
                        controller: nicknameController,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: "Nickname..."),
                      )
                    : Text(
                        nickname ?? 'Add Nickname',
                        style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.white),
                  onPressed: onEditToggle,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}