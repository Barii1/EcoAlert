import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  DateTime? _lastUpdate;
  late Timer _checkTimer;

  bool get isOnline => _isOnline;
  DateTime? get lastUpdate => _lastUpdate;

  String get lastUpdateLabel {
    if (_lastUpdate == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  ConnectivityProvider() {
    _initConnectivityCheck();
  }

  void _initConnectivityCheck() {
    // Check connectivity immediately
    _checkConnectivity();

    // Check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      // Google's generate_204 is designed for connectivity checks — returns 204 when online
      final result = await http
          .get(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));

      final wasOnline = _isOnline;
      _isOnline = result.statusCode == 204 || result.statusCode == 200;

      if (wasOnline != _isOnline) {
        _lastUpdate = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      // No connectivity
      if (_isOnline) {
        _isOnline = false;
        _lastUpdate = DateTime.now();
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
