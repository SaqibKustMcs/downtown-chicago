import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';

/// Service to fetch rider location from Firestore
class RiderLocationService {
  RiderLocationService._();

  /// Get rider location stream
  static Stream<Map<String, double>?> getRiderLocationStream(String riderId) {
    return FirebaseService.firestore
        .collection('users')
        .doc(riderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      final latLngData = data['userLatLng'];
      if (latLngData == null) return null;

      return {
        'latitude': (latLngData['latitude'] ?? latLngData['lat'] ?? 0.0).toDouble(),
        'longitude': (latLngData['longitude'] ?? latLngData['lng'] ?? 0.0).toDouble(),
      };
    });
  }

  /// Get rider location once
  static Future<Map<String, double>?> getRiderLocation(String riderId) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(riderId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      final latLngData = data['userLatLng'];
      if (latLngData == null) return null;

      return {
        'latitude': (latLngData['latitude'] ?? latLngData['lat'] ?? 0.0).toDouble(),
        'longitude': (latLngData['longitude'] ?? latLngData['lng'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }
}
