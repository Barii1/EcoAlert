import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String location;
  final DateTime timestamp;
  final String type;
  final String actionText;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.timestamp,
    required this.type,
    required this.actionText,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      location: json['location'] as String,
      timestamp: _timestampFromJson(json['timestamp']),
      type: json['type'] as String,
      actionText: json['actionText'] as String,
    );
  }

  static DateTime _timestampFromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'actionText': actionText,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  /// Category for filter chips: Flood, Smog/AQI, Heat, Cloudburst
  String get category {
    switch (type) {
      case 'flood': return 'Flood';
      case 'air_quality': return 'Smog/AQI';
      case 'cloudburst': return 'Cloudburst';
      case 'heatwave': return 'Heatwave';
      default: return 'Other';
    }
  }
}
