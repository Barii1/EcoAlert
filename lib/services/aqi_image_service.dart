import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/aqi_model.dart';

class AqiImagePrediction {
  const AqiImagePrediction({
    required this.predictedLabel,
    required this.confidence,
    required this.topK,
    required this.probabilities,
    this.assistedLabel,
    this.assistedConfidence,
    this.numericalLabel,
    this.assistanceNote,
  });

  final String predictedLabel;
  final double confidence;
  final List<AqiImageScore> topK;
  final Map<String, double> probabilities;
  final String? assistedLabel;
  final double? assistedConfidence;
  final String? numericalLabel;
  final String? assistanceNote;

  factory AqiImagePrediction.fromJson(Map<String, dynamic> json) {
    final topK = (json['topK'] as List<dynamic>? ?? [])
        .map((item) => AqiImageScore.fromJson(item as Map<String, dynamic>))
        .toList();
    final rawProbabilities =
        json['probabilities'] as Map<String, dynamic>? ?? {};
    return AqiImagePrediction(
      predictedLabel: json['predictedLabel'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      topK: topK,
      probabilities: rawProbabilities.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
      ),
    );
  }

  AqiImagePrediction withAssistedReading(AqiReading? reading) {
    if (reading == null) return this;

    final imageIndex = _indexForLabel(predictedLabel);
    final numericalIndex = reading.category.index;
    if (imageIndex == null) return this;

    final imageWeight = confidence >= 0.75 ? 0.55 : 0.35;
    final numericalWeight = 1.0 - imageWeight;
    final assistedIndex =
        ((imageIndex * imageWeight) + (numericalIndex * numericalWeight))
            .round()
            .clamp(0, _orderedLabels.length - 1);
    final distance = (imageIndex - numericalIndex).abs();
    final note = distance <= 1
        ? 'Image model and live pollutant AQI are close.'
        : 'Live pollutant AQI adjusted the visual estimate.';

    return AqiImagePrediction(
      predictedLabel: predictedLabel,
      confidence: confidence,
      topK: topK,
      probabilities: probabilities,
      assistedLabel: _orderedLabels[assistedIndex],
      assistedConfidence:
          ((confidence * imageWeight) + numericalWeight).clamp(0.0, 1.0),
      numericalLabel: reading.categoryLabel,
      assistanceNote: note,
    );
  }

  static int? _indexForLabel(String label) {
    final normalized = label.toLowerCase();
    for (var i = 0; i < _orderedLabels.length; i++) {
      if (normalized == _orderedLabels[i].toLowerCase()) return i;
    }
    if (normalized.contains('sensitive')) return 2;
    if (normalized.contains('very')) return 4;
    if (normalized.contains('severe') || normalized.contains('hazardous')) {
      return 5;
    }
    if (normalized.contains('unhealthy')) return 3;
    if (normalized.contains('moderate')) return 1;
    if (normalized.contains('good')) return 0;
    return null;
  }
}

const _orderedLabels = [
  'Good',
  'Moderate',
  'Unhealthy for Sensitive Groups',
  'Unhealthy',
  'Very Unhealthy',
  'Severe',
];

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

  static Future<AqiImagePrediction> predictImage(
    File image, {
    AqiReading? currentReading,
  }) async {
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
      return AqiImagePrediction.fromJson(data)
          .withAssistedReading(currentReading);
    }
    String message = 'AQI image prediction failed.';
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      message = data['error'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }
}
