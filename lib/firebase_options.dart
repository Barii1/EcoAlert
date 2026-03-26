import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration for the EcoAlert project (ecoalert-31c81).
/// Values sourced from google-services.json.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android; // Fallback to Android config
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:125523315849:android:c3078972c20fb200a94a58',
    messagingSenderId: '125523315849',
    projectId: 'ecoalert-31c81',
    storageBucket: 'ecoalert-31c81.firebasestorage.app',
  );

  // TODO: Add iOS app in Firebase Console, then fill these values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '125523315849',
    projectId: 'ecoalert-31c81',
    storageBucket: 'ecoalert-31c81.firebasestorage.app',
    iosBundleId: 'com.example.ecoalert',
  );

  /// Returns true if Firebase has been configured with real credentials.
  static bool get isConfigured {
    return currentPlatform.apiKey != 'YOUR_ANDROID_API_KEY' &&
        currentPlatform.apiKey != 'YOUR_IOS_API_KEY';
  }
}
