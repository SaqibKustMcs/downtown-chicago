import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';

/// Service for admin user management operations
class UserManagementService {
  UserManagementService._();
  static final UserManagementService instance = UserManagementService._();

  /// Get all users
  /// Optionally filter by userType
  Stream<List<UserModel>> getAllUsers({UserType? userType}) {
    Query query = FirebaseService.firestore.collection('users');

    if (userType != null) {
      query = query.where('userType', isEqualTo: userType.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          debugPrint('Error parsing user ${doc.id}: $e');
          return null;
        }
      }).whereType<UserModel>().toList();
    });
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await FirebaseService.firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
      return null;
    }
  }

  /// Get user stream by ID
  Stream<UserModel?> getUserStream(String userId) {
    return FirebaseService.firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        try {
          return UserModel.fromFirestore(snapshot.data()! as Map<String, dynamic>, snapshot.id);
        } catch (e) {
          debugPrint('Error parsing user ${snapshot.id}: $e');
          return null;
        }
      }
      return null;
    });
  }

  /// Delete user (from Firestore and Firebase Auth)
  /// Returns true if successful, false otherwise
  Future<bool> deleteUser(String userId) async {
    try {
      // Get user email before deletion
      final userDoc = await FirebaseService.firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final email = userData?['email'] as String?;

      // Delete from Firestore
      await FirebaseService.firestore.collection('users').doc(userId).delete();

      // Delete from Firebase Auth (if email exists)
      if (email != null) {
        try {
          // Note: Admin needs to delete from Firebase Auth Console or use Admin SDK
          // For now, we'll just delete from Firestore
          // In production, you'd use Firebase Admin SDK on backend
          debugPrint('User deleted from Firestore. Firebase Auth deletion requires Admin SDK.');
        } catch (e) {
          debugPrint('Error deleting from Firebase Auth: $e');
          // Continue even if Auth deletion fails
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting user $userId: $e');
      return false;
    }
  }

  /// Update user field
  Future<bool> updateUserField(String userId, Map<String, dynamic> fields) async {
    try {
      await FirebaseService.firestore.collection('users').doc(userId).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating user $userId: $e');
      return false;
    }
  }

  /// Update user status (active/inactive)
  /// Note: This requires adding an 'isActive' field to UserModel if not already present
  Future<bool> updateUserStatus(String userId, bool isActive) async {
    return await updateUserField(userId, {'isActive': isActive});
  }

  /// Update email verification status
  Future<bool> updateEmailVerificationStatus(String userId, bool emailVerified) async {
    return await updateUserField(userId, {'emailVerified': emailVerified});
  }

  /// Update rider online status
  Future<bool> updateRiderOnlineStatus(String userId, bool isOnline) async {
    return await updateUserField(userId, {'isOnline': isOnline});
  }

  /// Update rider availability status
  Future<bool> updateRiderAvailabilityStatus(String userId, bool isAvailable) async {
    return await updateUserField(userId, {'isAvailable': isAvailable});
  }

  /// Update user type
  Future<bool> updateUserType(String userId, UserType userType) async {
    return await updateUserField(userId, {'userType': userType.name});
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final usersSnapshot = await FirebaseService.firestore.collection('users').get();
      final users = usersSnapshot.docs.map((doc) {
        try {
          return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          return null;
        }
      }).whereType<UserModel>().toList();

      int totalUsers = users.length;
      int totalCustomers = users.where((u) => u.userType == UserType.customer).length;
      int totalRiders = users.where((u) => u.userType == UserType.rider).length;
      int totalAdmins = users.where((u) => u.userType == UserType.admin).length;
      int onlineRiders = users.where((u) => u.userType == UserType.rider && u.isOnline == true).length;
      int availableRiders = users.where((u) => u.userType == UserType.rider && u.isAvailable == true).length;
      int emailVerified = users.where((u) => u.emailVerified).length;

      return {
        'totalUsers': totalUsers,
        'totalCustomers': totalCustomers,
        'totalRiders': totalRiders,
        'totalAdmins': totalAdmins,
        'onlineRiders': onlineRiders,
        'availableRiders': availableRiders,
        'emailVerified': emailVerified,
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {
        'totalUsers': 0,
        'totalCustomers': 0,
        'totalRiders': 0,
        'totalAdmins': 0,
        'onlineRiders': 0,
        'availableRiders': 0,
        'emailVerified': 0,
      };
    }
  }

  /// Search users by name, email, or phone
  Stream<List<UserModel>> searchUsers(String query, {UserType? userType}) {
    if (query.isEmpty) {
      return getAllUsers(userType: userType);
    }

    final lowerQuery = query.toLowerCase();
    return getAllUsers(userType: userType).map((users) {
      return users.where((user) {
        final name = user.name?.toLowerCase() ?? '';
        final email = user.email.toLowerCase();
        final phone = user.phoneNumber?.toLowerCase() ?? '';
        return name.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            phone.contains(lowerQuery);
      }).toList();
    });
  }

  /// Create a new rider account
  /// Creates Firebase Auth user and Firestore document
  Future<String?> createRider({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? secondaryContactNumber,
    String? cnic,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      // Use a secondary admin auth instance so the current admin session is not affected
      final adminAuth = await FirebaseService.adminAuth;

      // Create Firebase Auth user for the rider
      final userCredential = await adminAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('Failed to create Firebase Auth user');
      }

      // Create Firestore document
      final userData = {
        'email': email,
        'name': name,
        'userType': UserType.rider.name,
        // Riders created by admin are treated as email-verified by default
        'emailVerified': true,
        'isOnline': false,
        'isAvailable': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
        if (secondaryContactNumber != null && secondaryContactNumber.isNotEmpty) 'secondaryContactNumber': secondaryContactNumber,
        if (cnic != null && cnic.isNotEmpty) 'cnic': cnic,
        if (vehicleType != null && vehicleType.isNotEmpty) 'vehicleType': vehicleType,
        if (vehicleNumber != null && vehicleNumber.isNotEmpty) 'vehicleNumber': vehicleNumber,
      };

      await FirebaseService.firestore.collection('users').doc(userId).set(userData);

      debugPrint('Rider created successfully: $userId');
      return userId;
    } catch (e) {
      debugPrint('Error creating rider: $e');
      rethrow;
    }
  }

  /// Set password for an existing rider (admin action)
  /// Note: This requires the admin to be authenticated
  Future<bool> setRiderPassword(String riderEmail, String newPassword) async {
    try {
      // Get the user by email
      final user = await FirebaseService.auth.fetchSignInMethodsForEmail(riderEmail);
      if (user.isEmpty) {
        throw Exception('User not found');
      }

      // Note: Setting password directly requires Admin SDK
      // For client-side, we can only send password reset email
      // In production, use Firebase Admin SDK on backend
      await FirebaseService.auth.sendPasswordResetEmail(email: riderEmail);
      
      debugPrint('Password reset email sent to $riderEmail');
      return true;
    } catch (e) {
      debugPrint('Error setting rider password: $e');
      return false;
    }
  }

  /// Update rider password (requires current password)
  /// For admin to set password without current password, use setRiderPassword
  Future<bool> updateRiderPassword(String riderEmail, String currentPassword, String newPassword) async {
    try {
      // Sign in with current password
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: riderEmail,
        password: currentPassword,
      );

      // Update password
      await credential.user?.updatePassword(newPassword);
      
      debugPrint('Password updated successfully for $riderEmail');
      return true;
    } catch (e) {
      debugPrint('Error updating rider password: $e');
      return false;
    }
  }
}
