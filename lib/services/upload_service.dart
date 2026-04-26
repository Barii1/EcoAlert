import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UploadException implements Exception {
  UploadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UploadService {
  static String get _baseUrl => AppConfig.uploadApiBaseUrl;

  static Future<String> _requireAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw UploadException('You must be signed in to upload files.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw UploadException('Could not fetch authentication token.');
    }
    return token;
  }

  static UploadException _responseToException(
    int statusCode,
    String body, {
    required String fallback,
  }) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'] as String?;
      if (error != null && error.isNotEmpty) {
        return UploadException(error, statusCode: statusCode);
      }
    } catch (_) {}
    return UploadException(fallback, statusCode: statusCode);
  }

  static Future<List<String>> uploadReportImages({
    required String reportId,
    required String uid,
    required List<File> images,
  }) async {
    if (images.isEmpty) return [];
    final token = await _requireAuthToken();
    final uri = Uri.parse('$_baseUrl/api/upload/report-images');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['report_id'] = reportId;
    request.fields['uid'] = uid;
    for (final image in images) {
      final stream = http.ByteStream(image.openRead());
      final length = await image.length();
      request.files.add(http.MultipartFile(
        'images',
        stream,
        length,
        filename: image.path.split('/').last,
      ));
    }
    final response = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final urls = data['imageUrls'] as List<dynamic>;
      return urls.cast<String>();
    }
    throw _responseToException(
      response.statusCode,
      body,
      fallback: 'Image upload failed.',
    );
  }

  static Future<String?> uploadProfilePicture({
    required String uid,
    required File image,
  }) async {
    final token = await _requireAuthToken();
    final uri = Uri.parse('$_baseUrl/api/upload/profile-picture');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['uid'] = uid;
    final stream = http.ByteStream(image.openRead());
    final length = await image.length();
    request.files.add(http.MultipartFile(
      'image',
      stream,
      length,
      filename: image.path.split('/').last,
    ));
    final response = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final body = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['photoUrl'] as String?;
    }
    throw _responseToException(
      response.statusCode,
      body,
      fallback: 'Profile image upload failed.',
    );
  }
}
