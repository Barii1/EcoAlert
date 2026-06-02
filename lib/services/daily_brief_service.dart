import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class DailyBrief {
  const DailyBrief({
    required this.summary,
    required this.safetyTip,
    required this.guideTitle,
    required this.guideSteps,
    required this.city,
  });

  final String       summary;
  final String       safetyTip;
  final String       guideTitle;
  final List<String> guideSteps;
  final String       city;

  factory DailyBrief.fromJson(Map<String, dynamic> j) => DailyBrief(
        summary:    j['summary']    as String? ?? '',
        safetyTip:  j['safety_tip'] as String? ?? '',
        guideTitle: j['guide_title'] as String? ?? 'Today\'s Safety Guide',
        guideSteps: (j['guide_steps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        city: j['city'] as String? ?? '',
      );
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role;    // 'user' or 'assistant'
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class DailyBriefService {
  DailyBriefService._();
  static final DailyBriefService instance = DailyBriefService._();

  static const _timeout = Duration(seconds: 25);
  String get _base => AppConfig.uploadApiBaseUrl;

  Future<DailyBrief> fetchSummary({
    required String city,
    int?    aqi,
    String? aqiCategory,
    String? floodRisk,
    double? floodProbability,
    String? cloudburstRisk,
    double? temperature,
    double? humidity,
    String? weatherDesc,
  }) async {
    final body = jsonEncode({
      'city':              city,
      if (aqi != null)            'aqi': aqi,
      if (aqiCategory != null)    'aqi_category': aqiCategory,
      if (floodRisk != null)      'flood_risk': floodRisk,
      if (floodProbability != null) 'flood_probability': floodProbability,
      if (cloudburstRisk != null) 'cloudburst_risk': cloudburstRisk,
      if (temperature != null)    'temperature': temperature,
      if (humidity != null)       'humidity': humidity,
      if (weatherDesc != null)    'weather_desc': weatherDesc,
    });

    final resp = await http
        .post(
          Uri.parse('$_base/api/ai/summary'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw Exception('AI summary failed: ${resp.statusCode}');
    }
    return DailyBrief.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<String> sendMessage({
    required String message,
    required String city,
    required List<ChatMessage> history,
    int?    aqi,
    String? aqiCategory,
    String? floodRisk,
    String? cloudburstRisk,
    double? temperature,
    String? weatherDesc,
  }) async {
    final body = jsonEncode({
      'message': message,
      'city':    city,
      'history': history.map((m) => m.toJson()).toList(),
      if (aqi != null)            'aqi': aqi,
      if (aqiCategory != null)    'aqi_category': aqiCategory,
      if (floodRisk != null)      'flood_risk': floodRisk,
      if (cloudburstRisk != null) 'cloudburst_risk': cloudburstRisk,
      if (temperature != null)    'temperature': temperature,
      if (weatherDesc != null)    'weather_desc': weatherDesc,
    });

    final resp = await http
        .post(
          Uri.parse('$_base/api/ai/chat'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw Exception('Chat failed: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['reply'] as String? ?? 'Sorry, I could not respond.';
  }
}
