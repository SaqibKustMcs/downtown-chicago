import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';

/// Push Notification Service - Handles FCM tokens, permissions, and device management
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseService.messaging;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  String? _currentDeviceId;
  String? _currentFcmToken;

  /// Get unique device ID
  Future<String> getDeviceId() async {
    if (_currentDeviceId != null) return _currentDeviceId!;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else {
        _currentDeviceId = 'unknown';
      }
      return _currentDeviceId!;
    } catch (e) {
      return 'unknown';
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Initialize push notifications and get FCM token
  Future<String?> initializeAndGetToken() async {
    try {
      // Request permission first
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted');
        return null;
      }

      // Get FCM token
      final token = await _messaging.getToken();
      _currentFcmToken = token;

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _currentFcmToken = newToken;
        _saveTokenToFirestore(newToken);
      });

      return token;
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore with device ID
  Future<void> saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final user = FirebaseService.currentUser;
    if (user == null) {
      debugPrint('User not authenticated, cannot save FCM token');
      return;
    }

    try {
      final deviceId = await getDeviceId();
      _currentFcmToken = token;

      // Save token to user's fcmTokens subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(deviceId)
          .set({
        'token': token,
        'deviceId': deviceId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token saved successfully for device: $deviceId');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Internal method to save token (used by token refresh listener)
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseService.currentUser;
    if (user == null) return;

    try {
      final deviceId = await getDeviceId();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(deviceId)
          .update({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token updated successfully for device: $deviceId');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Remove FCM token from Firestore based on device ID
  Future<void> removeTokenByDeviceId() async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      debugPrint('User not authenticated, cannot remove FCM token');
      return;
    }

    try {
      final deviceId = await getDeviceId();
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(deviceId)
          .delete();

      debugPrint('FCM token removed successfully for device: $deviceId');
      _currentFcmToken = null;
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Remove all FCM tokens for a user (used when deleting account)
  Future<void> removeAllTokensForUser(String userId) async {
    try {
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .get();

      final batch = _firestore.batch();
      for (var doc in tokensSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('All FCM tokens removed for user: $userId');
    } catch (e) {
      debugPrint('Error removing all FCM tokens: $e');
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentFcmToken;

  /// Setup foreground message handler
  void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
  }

  /// Setup background message handler (must be top-level function)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('Handling a background message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
  }
}
