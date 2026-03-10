import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/base/base_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/auth/repositories/auth_repository.dart';

/// Auth Service - Business logic for authentication
class AuthService extends BaseService<UserModel> {
  final AuthRepository _authRepository;

  AuthService(this._authRepository) : super(_authRepository);

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? name,
    UserType userType = UserType.customer, // Default to customer
  }) async {
    return await _authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      userType: userType,
    );
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    await _authRepository.sendEmailVerification();
  }

  /// Check if email exists in the system
  Future<bool> checkEmailExists(String email) async {
    try {
      // Normalize email to lowercase for consistent lookup
      final normalizedEmail = email.trim().toLowerCase();
      // Check in Firestore users collection
      final userDoc = await _authRepository.checkUserExists(normalizedEmail);
      return userDoc != null;
    } catch (e) {
      return false;
    }
  }

  /// Send password reset email
  /// Note: This method checks if email exists before sending to prevent sending codes to unregistered emails
  Future<void> sendPasswordResetEmail(String email) async {
    // Normalize email to lowercase for consistent lookup
    final normalizedEmail = email.trim().toLowerCase();
    
    // First check if email exists in Firestore
    final emailExists = await checkEmailExists(normalizedEmail);
    if (!emailExists) {
      // Throw exception to prevent sending reset email to unregistered email
      // The error message will be handled generically in the UI for security
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found with this email address',
      );
    }
    
    // Email exists, proceed with sending reset email
    // Use normalized email for Firebase Auth as well
    await _authRepository.sendPasswordResetEmail(normalizedEmail);
  }

  /// Confirm password reset with code
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _authRepository.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    await _authRepository.updatePassword(newPassword);
  }

  /// Sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
  }

  /// Get current user - fetches full user data from Firestore
  Future<UserModel?> getCurrentUser() async {
    return await _authRepository.getCurrentUser();
  }
  
  /// Get current user synchronously (for backwards compatibility)
  UserModel? getCurrentUserSync() {
    return _authRepository.getCurrentUserSync();
  }

  /// Stream auth state changes
  Stream<UserModel?> authStateChanges() {
    return _authRepository.authStateChanges();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getCurrentUserSync() != null;
  }

  /// Update user address and location
  Future<void> updateUserLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final updatedUser = currentUser.copyWith(
      address: address,
      userLatLng: {
        'latitude': latitude,
        'longitude': longitude,
      },
      updatedAt: DateTime.now(),
    );

    await _authRepository.update(currentUser.id, updatedUser);
  }

  /// Update user phone number
  Future<void> updateUserPhoneNumber(String phoneNumber) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final updatedUser = currentUser.copyWith(
      phoneNumber: phoneNumber,
      updatedAt: DateTime.now(),
    );

    await _authRepository.update(currentUser.id, updatedUser);
  }
}
