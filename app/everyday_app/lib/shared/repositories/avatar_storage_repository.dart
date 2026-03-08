import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class AvatarStorageRepository {
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
  }) async {
    await supabase.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
  }

  String getPublicUrl(String path) {
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> removeAvatar(String path) async {
    await supabase.storage.from('avatars').remove([path]);
  }
}
