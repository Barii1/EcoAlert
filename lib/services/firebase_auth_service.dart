import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/hash_utils.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Auth State ──────────────────────────────────────────────

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign Up ─────────────────────────────────────────────────

  /// Creates Firebase Auth user + Firestore profile document.
  /// cnicNumber is hashed before storage — raw value never saved.
  Future<User?> signUp({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String cnicNumber,
    required String province,
    required String city,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    await _db.collection('users').doc(user.uid).set({
      'id': user.uid,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'cnicHash': HashUtils.hashCnic(cnicNumber),
      'province': province,
      'city': city,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
      'fcmToken': null,
      'photoUrl': null,
    });

    return user;
  }

  // ─── Sign In ─────────────────────────────────────────────────

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // ─── Sign Out ────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Profile ─────────────────────────────────────────────────

  /// Fetches user profile from Firestore users/{uid}.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Updates a single field in the user's Firestore document.
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    await _db.collection('users').doc(uid).update({field: value});
  }
}
