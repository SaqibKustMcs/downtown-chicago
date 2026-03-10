import 'package:flutter/material.dart';
import 'package:downtown/core/services/secure_storage_service.dart';

class AppPreferencesService {
  AppPreferencesService._();

  // Keys
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _authTokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _themeModeKey = 'theme_mode';
  static const String _pushNotificationsEnabledKey = 'push_notifications_enabled';
  static const String _orderNotificationsEnabledKey = 'order_notifications_enabled';
  static const String _promotionalNotificationsEnabledKey = 'promotional_notifications_enabled';
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';

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

  // Remember Me
  static Future<void> saveRememberMeCredentials(String email, String password) async {
    await Future.wait([
      SecureStorageService.write(_rememberMeKey, 'true'),
      SecureStorageService.write(_rememberedEmailKey, email),
      SecureStorageService.write(_rememberedPasswordKey, password),
    ]);
  }

  static Future<void> clearRememberMeCredentials() async {
    await Future.wait([
      SecureStorageService.delete(_rememberMeKey),
      SecureStorageService.delete(_rememberedEmailKey),
      SecureStorageService.delete(_rememberedPasswordKey),
    ]);
  }

  static Future<bool> isRememberMeEnabled() async {
    final value = await SecureStorageService.read(_rememberMeKey);
    return value == 'true';
  }

  static Future<String?> getRememberedEmail() async {
    return await SecureStorageService.read(_rememberedEmailKey);
  }

  static Future<String?> getRememberedPassword() async {
    return await SecureStorageService.read(_rememberedPasswordKey);
  }

  // Push Notifications
  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    await SecureStorageService.write(_pushNotificationsEnabledKey, enabled.toString());
  }

  static Future<bool> isPushNotificationsEnabled() async {
    final value = await SecureStorageService.read(_pushNotificationsEnabledKey);
    return value != 'false'; // Default to true if not set
  }

  // Order Notifications
  static Future<void> setOrderNotificationsEnabled(bool enabled) async {
    await SecureStorageService.write(_orderNotificationsEnabledKey, enabled.toString());
  }

  static Future<bool> isOrderNotificationsEnabled() async {
    final value = await SecureStorageService.read(_orderNotificationsEnabledKey);
    return value != 'false'; // Default to true if not set
  }

  // Promotional Notifications
  static Future<void> setPromotionalNotificationsEnabled(bool enabled) async {
    await SecureStorageService.write(_promotionalNotificationsEnabledKey, enabled.toString());
  }

  static Future<bool> isPromotionalNotificationsEnabled() async {
    final value = await SecureStorageService.read(_promotionalNotificationsEnabledKey);
    return value != 'false'; // Default to true if not set
  }
}
