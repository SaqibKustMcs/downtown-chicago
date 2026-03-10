import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final String deliveryCost; // e.g., "Free", "$2.99" (display string)
  final double deliveryFee; // Fallback fixed fee when distance-based not used
  final double deliveryPricePerKm; // Base price per KM for distance-based fee (e.g. 5 Rs/km)
  final String deliveryTime; // e.g., "20 min", "30-45 min"
  final String? address;
  final Map<String, double>? location; // {latitude: double, longitude: double}
  final bool isOpen; // Manual override (if null, calculated from opening/closing times)
  final String? openingTime; // Format: "HH:mm" e.g., "09:00"
  final String? closingTime; // Format: "HH:mm" e.g., "22:00"
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
    this.deliveryFee = 0.0,
    this.deliveryPricePerKm = 5.0,
    required this.deliveryTime,
    this.address,
    this.location,
    this.isOpen = true,
    this.openingTime,
    this.closingTime,
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
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      deliveryPricePerKm: (data['deliveryPricePerKm'] ?? 5.0).toDouble(),
      deliveryTime: data['deliveryTime'] ?? '20 - 50 mins',
      address: data['address'],
      location: loc,
      isOpen: data['isOpen'] as bool? ?? true, // Store manual override, will be recalculated dynamically
      openingTime: data['openingTime'] as String?,
      closingTime: data['closingTime'] as String?,
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
      'deliveryFee': deliveryFee,
      'deliveryPricePerKm': deliveryPricePerKm,
      'deliveryTime': deliveryTime,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      'isOpen': isOpen,
      if (openingTime != null && openingTime!.isNotEmpty) 'openingTime': openingTime,
      if (closingTime != null && closingTime!.isNotEmpty) 'closingTime': closingTime,
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
    double? deliveryFee,
    double? deliveryPricePerKm,
    String? deliveryTime,
    String? address,
    Map<String, double>? location,
    bool? isOpen,
    String? openingTime,
    String? closingTime,
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
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryPricePerKm: deliveryPricePerKm ?? this.deliveryPricePerKm,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      address: address ?? this.address,
      location: location ?? this.location,
      isOpen: isOpen ?? this.isOpen,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      isActive: isActive ?? this.isActive,
      adminId: adminId ?? this.adminId,
      categoryNames: categoryNames ?? this.categoryNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate if restaurant is currently open based on opening/closing times
  /// Returns manual override if set, otherwise calculates from opening/closing times
  static bool _calculateIsOpen({
    bool? manualIsOpen,
    String? openingTime,
    String? closingTime,
  }) {
    // If manual override is explicitly set to false, restaurant is closed
    if (manualIsOpen == false) {
      return false;
    }

    // If no opening/closing times are set, use manual override or default to true
    if (openingTime == null || openingTime.isEmpty || closingTime == null || closingTime.isEmpty) {
      return manualIsOpen ?? true;
    }

    // Parse opening and closing times
    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);

      // Parse opening time (format: "HH:mm")
      final openingParts = openingTime.split(':');
      final openingHour = int.parse(openingParts[0]);
      final openingMinute = int.parse(openingParts[1]);
      final opening = TimeOfDay(hour: openingHour, minute: openingMinute);

      // Parse closing time (format: "HH:mm")
      final closingParts = closingTime.split(':');
      final closingHour = int.parse(closingParts[0]);
      final closingMinute = int.parse(closingParts[1]);
      final closing = TimeOfDay(hour: closingHour, minute: closingMinute);

      // Convert to minutes for easier comparison
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final openingMinutes = opening.hour * 60 + opening.minute;
      final closingMinutes = closing.hour * 60 + closing.minute;

      // Handle case where closing time is next day (e.g., 22:00 to 02:00)
      if (closingMinutes < openingMinutes) {
        // Restaurant closes next day
        return currentMinutes >= openingMinutes || currentMinutes < closingMinutes;
      } else {
        // Normal case: opening and closing on same day
        return currentMinutes >= openingMinutes && currentMinutes < closingMinutes;
      }
    } catch (e) {
      // If parsing fails, fall back to manual override or default to true
      return manualIsOpen ?? true;
    }
  }

  /// Check if restaurant is currently open (recalculates based on current time)
  bool get isCurrentlyOpen {
    return Restaurant._calculateIsOpen(
      manualIsOpen: isOpen,
      openingTime: openingTime,
      closingTime: closingTime,
    );
  }

  /// Get formatted opening hours string (e.g., "09:00 AM - 10:00 PM")
  String? get formattedOpeningHours {
    if (openingTime == null || openingTime!.isEmpty || closingTime == null || closingTime!.isEmpty) {
      return null;
    }

    try {
      final openingParts = openingTime!.split(':');
      final closingParts = closingTime!.split(':');
      final openingHour = int.parse(openingParts[0]);
      final openingMinute = int.parse(openingParts[1]);
      final closingHour = int.parse(closingParts[0]);
      final closingMinute = int.parse(closingParts[1]);

      final opening = TimeOfDay(hour: openingHour, minute: openingMinute);
      final closing = TimeOfDay(hour: closingHour, minute: closingMinute);

      final openingFormat = _formatTimeOfDay(opening);
      final closingFormat = _formatTimeOfDay(closing);

      return '$openingFormat - $closingFormat';
    } catch (e) {
      return null;
    }
  }

  /// Format TimeOfDay to 12-hour format string
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
