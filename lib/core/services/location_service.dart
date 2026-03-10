import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Result of checking if location can be used (device location on + app permission).
enum LocationAccessStatus {
  /// Location services are on and permission granted.
  ready,
  /// Device location is turned off in system settings.
  serviceDisabled,
  /// User denied the permission (can ask again).
  permissionDenied,
  /// User permanently denied; must open app settings.
  permissionDeniedForever,
}

class LocationService {
  LocationService._();

  /// Check if we can get location: device location on and app permission granted.
  /// If permission is denied, requests it (shows system dialog).
  static Future<LocationAccessStatus> checkLocationAccess() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationAccessStatus.permissionDenied;
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationAccessStatus.permissionDeniedForever;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationAccessStatus.permissionDeniedForever;
    }

    return LocationAccessStatus.ready;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  static Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      Placemark place = placemarks[0];
      
      // Build address string
      List<String> addressParts = [];
      
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      if (addressParts.isEmpty) {
        // Fallback to name or formatted address
        return place.name ?? place.toString();
      }

      return addressParts.join(', ');
    } catch (e) {
      return null;
    }
  }

  /// Get current location and address
  static Future<Map<String, dynamic>?> getCurrentLocationAndAddress() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) {
        return null;
      }

      final address = await getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address ?? 'Unknown location',
      };
    } catch (e) {
      return null;
    }
  }
}
