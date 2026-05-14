import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_navigator.dart';
import 'firestore_service.dart';

/// Top-level handler for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Singleton service for Firebase Cloud Messaging + local notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM + local notifications. Call once after Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions (Android 13+).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // Get FCM token.
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('[FCM] Token: $_fcmToken');
    } catch (e) {
      _fcmToken = null;
      debugPrint('[FCM] Token unavailable on this device: $e');
    }

    // Listen for token refresh.
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('[FCM] Token refreshed: $newToken');
    });

    // Setup local notifications (for foreground display).
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android.
    await _createNotificationChannel();

    // Handle foreground messages.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification taps when app is in background/terminated.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check if app was opened from a terminated state via notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated via notification');
      _navigateFromNotificationData(initialMessage.data);
    }
  }

  /// Save the FCM token to Firestore for server-side targeting.
  Future<void> saveFcmToken(String uid, FirestoreService firestoreService) async {
    if (_fcmToken == null) return;
    await firestoreService.saveFcmToken(uid, _fcmToken!);
    debugPrint('[FCM] Token saved for user $uid');
  }

  /// Remove the FCM token from Firestore (on logout).
  Future<void> removeFcmToken(String uid, FirestoreService firestoreService) async {
    await firestoreService.removeFcmToken(uid);
    debugPrint('[FCM] Token removed for user $uid');
  }

  /// Subscribe to a topic (e.g., "flood_lahore", "aqi_lahore").
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] Unsubscribed from topic: $topic');
  }

  /// Subscribe to default topics for a city.
  Future<void> subscribeToCity(String city) async {
    final cityKey = city.toLowerCase().replaceAll(' ', '_');
    await subscribeToTopic('flood_$cityKey');
    await subscribeToTopic('aqi_$cityKey');
    await subscribeToTopic('heat_$cityKey');
    await subscribeToTopic('cloudburst_$cityKey');
    await subscribeToTopic('all_alerts');
  }

  /// Unsubscribe from all topics for a city.
  Future<void> unsubscribeFromCity(String city) async {
    final cityKey = city.toLowerCase().replaceAll(' ', '_');
    await unsubscribeFromTopic('flood_$cityKey');
    await unsubscribeFromTopic('aqi_$cityKey');
    await unsubscribeFromTopic('heat_$cityKey');
    await unsubscribeFromTopic('cloudburst_$cityKey');
  }

  // ── Private Handlers ──

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'ecoalert_alerts',
      'EcoAlert Alerts',
      description: 'Environmental hazard alerts and warnings',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Show as local notification so user sees it even in foreground.
    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'EcoAlert',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ecoalert_alerts',
          'EcoAlert Alerts',
          channelDescription: 'Environmental hazard alerts and warnings',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: '/alerts',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] App opened from background via notification');
    _navigateFromNotificationData(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    _navigateFromNotificationPayload(response.payload);
  }

  /// Opens a relevant screen when the user taps a notification. Uses the
  /// global [appNavigatorKey] because handlers run outside widget context.
  void _navigateFromNotificationData(Map<String, dynamic> data) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    final rawRoute = data['route'] as String?;
    final topic = (data['topic'] as String?) ?? (data['type'] as String?);

    if (rawRoute != null && rawRoute.isNotEmpty) {
      nav.pushNamedAndRemoveUntil(rawRoute, (r) => false);
      return;
    }

    if (topic != null && topic.startsWith('aqi')) {
      nav.pushNamedAndRemoveUntil('/navigation', (r) => false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appNavigatorKey.currentState?.pushNamed('/aqi-detail');
      });
      return;
    }

    if (topic != null &&
        (topic.contains('flood') || topic.contains('cloudburst'))) {
      nav.pushNamedAndRemoveUntil('/navigation', (r) => false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appNavigatorKey.currentState?.pushNamed('/flood-detail');
      });
      return;
    }

    nav.pushNamedAndRemoveUntil('/navigation', (r) => false);
  }

  void _navigateFromNotificationPayload(String? payload) {
    if (payload != null && payload.isNotEmpty && payload.startsWith('/')) {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushNamedAndRemoveUntil('/navigation', (r) => false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appNavigatorKey.currentState?.pushNamed(payload);
      });
      return;
    }
    appNavigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/navigation', (r) => false);
  }
}
