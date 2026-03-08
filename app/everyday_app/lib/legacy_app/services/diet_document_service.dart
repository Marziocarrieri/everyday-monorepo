import 'dart:typed_data';

import 'package:everyday_app/shared/repositories/diet_repository.dart';
import 'package:everyday_app/shared/repositories/diet_storage_repository.dart';

class DietDocumentService {
  final DietRepository _dietRepository = DietRepository();
  final DietStorageRepository _dietStorageRepository = DietStorageRepository();

  Future<Map<String, dynamic>?> getLatestDietForUser(String userId) async {
    return _dietRepository.getLatestDietForUser(userId);
  }

  Future<void> uploadDietPdf({
    required String userId,
    required Uint8List bytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$timestamp.pdf';

    await _dietStorageRepository.uploadPdf(path: storagePath, bytes: bytes);
    final publicUrl = _dietStorageRepository.getPublicUrl(storagePath);

    await _dietRepository.insertDietDocument(userId: userId, url: publicUrl);
  }

  Future<void> removeDietPdf({
    required String userId,
    required Map<String, dynamic> currentDiet,
  }) async {
    final url = currentDiet['url'] as String;
    final docId = currentDiet['id'] as String;

    final storagePath = _extractStoragePathFromUrl(url);
    if (storagePath != null && storagePath.isNotEmpty) {
      await _dietStorageRepository.removeByPath(storagePath);
    }

    await _dietRepository.deleteDietDocument(docId: docId, userId: userId);
  }

  String? _extractStoragePathFromUrl(String url) {
    const marker = '/storage/v1/object/public/diets/';
    final index = url.indexOf(marker);
    if (index < 0) return null;
    return url.substring(index + marker.length);
  }
}
