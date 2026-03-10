import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:downtown/core/services/location_service.dart';
import 'package:downtown/modules/rider/services/rider_service.dart';

/// Service to handle periodic location updates for riders
class RiderLocationService {
  RiderLocationService._();
  static final RiderLocationService instance = RiderLocationService._();

  Timer? _locationUpdateTimer;
  String? _riderId;
  bool _isUpdating = false;

  /// Start periodic location updates for a rider
  /// Updates location every 30 seconds when rider is online and has active order
  Future<void> startLocationUpdates(String riderId) async {
    if (_isUpdating && _riderId == riderId) {
      debugPrint('Location updates already running for rider: $riderId');
      return;
    }

    _riderId = riderId;
    _isUpdating = true;

    // Update immediately
    await _updateLocation(riderId);

    // Then update every 30 seconds
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (!_isUpdating) {
          timer.cancel();
          return;
        }
        await _updateLocation(riderId);
      },
    );

    debugPrint('Started location updates for rider: $riderId (30 second interval)');
  }

  /// Stop periodic location updates
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isUpdating = false;
    _riderId = null;
    debugPrint('Stopped location updates');
  }

  /// Update rider's location in Firestore
  Future<void> _updateLocation(String riderId) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      // Check permission
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        debugPrint('Location permission not granted');
        return;
      }

      // Get current location
      final locationData = await LocationService.getCurrentLocationAndAddress();
      if (locationData == null) {
        debugPrint('Failed to get current location');
        return;
      }

      final latitude = locationData['latitude'] as double;
      final longitude = locationData['longitude'] as double;

      // Update in Firestore
      await RiderService.updateLocation(riderId, latitude, longitude);
      debugPrint('Updated rider location: $latitude, $longitude');
    } catch (e) {
      debugPrint('Error updating rider location: $e');
    }
  }

  /// Check if location updates are running
  bool get isUpdating => _isUpdating;
}
