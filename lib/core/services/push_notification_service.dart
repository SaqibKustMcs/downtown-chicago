import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:downtown/core/firebase/firebase_service.dart';

/// Push Notification Service - Handles FCM tokens, permissions, and device management
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseService.messaging;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _currentDeviceId;
  String? _currentFcmToken;
  bool _isInitialized = false;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

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
      final settings = await _messaging.requestPermission(alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);

      return settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      if (!initialized!) {
        debugPrint('⚠️ Local notifications initialization returned false');
        return;
      }

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'food_flow_channel',
          'Food Flow Notifications',
          description: 'Notifications for orders, updates, and more',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);

        // Request permissions for Android 13+
        await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('✅ Local notifications initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing local notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false; // Ensure we don't mark as initialized on error
    }
  }

  /// Initialize push notifications and get FCM token
  Future<String?> initializeAndGetToken() async {
    try {
      // Initialize local notifications first
      await initializeLocalNotifications();

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
      await _firestore.collection('users').doc(user.uid).collection('fcmTokens').doc(deviceId).set({
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
      await _firestore.collection('users').doc(user.uid).collection('fcmTokens').doc(deviceId).update({'token': token, 'updatedAt': FieldValue.serverTimestamp()});
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

      await _firestore.collection('users').doc(user.uid).collection('fcmTokens').doc(deviceId).delete();

      debugPrint('FCM token removed successfully for device: $deviceId');
      _currentFcmToken = null;
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Remove all FCM tokens for a user (used when deleting account)
  Future<void> removeAllTokensForUser(String userId) async {
    try {
      final tokensSnapshot = await _firestore.collection('users').doc(userId).collection('fcmTokens').get();

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

  /// Show local notification
  Future<void> showLocalNotification({required String title, required String body, Map<String, dynamic>? data}) async {
    try {
      // Validate inputs
      if (title.isEmpty && body.isEmpty) {
        debugPrint('⚠️ Cannot show notification: both title and body are empty');
        return;
      }

      // Ensure initialization
      if (!_isInitialized) {
        await initializeLocalNotifications();
        // Double check after initialization
        if (!_isInitialized) {
          debugPrint('⚠️ Local notifications not initialized, cannot show notification');
          return;
        }
      }

      // Ensure title and body are not null
      final finalTitle = title.isNotEmpty ? title : 'Notification';
      final finalBody = body.isNotEmpty ? body : 'You have a new notification';

      const androidDetails = AndroidNotificationDetails(
        'food_flow_channel',
        'Food Flow Notifications',
        channelDescription: 'Notifications for orders, updates, and more',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

      const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Generate a unique notification ID
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(notificationId, finalTitle, finalBody, notificationDetails, payload: data != null ? data.toString() : null);

      debugPrint('✅ Local notification shown: $finalTitle');
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing local notification: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - we don't want notification errors to crash the app
    }
  }

  /// Setup foreground message handler (only call once)
  void setupForegroundMessageHandler() {
    // Cancel existing subscription if any
    _foregroundMessageSubscription?.cancel();

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📬 Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      debugPrint('Message notification: ${message.notification?.title} - ${message.notification?.body}');

      try {
        String? title;
        String? body;
        Map<String, dynamic>? data;

        // Show local notification when app is in foreground
        if (message.notification != null) {
          title = message.notification!.title;
          body = message.notification!.body;
          data = message.data;
        } else if (message.data.isNotEmpty) {
          // If no notification payload, show from data
          title = message.data['title'] as String?;
          body = message.data['body'] as String? ?? message.data['message'] as String?;
          data = message.data;
        }

        // Only show notification if we have at least title or body
        final hasTitle = title?.isNotEmpty == true;
        final hasBody = body?.isNotEmpty == true;

        if (hasTitle || hasBody) {
          await showLocalNotification(title: title ?? 'Notification', body: body ?? '', data: data).catchError((error) {
            debugPrint('❌ Error in showLocalNotification: $error');
          });
        } else {
          debugPrint('⚠️ Skipping notification: no title or body available');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error showing foreground notification: $e');
        debugPrint('Stack trace: $stackTrace');
        // Don't rethrow - we don't want notification errors to crash the app
      }
    });

    debugPrint('✅ Foreground message handler setup complete');
  }

  /// Setup background message handler (must be top-level function)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    try {
      debugPrint('📬 Handling a background message: ${message.messageId}');
      debugPrint('Message data: ${message.data}');

      // Initialize local notifications in background
      final localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      final initialized = await localNotifications.initialize(initSettings);

      if (!initialized!) {
        debugPrint('⚠️ Background: Local notifications initialization returned false');
        return;
      }

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'food_flow_channel',
          'Food Flow Notifications',
          description: 'Notifications for orders, updates, and more',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
      }

      // Determine title and body
      String? title;
      String? body;

      if (message.notification != null) {
        title = message.notification!.title;
        body = message.notification!.body;
      } else if (message.data.isNotEmpty) {
        title = message.data['title'] as String?;
        body = message.data['body'] as String? ?? message.data['message'] as String?;
      }

      // Only show if we have at least title or body
      final hasTitle = title?.isNotEmpty == true;
      final hasBody = body?.isNotEmpty == true;

      if (!hasTitle && !hasBody) {
        debugPrint('⚠️ Background: Skipping notification - no title or body');
        return;
      }

      // Show notification
      const androidDetails = AndroidNotificationDetails(
        'food_flow_channel',
        'Food Flow Notifications',
        channelDescription: 'Notifications for orders, updates, and more',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

      const notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await localNotifications.show(notificationId, title ?? 'Notification', body ?? '', notificationDetails, payload: message.data.toString());

      debugPrint('✅ Background notification shown: ${title ?? "Notification"}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in background message handler: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - background handlers should never crash
    }
  }
}
