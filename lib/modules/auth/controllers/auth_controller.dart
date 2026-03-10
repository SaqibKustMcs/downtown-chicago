import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/base/base_controller.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/services/notification_listener_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/auth/services/auth_service.dart';

/// Auth Controller - Manages authentication state and UI logic
class AuthController extends BaseController {
  final AuthService _authService;
  UserModel? _currentUser;

  AuthController(this._authService);

  UserModel? get currentUser => _currentUser;

  /// Initialize - Listen to auth state changes
  void initialize() {
    // Load initial user data
    _loadInitialUser();
    
    _authService.authStateChanges().listen((user) async {
      if (user != null) {
        // Fetch full user data from Firestore when auth state changes
        _currentUser = await _authService.getCurrentUser();
      } else {
        _currentUser = null;
        // Stop notification listener when user logs out
        NotificationListenerService.instance.stopListening();
      }
      notifyListeners();
    });
  }
  
  /// Load initial user data
  Future<void> _loadInitialUser() async {
    if (_authService.isAuthenticated()) {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return await execute(() async {
      await _authService.signIn(email: email, password: password);
      _currentUser = await _authService.getCurrentUser();
      
      // Initialize and save FCM token after successful login (non-blocking)
      // Don't await - let it run in background so it doesn't block user data loading
      unawaited(_initializeFcmToken());
      
      return true;
    }) ?? false;
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    UserType userType = UserType.customer,
  }) async {
    return await execute(() async {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
      _currentUser = await _authService.getCurrentUser();
      
      // Initialize and save FCM token after successful signup (non-blocking)
      // Don't await - let it run in background so it doesn't block user data loading
      unawaited(_initializeFcmToken());
      
      return true;
    }) ?? false;
  }
  
  /// Refresh current user data from Firestore
  Future<void> refreshUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    return await execute(() async {
      await _authService.sendEmailVerification();
      return true;
    }) ?? false;
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return await execute(() async {
      await _authService.sendPasswordResetEmail(email);
      return true;
    }) ?? false;
  }

  /// Confirm password reset with code
  Future<bool> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    return await execute(() async {
      await _authService.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      return true;
    }) ?? false;
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    return await execute(() async {
      await _authService.updatePassword(newPassword);
      return true;
    }) ?? false;
  }

  /// Sign out - optimized for faster execution
  Future<bool> signOut() async {
    try {
      // Stop notification listener before signing out
      NotificationListenerService.instance.stopListening();
      
      // Don't use execute wrapper to avoid unnecessary loading state overhead
      await _authService.signOut();
      _currentUser = null;
      clearError();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    return await execute(() async {
      await _authService.deleteAccount();
      _currentUser = null;
      return true;
    }) ?? false;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _authService.isAuthenticated();
  }

  /// Update user location and address
  Future<bool> updateUserLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    return await execute(() async {
      await _authService.updateUserLocation(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      // Refresh user data
      await refreshUser();
      return true;
    }) ?? false;
  }

  /// Update user phone number
  Future<bool> updateUserPhoneNumber(String phoneNumber) async {
    return await execute(() async {
      await _authService.updateUserPhoneNumber(phoneNumber);
      // Refresh user data
      await refreshUser();
      return true;
    }) ?? false;
  }

  /// Initialize FCM token and save to Firestore
  /// This is called after successful login/signup
  Future<void> _initializeFcmToken() async {
    try {
      final pushService = PushNotificationService.instance;
      
      // Setup foreground message handler
      pushService.setupForegroundMessageHandler();
      
      // Initialize and get token
      final token = await pushService.initializeAndGetToken();
      
      if (token != null) {
        // Save token to Firestore
        await pushService.saveTokenToFirestore(token);
        debugPrint('FCM token initialized and saved after authentication');
      } else {
        debugPrint('Failed to get FCM token after authentication');
      }
    } catch (e) {
      debugPrint('Error initializing FCM token: $e');
      // Don't throw error - FCM token is not critical for authentication
    }
  }
}
