import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class UploadException implements Exception {
  UploadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UploadService {
  static SupabaseClient? _client() {
    if (!AppConfig.isSupabaseConfigured) return null;
    return Supabase.instance.client;
  }

  static Future<String> _uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    final client = _client();
    if (client == null) {
      throw UploadException('Supabase is not configured.');
    }
    await client.storage.from(bucket).upload(path, file);
    return client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<List<String>> uploadReportImages({
    required String reportId,
    required String uid,
    required List<File> images,
  }) async {
    if (images.isEmpty) return [];
    const bucket = AppConfig.supabaseReportBucket;
    final now = DateTime.now().millisecondsSinceEpoch;
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final extension = file.path.split('.').last;
      final path = 'reports/$reportId/$uid-$now-$i.$extension';
      final url = await _uploadFile(
        bucket: bucket,
        path: path,
        file: file,
      );
      urls.add(url);
    }
    return urls;
  }

  static Future<String?> uploadProfilePicture({
    required String uid,
    required File image,
  }) async {
    const bucket = AppConfig.supabaseProfileBucket;
    final extension = image.path.split('.').last;
    final path = 'profiles/$uid.$extension';
    return _uploadFile(
      bucket: bucket,
      path: path,
      file: image,
    );
  }
}
