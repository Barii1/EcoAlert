import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AqiImagePrediction {
  const AqiImagePrediction({
    required this.predictedLabel,
    required this.confidence,
    required this.topK,
  });

  final String predictedLabel;
  final double confidence;
  final List<AqiImageScore> topK;

  factory AqiImagePrediction.fromJson(Map<String, dynamic> json) {
    final topK = (json['topK'] as List<dynamic>? ?? [])
        .map((item) => AqiImageScore.fromJson(item as Map<String, dynamic>))
        .toList();
    return AqiImagePrediction(
      predictedLabel: json['predictedLabel'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      topK: topK,
    );
  }
}

class AqiImageScore {
  const AqiImageScore({required this.label, required this.confidence});

  final String label;
  final double confidence;

  factory AqiImageScore.fromJson(Map<String, dynamic> json) {
    return AqiImageScore(
      label: json['label'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AqiImageService {
  static String get _baseUrl => AppConfig.uploadApiBaseUrl;

  static Future<AqiImagePrediction> predictImage(File image) async {
    // Send the raw image bytes; preprocessing happens inside the model graph.
    final uri = Uri.parse('$_baseUrl/api/aqi-image/predict');
    final request = http.MultipartRequest('POST', uri);
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
      return AqiImagePrediction.fromJson(data);
    }
    String message = 'AQI image prediction failed.';
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      message = data['error'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }
}
