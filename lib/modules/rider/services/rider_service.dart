import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';

class RiderService {
  RiderService._();

  /// Update rider online/offline status
  static Future<bool> updateOnlineStatus(String riderId, bool isOnline) async {
    try {
      // Check if rider has active orders before setting availability
      final activeOrdersSnapshot = await FirebaseService.firestore
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('status', whereIn: [
            OrderModel.statusToFirestore(OrderStatus.assignedToRider),
            OrderModel.statusToFirestore(OrderStatus.acceptedByRider),
            OrderModel.statusToFirestore(OrderStatus.pickedUp),
            OrderModel.statusToFirestore(OrderStatus.onTheWay),
          ])
          .limit(1)
          .get();

      final hasActiveOrder = activeOrdersSnapshot.docs.isNotEmpty;

      await FirebaseService.firestore.collection('users').doc(riderId).update({
        'isOnline': isOnline,
        // Only set isAvailable to true if going online AND no active orders
        // If going offline, set isAvailable to false
        'isAvailable': isOnline && !hasActiveOrder,
        if (!isOnline) 'activeOrderId': null, // Clear active order when going offline
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update rider availability (can be online but not available if has active order)
  static Future<bool> updateAvailability(String riderId, bool isAvailable) async {
    try {
      await FirebaseService.firestore.collection('users').doc(riderId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update rider's current location
  static Future<bool> updateLocation(
    String riderId,
    double latitude,
    double longitude,
  ) async {
    try {
      await FirebaseService.firestore.collection('users').doc(riderId).update({
        'userLatLng': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get available riders (online and available)
  static Stream<List<UserModel>> getAvailableRiders() {
    return FirebaseService.firestore
        .collection('users')
        .where('userType', isEqualTo: 'rider')
        .where('isOnline', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return UserModel.fromFirestore(
                doc.data(),
                doc.id,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<UserModel>()
          .toList();
    });
  }

  /// Get available riders once (non-stream)
  static Future<List<UserModel>> getAvailableRidersOnce() async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('users')
          .where('userType', isEqualTo: 'rider')
          .where('isOnline', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return UserModel.fromFirestore(
                doc.data(),
                doc.id,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<UserModel>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
