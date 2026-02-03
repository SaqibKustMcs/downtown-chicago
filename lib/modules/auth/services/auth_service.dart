import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_flow_app/core/base/base_service.dart';
import 'package:food_flow_app/modules/auth/models/user_model.dart';
import 'package:food_flow_app/modules/auth/repositories/auth_repository.dart';

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

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
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
}
