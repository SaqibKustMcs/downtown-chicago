import 'package:food_flow_app/core/base/base_repository.dart';
import 'package:food_flow_app/modules/auth/models/user_model.dart';
import 'package:food_flow_app/modules/auth/datasources/auth_remote_datasource.dart';
import 'package:food_flow_app/modules/auth/datasources/auth_local_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Auth Repository - Handles data operations for authentication
class AuthRepository implements BaseRepository<UserModel> {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepository({required AuthRemoteDataSource remoteDataSource, required AuthLocalDataSource localDataSource})
    : _remoteDataSource = remoteDataSource,
      _localDataSource = localDataSource;

  @override
  Future<List<UserModel>> getAll() async {
    try {
      final data = await _remoteDataSource.getAll();
      return data.map((item) => UserModel.fromFirestore(item, item['id'])).toList();
    } catch (e) {
      // Fallback to local if remote fails
      final localData = await _localDataSource.getAll();
      return localData.map((item) => UserModel.fromFirestore(item, item['id'])).toList();
    }
  }

  @override
  Future<UserModel?> getById(String id) async {
    try {
      final data = await _remoteDataSource.getById(id);
      if (data == null) return null;
      return UserModel.fromFirestore(data, data['id']);
    } catch (e) {
      final localData = await _localDataSource.getById(id);
      if (localData == null) return null;
      return UserModel.fromFirestore(localData, localData['id']);
    }
  }

  @override
  Future<String> create(UserModel item) async {
    final data = item.toFirestore();
    // Include the user ID in the data so it can be used as document ID
    final dataWithId = {'id': item.id, ...data};
    // Use the item's ID as the document ID
    await _remoteDataSource.create(dataWithId);
    // Also save locally
    await _localDataSource.create({'id': item.id, ...data});
    return item.id;
  }

  @override
  Future<void> update(String id, UserModel item) async {
    final data = item.toFirestore();
    await _remoteDataSource.update(id, data);
    await _localDataSource.update(id, {'id': id, ...data});
  }

  @override
  Future<void> delete(String id) async {
    await _remoteDataSource.delete(id);
    await _localDataSource.delete(id);
  }

  // Auth-specific methods

  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    final credential = await _remoteDataSource.signInWithEmailAndPassword(email: email, password: password);

    // Save token locally
    if (credential.user != null) {
      final token = await credential.user!.getIdToken();
      await _localDataSource.saveAuthToken(token!);

      // Save user data
      final userModel = UserModel.fromFirebaseUser(credential.user!);
      await _localDataSource.create({'id': userModel.id, ...userModel.toFirestore()});
    }

    return credential;
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({required String email, required String password, String? name, UserType userType = UserType.customer}) async {
    final credential = await _remoteDataSource.signUpWithEmailAndPassword(email: email, password: password);

    // Create user document in Firestore
    if (credential.user != null) {
      final userModel = UserModel(id: credential.user!.uid, email: email, name: name, userType: userType, createdAt: DateTime.now(), emailVerified: false);
      await create(userModel);

      // Send verification email
      await _remoteDataSource.sendEmailVerification();
    }

    return credential;
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    await _remoteDataSource.sendEmailVerification();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _remoteDataSource.sendPasswordResetEmail(email);
  }

  /// Confirm password reset with code
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _remoteDataSource.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    await _remoteDataSource.updatePassword(newPassword);
  }

  /// Sign out
  Future<void> signOut() async {
    // Run sign out and clear local data in parallel for faster logout
    await Future.wait([
      _remoteDataSource.signOut(),
      _localDataSource.clearAll(),
    ]);
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final firebaseUser = _remoteDataSource.currentUser;
    if (firebaseUser != null) {
      // Delete from Firestore and Firebase Auth
      await _remoteDataSource.deleteAccount();
      // Clear local data
      await _localDataSource.clearAll();
    }
  }

  /// Get current user - fetches full user data from Firestore
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _remoteDataSource.currentUser;
    if (firebaseUser == null) return null;
    
    // Try to get full user data from Firestore
    try {
      final userData = await getById(firebaseUser.uid);
      if (userData != null) {
        return userData;
      }
    } catch (e) {
      // If Firestore fetch fails, fallback to Firebase Auth data
      print('Error fetching user from Firestore: $e');
    }
    
    // Fallback to Firebase Auth data if Firestore fetch fails
    return UserModel.fromFirebaseUser(firebaseUser);
  }
  
  /// Get current user synchronously (for backwards compatibility)
  UserModel? getCurrentUserSync() {
    final firebaseUser = _remoteDataSource.currentUser;
    if (firebaseUser == null) return null;
    return UserModel.fromFirebaseUser(firebaseUser);
  }

  /// Stream auth state changes
  Stream<UserModel?> authStateChanges() {
    return _remoteDataSource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      
      // Try to get full user data from Firestore
      try {
        final userData = await getById(user.uid);
        if (userData != null) {
          return userData;
        }
      } catch (e) {
        // If Firestore fetch fails, fallback to Firebase Auth data
        print('Error fetching user from Firestore in stream: $e');
      }
      
      // Fallback to Firebase Auth data
      return UserModel.fromFirebaseUser(user);
    });
  }
}
