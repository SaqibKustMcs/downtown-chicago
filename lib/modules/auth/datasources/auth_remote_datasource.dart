import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/base/base_datasource.dart';
import 'package:downtown/modules/auth/models/user_model.dart';

/// Remote DataSource for Authentication (Firebase Auth + Firestore)
class AuthRemoteDataSource implements RemoteDataSource<UserModel> {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    // If data contains 'id', use it as document ID, otherwise generate new ID
    final String docId = data['id'] as String? ?? '';
    if (docId.isNotEmpty) {
      await _firestore.collection('users').doc(docId).set(data);
      return docId;
    } else {
      final docRef = await _firestore.collection('users').add(data);
      return docRef.id;
    }
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAll() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  @override
  Stream<Map<String, dynamic>?> streamById(String id) {
    return _firestore.collection('users').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  // Auth-specific methods

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Verify password reset code
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _auth.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user from Firebase Auth
      await user.delete();
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get Firestore instance (for repository use)
  FirebaseFirestore get firestore => _firestore;

  /// Check if user exists by email in Firestore
  Future<Map<String, dynamic>?> checkUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return {'id': querySnapshot.docs.first.id, ...querySnapshot.docs.first.data()};
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
