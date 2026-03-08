import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class DietStorageRepository {
  Future<void> uploadPdf({
    required String path,
    required Uint8List bytes,
  }) async {
    await supabase.storage.from('diets').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );
  }

  String getPublicUrl(String path) {
    return supabase.storage.from('diets').getPublicUrl(path);
  }

  Future<void> removeByPath(String path) async {
    await supabase.storage.from('diets').remove([path]);
  }
}
