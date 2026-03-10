import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';

class AdminSettingsService {
  AdminSettingsService._();
  static final AdminSettingsService instance = AdminSettingsService._();

  static const String _settingsCollection = 'appSettings';
  static const String _settingsDocId = 'main';

  /// Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final doc = await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocId)
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }

      // Return default settings if document doesn't exist
      return _getDefaultSettings();
    } catch (e) {
      print('Error getting settings: $e');
      return _getDefaultSettings();
    }
  }

  /// Update a specific setting
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocId)
          .set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating setting $key: $e');
      return false;
    }
  }

  /// Update multiple settings at once
  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocId)
          .set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }

  /// Get default settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'maintenanceMode': false,
      'allowNewRegistrations': true,
      'allowNewOrders': true,
      'minOrderAmount': 0.0,
      'maxDeliveryDistance': 10.0, // km
      'defaultDeliveryFee': 0.0,
      'defaultDeliveryPricePerKm': 5.0,
      'riderPaymentPerKm': 10.0, // Rs per km (round-trip) paid to rider; admin keeps 100% delivery fee
      'enableNotifications': true,
      'enablePushNotifications': true,
      'enableEmailNotifications': false,
      'orderAutoAccept': false,
      'riderAutoAssign': false,
      'appVersion': '1.0.0',
      'forceUpdate': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Stream settings for real-time updates
  Stream<Map<String, dynamic>> getSettingsStream() {
    return FirebaseService.firestore
        .collection(_settingsCollection)
        .doc(_settingsDocId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() ?? {};
      }
      return _getDefaultSettings();
    });
  }
}
