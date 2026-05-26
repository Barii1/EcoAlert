import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/browser_online.dart';

/// Tracks internet connectivity. On web, avoids Google probes that fail due to CORS.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  DateTime? _lastChecked;
  late Timer _checkTimer;

  bool get isOnline => _isOnline;
  DateTime? get lastUpdate => _lastChecked;

  String get lastUpdateLabel {
    if (_lastChecked == null) return 'Never';
    final difference = DateTime.now().difference(_lastChecked!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  ConnectivityProvider() {
    _initConnectivityCheck();
  }

  void _initConnectivityCheck() {
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      bool online;

      if (kIsWeb) {
        // Browser onLine + CORS-friendly API ping (Open-Meteo).
        online = browserIsOnline;
        if (online) {
          final uri = Uri.parse(
            'https://api.open-meteo.com/v1/forecast'
            '?latitude=31.52&longitude=74.36'
            '&current=temperature_2m&forecast_days=1',
          );
          final result =
              await http.get(uri).timeout(const Duration(seconds: 8));
          online = result.statusCode == 200;
        }
      } else {
        final uri = Uri.parse('https://www.google.com/generate_204');
        final result =
            await http.get(uri).timeout(const Duration(seconds: 5));
        online = result.statusCode == 204 || result.statusCode == 200;
      }

      if (_isOnline != online) {
        _isOnline = online;
        _lastChecked = DateTime.now();
        notifyListeners();
      } else {
        _lastChecked = DateTime.now();
      }
    } catch (e) {
      debugPrint('[Connectivity] Check failed: $e');
      // On web, do not flip to offline on a single failed probe if browser says online.
      if (kIsWeb && browserIsOnline) {
        return;
      }
      if (_isOnline) {
        _isOnline = false;
        _lastChecked = DateTime.now();
        notifyListeners();
      }
    }
  }

  Future<void> retryConnection() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _checkTimer.cancel();
    super.dispose();
  }
}
