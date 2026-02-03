import 'package:cloud_firestore/cloud_firestore.dart';

/// Restaurant Model
/// Supports multiple restaurants, each managed by an admin
class Restaurant {
  final String? id; // Firestore document ID
  final String name;
  final String cuisines; // Comma-separated string like "Burger - Chicken - Rice - Wings"
  final String imageUrl; // Main restaurant image
  final List<String>? bannerImages; // Multiple images for carousel
  final String? description;
  final double rating; // Average rating
  final int totalRatings; // Total number of ratings
  final String deliveryCost; // e.g., "Free", "$2.99"
  final String deliveryTime; // e.g., "20 min", "30-45 min"
  final String? address;
  final Map<String, double>? location; // {latitude: double, longitude: double}
  final bool isOpen;
  final bool isActive;
  final String? adminId; // Reference to users/{adminId}
  final List<String>? categoryNames; // List of category names this restaurant serves
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Restaurant({
    this.id,
    required this.name,
    required this.cuisines,
    required this.imageUrl,
    this.bannerImages,
    this.description,
    this.rating = 0.0,
    this.totalRatings = 0,
    required this.deliveryCost,
    required this.deliveryTime,
    this.address,
    this.location,
    this.isOpen = true,
    this.isActive = true,
    this.adminId,
    this.categoryNames,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle location - can be Map or null
    Map<String, double>? loc;
    if (data['location'] != null) {
      final locData = data['location'] as Map;
      loc = {
        'latitude': (locData['latitude'] ?? locData['lat'] ?? 0.0).toDouble(),
        'longitude': (locData['longitude'] ?? locData['lng'] ?? 0.0).toDouble(),
      };
    }

    // Handle bannerImages - can be List or null
    List<String>? banners;
    if (data['bannerImages'] != null) {
      banners = List<String>.from(data['bannerImages']);
    }

    // Handle categoryNames - can be List or null
    List<String>? categories;
    if (data['categoryNames'] != null) {
      categories = List<String>.from(data['categoryNames']);
    }

    return Restaurant(
      id: id,
      name: data['name'] ?? '',
      cuisines: data['cuisines'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      bannerImages: banners,
      description: data['description'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      deliveryCost: data['deliveryCost'] ?? 'Free',
      deliveryTime: data['deliveryTime'] ?? '20 min',
      address: data['address'],
      location: loc,
      isOpen: data['isOpen'] ?? true,
      isActive: data['isActive'] ?? true,
      adminId: data['adminId'],
      categoryNames: categories,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cuisines': cuisines,
      'imageUrl': imageUrl,
      if (bannerImages != null && bannerImages!.isNotEmpty)
        'bannerImages': bannerImages,
      if (description != null) 'description': description,
      'rating': rating,
      'totalRatings': totalRatings,
      'deliveryCost': deliveryCost,
      'deliveryTime': deliveryTime,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      'isOpen': isOpen,
      'isActive': isActive,
      if (adminId != null) 'adminId': adminId,
      if (categoryNames != null && categoryNames!.isNotEmpty)
        'categoryNames': categoryNames,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Copy with method
  Restaurant copyWith({
    String? id,
    String? name,
    String? cuisines,
    String? imageUrl,
    List<String>? bannerImages,
    String? description,
    double? rating,
    int? totalRatings,
    String? deliveryCost,
    String? deliveryTime,
    String? address,
    Map<String, double>? location,
    bool? isOpen,
    bool? isActive,
    String? adminId,
    List<String>? categoryNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisines: cuisines ?? this.cuisines,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerImages: bannerImages ?? this.bannerImages,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      address: address ?? this.address,
      location: location ?? this.location,
      isOpen: isOpen ?? this.isOpen,
      isActive: isActive ?? this.isActive,
      adminId: adminId ?? this.adminId,
      categoryNames: categoryNames ?? this.categoryNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
