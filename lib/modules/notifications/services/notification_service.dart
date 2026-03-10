import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/models/notification_model.dart';

class NotificationService {
  NotificationService._();

  /// Create an in-app notification in Firestore
  /// Prevents duplicate notifications for the same order and type within 2 minutes
  static Future<String> createInAppNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? orderId,
  }) async {
    try {
      debugPrint('📝 Creating in-app notification for userId: $userId');
      
      // Validate inputs
      if (userId.isEmpty) {
        throw Exception('userId cannot be empty');
      }
      if (title.isEmpty && body.isEmpty) {
        throw Exception('Title and body cannot both be empty');
      }
      
      // Check for duplicate notifications (same orderId, type, and title) within last 2 minutes
      if (orderId != null && orderId.isNotEmpty) {
        final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));
        final recentNotifications = await FirebaseService.firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('orderId', isEqualTo: orderId)
            .where('type', isEqualTo: NotificationModel.typeToFirestore(type))
            .where('title', isEqualTo: title)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(twoMinutesAgo))
            .limit(1)
            .get();

        if (recentNotifications.docs.isNotEmpty) {
          debugPrint('⚠️ Duplicate notification prevented for order $orderId, type $type, title: $title');
          return recentNotifications.docs.first.id; // Return existing notification ID
        }
      }

      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'type': NotificationModel.typeToFirestore(type),
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📤 Writing notification to Firestore: users/$userId/notifications');
      debugPrint('   Data: $notificationData');

      final docRef = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      debugPrint('✅ Created notification: "$title" for user $userId, orderId: $orderId, notificationId: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating in-app notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send push notification to a user
  static Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all FCM tokens for the user
      final tokensSnapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .get();

      if (tokensSnapshot.docs.isEmpty) {
        debugPrint('No FCM tokens found for user: $userId');
        return false;
      }

      final tokens = tokensSnapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .whereType<String>()
          .toList();

      if (tokens.isEmpty) {
        debugPrint('⚠️ No valid FCM tokens found for user: $userId');
        return false;
      }

      // Note: Local notifications are now handled by NotificationListenerService
      // which listens to Firestore changes and shows notifications on the recipient's device.
      // For actual FCM push notifications (when app is closed), implement Cloud Functions
      // that listen to notification creation in Firestore and send FCM messages.

      debugPrint('📤 Push notification prepared for user: $userId');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      debugPrint('   Data: $data');
      debugPrint('   Tokens: ${tokens.length} device(s)');
      debugPrint('   Note: Notification will be shown via NotificationListenerService');

      return true;
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }

  /// Create notification and send push (combined)
  static Future<bool> notifyUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? orderId,
    bool sendPush = true,
  }) async {
    try {
      debugPrint('🔔 notifyUser called for userId: $userId');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      debugPrint('   Type: $type');
      debugPrint('   OrderId: $orderId');
      
      // Validate userId
      if (userId.isEmpty) {
        debugPrint('❌ Error: userId is empty');
        return false;
      }
      
      // Create in-app notification
      final notificationId = await createInAppNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        orderId: orderId,
      );
      
      debugPrint('✅ In-app notification created: $notificationId');

      // Send push notification if requested
      if (sendPush) {
        final pushResult = await sendPushNotification(
          userId: userId,
          title: title,
          body: body,
          data: orderId != null ? {'orderId': orderId, 'type': NotificationModel.typeToFirestore(type)} : null,
        );
        
        if (pushResult) {
          debugPrint('✅ Push notification prepared');
        } else {
          debugPrint('⚠️ Push notification preparation returned false');
        }
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error notifying user: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get notifications for a user
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return FirebaseService.firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final notificationsSnapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseService.firestore.batch();
      for (final doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String userId, String notificationId) async {
    try {
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Get unread count
  /// Counts notifications where isRead is false or null (null means unread)
  static Stream<int> getUnreadCount(String userId) {
    try {
      return FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .snapshots()
          .map((snapshot) {
        // Count notifications where isRead is false or null
        int count = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final isRead = data['isRead'];
          // Count as unread if isRead is false or null (null means unread by default)
          if (isRead == null || isRead == false) {
            count++;
          }
        }
        debugPrint('Unread notification count for user $userId: $count');
        return count;
      }).handleError((error) {
        debugPrint('Error getting unread count: $error');
        return 0; // Return 0 on error
      });
    } catch (e) {
      debugPrint('Exception in getUnreadCount: $e');
      return Stream.value(0);
    }
  }
}
