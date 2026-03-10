import 'package:cloud_firestore/cloud_firestore.dart';

class Variation {
  final String name;
  final double price;
  final String? description;

  const Variation({
    required this.name,
    required this.price,
    this.description,
  });

  factory Variation.fromMap(Map<String, dynamic> map) {
    return Variation(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}

class Flavor {
  final String name;
  final double price;
  final String? description;

  const Flavor({
    required this.name,
    required this.price,
    this.description,
  });

  factory Flavor.fromMap(Map<String, dynamic> map) {
    return Flavor(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}

class FoodItem {
  final String? id; // Firestore document ID
  final String name;
  final String restaurantName; // Denormalized restaurant name
  final String? restaurantId; // Reference to restaurant
  final String imageUrl;
  final double basePrice; // Base price
  final String? description;
  final List<String>? imageUrls; // For image slider
  final List<Variation>? variations; // e.g., Small, Medium, Large
  final List<Flavor>? flavors; // e.g., Spicy, Mild, Extra Spicy
  final String? categoryId; // Reference to categories/{categoryId}
  final String? categoryName; // Denormalized category name
  final bool isAvailable;
  final bool isActive;
  final bool isPopular; // Whether product should be shown in "Popular Products" section
  final int displayOrder; // Order for displaying products within category (lower = shown first)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodItem({
    this.id,
    required this.name,
    required this.restaurantName,
    this.restaurantId,
    required this.imageUrl,
    required this.basePrice,
    this.description,
    this.imageUrls,
    this.variations,
    this.flavors,
    this.categoryId,
    this.categoryName,
    this.isAvailable = true,
    this.isActive = true,
    this.isPopular = false,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory FoodItem.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle variations
    List<Variation>? variationsList;
    if (data['variations'] != null) {
      final variationsData = data['variations'] as List;
      variationsList = variationsData
          .map((v) => Variation.fromMap(v as Map<String, dynamic>))
          .toList();
    }

    // Handle flavors
    List<Flavor>? flavorsList;
    if (data['flavors'] != null) {
      final flavorsData = data['flavors'] as List;
      flavorsList = flavorsData
          .map((f) => Flavor.fromMap(f as Map<String, dynamic>))
          .toList();
    }

    // Handle imageUrls
    List<String>? imageUrlsList;
    if (data['imageUrls'] != null) {
      imageUrlsList = List<String>.from(data['imageUrls']);
    }

    return FoodItem(
      id: id,
      name: data['name'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantId: data['restaurantId'],
      imageUrl: data['imageUrl'] ?? '',
      basePrice: (data['basePrice'] ?? 0.0).toDouble(),
      description: data['description'],
      imageUrls: imageUrlsList,
      variations: variationsList,
      flavors: flavorsList,
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],
      isAvailable: data['isAvailable'] ?? true,
      isActive: data['isActive'] ?? true,
      isPopular: data['isPopular'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
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
      'restaurantName': restaurantName,
      if (restaurantId != null) 'restaurantId': restaurantId,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      if (description != null) 'description': description,
      if (imageUrls != null && imageUrls!.isNotEmpty) 'imageUrls': imageUrls,
      if (variations != null && variations!.isNotEmpty)
        'variations': variations!.map((v) => v.toMap()).toList(),
      if (flavors != null && flavors!.isNotEmpty)
        'flavors': flavors!.map((f) => f.toMap()).toList(),
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'isPopular': isPopular,
      'displayOrder': displayOrder,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Copy with method
  FoodItem copyWith({
    String? id,
    String? name,
    String? restaurantName,
    String? restaurantId,
    String? imageUrl,
    double? basePrice,
    String? description,
    List<String>? imageUrls,
    List<Variation>? variations,
    List<Flavor>? flavors,
    String? categoryId,
    String? categoryName,
    bool? isAvailable,
    bool? isActive,
    bool? isPopular,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantId: restaurantId ?? this.restaurantId,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      variations: variations ?? this.variations,
      flavors: flavors ?? this.flavors,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get price for backward compatibility
  double get price => basePrice;
}
