import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/location/models/address_model.dart';

class AddressService {
  AddressService._();

  /// Get all addresses for a user
  static Stream<List<AddressModel>> getUserAddresses(String userId) {
    return FirebaseService.firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AddressModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get default address for a user
  static Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AddressModel.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      debugPrint('Error getting default address: $e');
      return null;
    }
  }

  /// Add a new address
  static Future<String> addAddress({
    required String userId,
    required String address,
    String? label,
    String? note,
    double? latitude,
    double? longitude,
    bool setAsDefault = false,
  }) async {
    try {
      // If setting as default, unset other default addresses
      if (setAsDefault) {
        await _unsetDefaultAddresses(userId);
      }

      final addressData = AddressModel(
        id: '',
        userId: userId,
        address: address,
        label: label,
        note: note,
        latitude: latitude,
        longitude: longitude,
        isDefault: setAsDefault,
        createdAt: DateTime.now(),
      ).toFirestore();

      final docRef = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .add(addressData);

      // Update user's main address field if this is default
      if (setAsDefault) {
        await FirebaseService.firestore.collection('users').doc(userId).update({
          'address': address,
          if (latitude != null && longitude != null)
            'userLatLng': {
              'latitude': latitude,
              'longitude': longitude,
            },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  /// Update an address
  static Future<void> updateAddress({
    required String userId,
    required String addressId,
    String? address,
    String? label,
    String? note,
    double? latitude,
    double? longitude,
    bool? setAsDefault,
  }) async {
    try {
      final addressRef = FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId);

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (address != null) updateData['address'] = address;
      if (label != null) updateData['label'] = label;
      if (note != null) updateData['note'] = note;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (setAsDefault != null) {
        updateData['isDefault'] = setAsDefault;
        if (setAsDefault) {
          await _unsetDefaultAddresses(userId, excludeId: addressId);
        }
      }

      await addressRef.update(updateData);

      // Update user's main address field if this is default
      if (setAsDefault == true && address != null) {
        await FirebaseService.firestore.collection('users').doc(userId).update({
          'address': address,
          if (latitude != null && longitude != null)
            'userLatLng': {
              'latitude': latitude,
              'longitude': longitude,
            },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  /// Delete an address
  static Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }

  /// Set an address as default
  static Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      await _unsetDefaultAddresses(userId, excludeId: addressId);

      final addressRef = FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId);

      final addressDoc = await addressRef.get();
      if (!addressDoc.exists) {
        throw Exception('Address not found');
      }

      final addressData = addressDoc.data()!;
      await addressRef.update({
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's main address field
      await FirebaseService.firestore.collection('users').doc(userId).update({
        'address': addressData['address'] as String,
        if (addressData['latitude'] != null && addressData['longitude'] != null)
          'userLatLng': {
            'latitude': addressData['latitude'],
            'longitude': addressData['longitude'],
          },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }

  /// Unset all default addresses for a user
  static Future<void> _unsetDefaultAddresses(String userId, {String? excludeId}) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .where('isDefault', isEqualTo: true)
          .get();

      final batch = FirebaseService.firestore.batch();
      for (final doc in snapshot.docs) {
        if (excludeId == null || doc.id != excludeId) {
          batch.update(doc.reference, {
            'isDefault': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error unsetting default addresses: $e');
    }
  }
}
