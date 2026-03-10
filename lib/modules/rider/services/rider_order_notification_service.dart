import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/orders/models/order_model.dart';

/// Service to handle order notifications for riders
/// Plays sound and manages notification state when new orders are assigned
class RiderOrderNotificationService {
  RiderOrderNotificationService._();
  static final RiderOrderNotificationService instance = RiderOrderNotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _orderSubscription;
  String? _currentRiderId;
  String? _lastOrderId;
  bool _isPlaying = false;

  /// Start listening for pending orders for a rider
  void startListening(String riderId) {
    if (_currentRiderId == riderId && _orderSubscription != null) {
      return; // Already listening
    }

    stopListening();
    _currentRiderId = riderId;
    _lastOrderId = null;

    _orderSubscription = FirebaseService.firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: OrderModel.statusToFirestore(OrderStatus.assignedToRider))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final latestOrder = snapshot.docs.first;
          final orderId = latestOrder.id;
          final orderData = latestOrder.data() as Map<String, dynamic>;
          final createdAt = orderData['createdAt'] as Timestamp?;
          
          // Play sound only for new orders (not the same as last one)
          // Also check if order was created recently (within last 30 seconds) to avoid replaying old orders
          final isNewOrder = _lastOrderId != orderId;
          final isRecentOrder = createdAt != null && 
              DateTime.now().difference(createdAt.toDate()).inSeconds < 30;
          
          if (isNewOrder && isRecentOrder && !_isPlaying) {
            _lastOrderId = orderId;
            _playNotificationSound();
            debugPrint('New order assigned to rider: $orderId');
          } else if (isNewOrder && !isRecentOrder) {
            // Order exists but is not recent - update lastOrderId without playing sound
            _lastOrderId = orderId;
          }
        } else {
          // No pending orders
          _lastOrderId = null;
        }
      },
      onError: (error) {
        debugPrint('Error listening for rider orders: $error');
      },
    );

    debugPrint('Started listening for pending orders for rider: $riderId');
  }

  /// Stop listening for orders
  void stopListening() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _currentRiderId = null;
    _lastOrderId = null;
    debugPrint('Stopped listening for rider orders');
  }

  /// Play notification sound
  Future<void> _playNotificationSound() async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;
      
      // Play notification sound - try custom sound first, then fallback to system sound
      try {
        // Try to play custom sound file
        await _audioPlayer.play(AssetSource('sounds/order_notification.mp3'));
        // Wait for sound to complete
        await _audioPlayer.onPlayerComplete.first.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Sound playback timeout');
            _isPlaying = false;
          },
        );
        _isPlaying = false;
      } catch (e) {
        debugPrint('Custom sound file not found or error: $e');
        // Fallback: Use haptic feedback as notification indicator
        // The visual animation in the bottom nav bar will be the main indicator
        try {
          debugPrint('Using visual animation as notification indicator (sound file not available)');
          // Note: Add a proper notification sound file to assets/sounds/order_notification.mp3
          // For now, the fade animation in the bottom nav bar serves as the notification
          _isPlaying = false;
        } catch (fallbackError) {
          debugPrint('Error with fallback notification: $fallbackError');
          _isPlaying = false;
        }
      }
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
      _isPlaying = false;
    }
  }

  /// Check if there are pending orders
  Future<bool> hasPendingOrders(String riderId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('status', isEqualTo: OrderModel.statusToFirestore(OrderStatus.assignedToRider))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending orders: $e');
      return false;
    }
  }

  /// Get stream of pending orders count
  Stream<int> getPendingOrdersCount(String riderId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: OrderModel.statusToFirestore(OrderStatus.assignedToRider))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _audioPlayer.dispose();
  }
}
