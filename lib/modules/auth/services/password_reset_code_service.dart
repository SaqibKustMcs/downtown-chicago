import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'dart:math';

/// Service to manage 6-digit password reset codes
class PasswordResetCodeService {
  PasswordResetCodeService._();
  static final PasswordResetCodeService instance = PasswordResetCodeService._();

  /// Generate a random 6-digit code
  String _generateSixDigitCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Generates 100000-999999
  }

  /// Store password reset code in Firestore
  /// Returns the 6-digit code
  Future<String> generateAndStoreCode(String email, String firebaseActionCode) async {
    final code = _generateSixDigitCode();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15)); // Code expires in 15 minutes

    await FirebaseService.firestore
        .collection('password_reset_codes')
        .doc(email.toLowerCase().trim())
        .set({
      'code': code,
      'email': email.toLowerCase().trim(),
      'firebaseActionCode': firebaseActionCode,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'used': false,
    });

    return code;
  }

  /// Verify 6-digit code and get Firebase action code
  /// Returns the Firebase action code if valid, null otherwise
  Future<String?> verifyCode(String email, String code) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('password_reset_codes')
          .doc(email.toLowerCase().trim())
          .get();

      if (!doc.exists) {
        debugPrint('Password reset code document not found for email: $email');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code'] as String?;
      final firebaseActionCode = data['firebaseActionCode'] as String?;
      final used = data['used'] as bool? ?? false;
      final expiresAt = data['expiresAt'] as Timestamp?;

      // Check if code is used
      if (used) {
        debugPrint('Password reset code already used');
        return null;
      }

      // Check if code is expired
      if (expiresAt != null) {
        final expiryDate = expiresAt.toDate();
        if (DateTime.now().isAfter(expiryDate)) {
          debugPrint('Password reset code expired');
          return null;
        }
      }

      // Verify code matches
      if (storedCode != code) {
        debugPrint('Password reset code mismatch');
        return null;
      }

      // Mark code as used
      await doc.reference.update({'used': true});

      return firebaseActionCode;
    } catch (e) {
      debugPrint('Error verifying password reset code: $e');
      return null;
    }
  }

  /// Delete expired codes (cleanup method)
  Future<void> cleanupExpiredCodes() async {
    try {
      final now = Timestamp.now();
      final expiredCodes = await FirebaseService.firestore
          .collection('password_reset_codes')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = FirebaseService.firestore.batch();
      for (var doc in expiredCodes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up expired codes: $e');
    }
  }
}
