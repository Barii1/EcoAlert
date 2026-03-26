import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles image uploads to Firebase Storage for hazard reports.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload report images to `reports/{reportId}/image_{n}.jpg`.
  /// Returns a list of download URLs.
  Future<List<String>> uploadReportImages({
    required String reportId,
    required List<File> images,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final ref = _storage.ref('reports/$reportId/image_$i.jpg');

        // Upload with JPEG content type.
        final uploadTask = ref.putFile(
          images[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Wait for upload to complete.
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);

        debugPrint('[StorageService] Uploaded image $i for report $reportId');
      } catch (e) {
        debugPrint('[StorageService] Failed to upload image $i: $e');
        // Continue uploading remaining images even if one fails.
      }
    }

    return urls;
  }

  /// Delete all images for a report (cleanup on report deletion).
  Future<void> deleteReportImages(String reportId) async {
    try {
      final listResult = await _storage.ref('reports/$reportId').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
      debugPrint('[StorageService] Deleted images for report $reportId');
    } catch (e) {
      debugPrint('[StorageService] Failed to delete images: $e');
    }
  }
}
