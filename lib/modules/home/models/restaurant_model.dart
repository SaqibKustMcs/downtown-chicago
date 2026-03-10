import 'package:cloud_firestore/cloud_firestore.dart';

/// Restaurant Model (Firestore compatible)
class RestaurantModel {
  final String id;
  final String name;
  final String cuisines;
  final String imageUrl;
  final double rating;
  final String deliveryCost;
  final String deliveryTime;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isOpen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.cuisines,
    required this.imageUrl,
    required this.rating,
    required this.deliveryCost,
    required this.deliveryTime,
    this.address,
    this.latitude,
    this.longitude,
    this.isOpen = true,
    this.createdAt,
    this.updatedAt,
  });

  factory RestaurantModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RestaurantModel(
      id: id,
      name: data['name'] ?? '',
      cuisines: data['cuisines'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      deliveryCost: data['deliveryCost'] ?? 'Free',
      deliveryTime: data['deliveryTime'] ?? '20 - 50 mins',
      address: data['address'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isOpen: data['isOpen'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cuisines': cuisines,
      'imageUrl': imageUrl,
      'rating': rating,
      'deliveryCost': deliveryCost,
      'deliveryTime': deliveryTime,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isOpen': isOpen,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Convert to legacy Restaurant model for backward compatibility
  Restaurant toLegacy() {
    return Restaurant(
      name: name,
      cuisines: cuisines,
      imageUrl: imageUrl,
      rating: rating,
      deliveryCost: deliveryCost,
      deliveryTime: deliveryTime,
    );
  }
}

/// Legacy Restaurant model (for backward compatibility)
class Restaurant {
  final String name;
  final String cuisines;
  final String imageUrl;
  final double rating;
  final String deliveryCost;
  final String deliveryTime;

  const Restaurant({
    required this.name,
    required this.cuisines,
    required this.imageUrl,
    required this.rating,
    required this.deliveryCost,
    required this.deliveryTime,
  });
}
