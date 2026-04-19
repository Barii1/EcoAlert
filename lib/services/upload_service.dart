import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class UploadService {
  /// Change to your PC's local IP when testing on physical device.
  /// Example: 'http://192.168.1.5:5000'
  /// For emulator use: 'http://10.0.2.2:5000'
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<List<String>> uploadReportImages({
    required String reportId,
    required List<File> images,
  }) async {
    if (images.isEmpty) return [];
    try {
      final uri = Uri.parse('$_baseUrl/api/upload/report-images');
      final request = http.MultipartRequest('POST', uri);
      request.fields['report_id'] = reportId;
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
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final urls = data['imageUrls'] as List<dynamic>;
        return urls.cast<String>();
      }
      return [];
    } catch (e) {
      // Upload failure must never block report submission
      return [];
    }
  }

  static Future<String?> uploadProfilePicture({
    required String uid,
    required File image,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/upload/profile-picture');
      final request = http.MultipartRequest('POST', uri);
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
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['photoUrl'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
