import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  /// Hashes a plain-text CNIC using SHA-256.
  /// Returns a 64-character hex string.
  /// Input should be digits only, stripped of dashes.
  static String hashCnic(String cnic) {
    final normalized = cnic.replaceAll('-', '').trim();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
