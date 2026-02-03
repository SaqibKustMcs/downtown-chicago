import 'package:flutter/material.dart';
import 'package:food_flow_app/core/services/secure_storage_service.dart';

class AppPreferencesService {
  AppPreferencesService._();

  // Keys
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _authTokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _themeModeKey = 'theme_mode';

  // Onboarding
  static Future<bool> isOnboardingCompleted() async {
    final value = await SecureStorageService.read(_onboardingCompletedKey);
    return value == 'true';
  }

  static Future<void> setOnboardingCompleted() async {
    await SecureStorageService.write(_onboardingCompletedKey, 'true');
  }

  // Auth Token
  static Future<void> saveAuthToken(String token) async {
    await SecureStorageService.write(_authTokenKey, token);
    await SecureStorageService.write(_isLoggedInKey, 'true');
  }

  static Future<String?> getAuthToken() async {
    return await SecureStorageService.read(_authTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final value = await SecureStorageService.read(_isLoggedInKey);
    return value == 'true';
  }

  static Future<void> clearAuthToken() async {
    // Run both deletes in parallel for faster execution
    await Future.wait([
      SecureStorageService.delete(_authTokenKey),
      SecureStorageService.delete(_isLoggedInKey),
    ]);
  }

  // Theme Mode
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    await SecureStorageService.write(_themeModeKey, themeMode.toString());
  }

  static Future<ThemeMode?> getThemeMode() async {
    final value = await SecureStorageService.read(_themeModeKey);
    if (value == null) return null;
    
    switch (value) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
