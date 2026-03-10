import 'dart:math' show pi, sin, cos, sqrt, atan2;

/// Distance and delivery fee calculation (Foodpanda-style).
/// Fee = distance (restaurant → customer) × price per KM.
/// Rider round trip (e.g. 10 km each way) is covered by using one-way distance × base price.
class DeliveryFeeUtil {
  static const double _earthRadiusKm = 6371.0;

  /// Haversine distance in KM between two points.
  static double distanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _toRadians(double deg) => deg * pi / 180;

  /// Calculate delivery fee: distance_km × pricePerKm.
  /// [restaurantLat], [restaurantLon]: restaurant location.
  /// [customerLat], [customerLon]: delivery address.
  /// [pricePerKm]: base price per KM (e.g. 5 rupees). Set 0 to return [fallbackFee].
  /// [fallbackFee]: used when distance cannot be calculated or pricePerKm is 0.
  static double calculate({
    required double? restaurantLat,
    required double? restaurantLon,
    required double? customerLat,
    required double? customerLon,
    required double pricePerKm,
    double fallbackFee = 0.0,
  }) {
    if (pricePerKm <= 0) return fallbackFee;
    if (restaurantLat == null ||
        restaurantLon == null ||
        customerLat == null ||
        customerLon == null) {
      return fallbackFee;
    }
    final km = distanceKm(
      lat1: restaurantLat,
      lon1: restaurantLon,
      lat2: customerLat,
      lon2: customerLon,
    );
    final fee = km * pricePerKm;
    return double.parse(fee.toStringAsFixed(2));
  }
}
