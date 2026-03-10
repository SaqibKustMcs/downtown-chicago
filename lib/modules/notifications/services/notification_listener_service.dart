import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/models/notification_model.dart';

/// Service to listen for new notifications and show local push notifications
class NotificationListenerService {
  NotificationListenerService._();
  static final NotificationListenerService instance = NotificationListenerService._();

  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  String? _currentUserId;
  Set<String> _processedNotificationIds = {};
  DateTime? _listenerStartTime; // Track when listener started
  bool _isInitialLoad = true; // Track if this is the first load

  /// Start listening for new notifications for a user
  void startListening(String userId) {
    if (_currentUserId == userId && _notificationSubscription != null) {
      // Already listening for this user
      debugPrint('Already listening for user: $userId');
      return;
    }

    // Stop previous listener if any
    stopListening();

    _currentUserId = userId;
    _processedNotificationIds.clear();
    _listenerStartTime = DateTime.now();
    _isInitialLoad = true;

    try {
      // Listen to all notifications, but only process new ones after initial load
      _notificationSubscription = FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) async {
              // Safety check: ensure we have a valid userId
              if (_currentUserId == null || _currentUserId != userId) {
                debugPrint('⚠️ Listener userId mismatch, stopping processing');
                return;
              }

              if (snapshot.docs.isEmpty) {
                _isInitialLoad = false; // Mark initial load as complete even if empty
                return;
              }

              final now = DateTime.now();

              // Process document changes
              for (final docChange in snapshot.docChanges) {
                final doc = docChange.doc;
                final notificationId = doc.id;
                final data = doc.data() as Map<String, dynamic>;

                // Skip if we've already processed this notification
                if (_processedNotificationIds.contains(notificationId)) {
                  continue;
                }

                // Get createdAt timestamp
                Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
                if (createdAtTimestamp == null) {
                  debugPrint('Notification $notificationId has no createdAt timestamp, skipping');
                  continue;
                }

                final createdAt = createdAtTimestamp.toDate();

                // On initial load, mark all existing notifications as processed without showing them
                if (_isInitialLoad) {
                  _processedNotificationIds.add(notificationId);
                  debugPrint('Marked existing notification as processed: $notificationId (Created: $createdAt)');
                  continue;
                }

                // After initial load, only process newly added documents
                if (docChange.type != DocumentChangeType.added) {
                  continue;
                }

                // Only process notifications created after listener started (to avoid duplicates)
                // Or notifications created within the last 10 minutes (to catch any missed ones)
                final isAfterListenerStart = _listenerStartTime != null && createdAt.isAfter(_listenerStartTime!);
                final isRecent = createdAt.isAfter(now.subtract(const Duration(minutes: 10)));

                if (isAfterListenerStart || isRecent) {
                  _processedNotificationIds.add(notificationId);

                  try {
                    // Validate required fields before parsing
                    final title = data['title'] as String? ?? '';
                    final body = data['body'] as String? ?? '';

                    if (title.isEmpty && body.isEmpty) {
                      debugPrint('⚠️ Skipping notification $notificationId: missing title and body');
                      continue;
                    }

                    final notification = NotificationModel.fromFirestore(data, notificationId);

                    // Ensure title and body are not empty
                    final finalTitle = notification.title.isNotEmpty ? notification.title : 'Notification';
                    final finalBody = notification.body.isNotEmpty ? notification.body : 'You have a new notification';

                    // Show local notification with error handling
                    await PushNotificationService.instance
                        .showLocalNotification(
                          title: finalTitle,
                          body: finalBody,
                          data: {
                            'type': NotificationModel.typeToFirestore(notification.type),
                            if (notification.orderId != null && notification.orderId!.isNotEmpty) 'orderId': notification.orderId!,
                            'notificationId': notificationId,
                          },
                        )
                        .catchError((error) {
                          debugPrint('❌ Error showing local notification: $error');
                        });

                    debugPrint('✅ Local notification shown: $finalTitle (ID: $notificationId, Created: $createdAt)');
                  } catch (e, stackTrace) {
                    debugPrint('❌ Error processing notification: $e');
                    debugPrint('Stack trace: $stackTrace');
                    // Continue processing other notifications even if one fails
                  }
                } else {
                  debugPrint('⏭️ Skipping notification: $notificationId (Created: $createdAt, too old)');
                }
              }

              // Mark initial load as complete after processing first batch
              if (_isInitialLoad) {
                _isInitialLoad = false;
                debugPrint('✅ Initial notification load complete. Now listening for new notifications.');
              }
            },
            onError: (error) {
              debugPrint('❌ Error listening to notifications: $error');
              // Try to restart listener after a delay
              Future.delayed(const Duration(seconds: 5), () {
                if (_currentUserId == userId) {
                  debugPrint('🔄 Attempting to restart notification listener...');
                  stopListening();
                  startListening(userId);
                }
              });
            },
          );

      debugPrint('✅ Started listening for notifications for user: $userId');
    } catch (e) {
      debugPrint('❌ Error starting notification listener: $e');
    }
  }

  /// Stop listening for notifications
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    _processedNotificationIds.clear();
    _listenerStartTime = null;
    _isInitialLoad = true;
    debugPrint('🛑 Stopped listening for notifications');
  }

  /// Clear processed notifications (useful when user logs out)
  void clearProcessedNotifications() {
    _processedNotificationIds.clear();
    _listenerStartTime = null;
    _isInitialLoad = true;
  }
}
