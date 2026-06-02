import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

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
    this.usedBackendModel = true,
  });

  final String predictedLabel;
  final double confidence;
  final List<AqiImageScore> topK;
  final Map<String, double> probabilities;
  final String? assistedLabel;
  final double? assistedConfidence;
  final String? numericalLabel;
  final String? assistanceNote;
  final bool usedBackendModel;

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

  factory AqiImagePrediction.liveFallback(AqiReading reading) {
    return AqiImagePrediction(
      predictedLabel: reading.categoryLabel,
      confidence: 0.0,
      topK: const [],
      probabilities: const {},
      assistedLabel: reading.categoryLabel,
      assistedConfidence: null,
      numericalLabel: reading.categoryLabel,
      assistanceNote:
          'Image backend unavailable; using live pollutant AQI for this scan.',
      usedBackendModel: false,
    );
  }

  AqiImagePrediction withAssistedReading(AqiReading? reading) {
    if (reading == null) return this;

    final imageIndex = _indexForLabel(predictedLabel);
    final numericalIndex = reading.category.index;
    if (imageIndex == null) return this;

    final distance = (imageIndex - numericalIndex).abs();
    final imageWeight = confidence >= 0.90 ? 0.45 : 0.25;
    final numericalWeight = 1.0 - imageWeight;
    var assistedIndex =
        ((imageIndex * imageWeight) + (numericalIndex * numericalWeight))
            .round();
    if (distance >= 2 && confidence < 0.92) {
      assistedIndex = assistedIndex.clamp(
        numericalIndex - 1,
        numericalIndex + 1,
      );
    }
    assistedIndex = assistedIndex.clamp(0, _orderedLabels.length - 1);
    final note = distance <= 1
        ? 'Image model and live pollutant AQI are close.'
        : 'Live pollutant AQI stabilized the visual estimate.';

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
      usedBackendModel: usedBackendModel,
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
  static const String _usbFallbackBaseUrl = 'http://127.0.0.1:5000';

  static Future<AqiImagePrediction> predictImage(
    File image, {
    AqiReading? currentReading,
  }) async {
    final urls = <String>[
      _baseUrl,
      if (_baseUrl != _usbFallbackBaseUrl) _usbFallbackBaseUrl,
    ];

    Object? lastError;
    for (final baseUrl in urls) {
      try {
        return await _predictImageAtBaseUrl(
          baseUrl,
          image,
          currentReading: currentReading,
        );
      } catch (e) {
        lastError = e;
      }
    }

    if (currentReading != null) {
      return AqiImagePrediction.liveFallback(currentReading);
    }

    throw Exception(_friendlyError(lastError));
  }

  static Future<AqiImagePrediction> _predictImageAtBaseUrl(
    String baseUrl,
    File image, {
    AqiReading? currentReading,
  }) async {
    final imageBytes = await _jpegBytesForUpload(image);

    // Send a normalized JPEG; preprocessing happens inside the model graph.
    final uri = Uri.parse('$baseUrl/api/aqi-image/predict');
    final request = http.MultipartRequest('POST', uri);
    final stream = http.ByteStream.fromBytes(imageBytes);
    request.files.add(http.MultipartFile(
      'image',
      stream,
      imageBytes.length,
      filename: 'aqi_scan.jpg',
      contentType: _jpegContentType,
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

  static String _friendlyError(Object? error) {
    final message = error.toString();
    if (message.contains('No route to host') ||
        message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('TimeoutException')) {
      return 'Image model server is not reachable. Keep the Flask backend running and the USB cable connected.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  static Future<List<int>> _jpegBytesForUpload(File image) async {
    final rawBytes = await image.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;
    final oriented = img.bakeOrientation(decoded);
    return img.encodeJpg(oriented, quality: 92);
  }

  static final _jpegContentType = MediaType('image', 'jpeg');
}
