import 'package:food_flow_app/core/services/app_preferences_service.dart';
import 'package:food_flow_app/core/services/secure_storage_service.dart';
import 'package:food_flow_app/core/base/base_datasource.dart';
import 'package:food_flow_app/modules/auth/models/user_model.dart';

/// Local DataSource for Authentication (Secure Storage, SharedPreferences)
class AuthLocalDataSource implements LocalDataSource<UserModel> {
  static const String _userKey = 'current_user';
  static const String _authTokenKey = 'auth_token';

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    // Local storage typically doesn't store multiple users
    final user = await getById(_userKey);
    return user != null ? [user] : [];
  }

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final userJson = await SecureStorageService.read(_userKey);
    if (userJson == null) return null;
    // Parse JSON string to Map
    // In a real implementation, you'd use jsonDecode
    return {'id': id, 'data': userJson};
  }

  @override
  Future<String> create(Map<String, dynamic> data) async {
    // Save user data locally
    await SecureStorageService.write(_userKey, data.toString());
    return _userKey;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await SecureStorageService.write(_userKey, data.toString());
  }

  @override
  Future<void> delete(String id) async {
    await SecureStorageService.delete(_userKey);
    await SecureStorageService.delete(_authTokenKey);
  }

  @override
  Future<void> clearAll() async {
    // Run all delete operations in parallel for faster logout
    await Future.wait([
      SecureStorageService.delete(_userKey),
      SecureStorageService.delete(_authTokenKey),
      AppPreferencesService.clearAuthToken(),
    ]);
  }

  /// Save auth token
  Future<void> saveAuthToken(String token) async {
    await AppPreferencesService.saveAuthToken(token);
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return await AppPreferencesService.getAuthToken();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await AppPreferencesService.isLoggedIn();
  }
}
