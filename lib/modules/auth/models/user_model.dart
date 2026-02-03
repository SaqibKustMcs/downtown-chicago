import 'package:cloud_firestore/cloud_firestore.dart';

/// User Type Enum
enum UserType {
  admin,
  customer,
  rider,
}

/// User Model
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? photoUrl;
  final String? userImage; // Alias for photoUrl, kept for compatibility
  final String? bio;
  final Map<String, double>? userLatLng; // {latitude: double, longitude: double}
  final String? address;
  final UserType userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool emailVerified;
  // Rider specific fields
  final bool? isAvailable;
  final String? vehicleType;
  final String? vehicleNumber;
  // Admin specific fields
  final String? restaurantId; // Admin's restaurant ID

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.userImage,
    this.bio,
    this.userLatLng,
    this.address,
    required this.userType,
    this.createdAt,
    this.updatedAt,
    this.emailVerified = false,
    this.isAvailable,
    this.vehicleType,
    this.vehicleNumber,
    this.restaurantId,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle userLatLng - can be Map or null
    Map<String, double>? latLng;
    if (data['userLatLng'] != null) {
      final latLngData = data['userLatLng'] as Map;
      latLng = {
        'latitude': (latLngData['latitude'] ?? latLngData['lat'] ?? 0.0).toDouble(),
        'longitude': (latLngData['longitude'] ?? latLngData['lng'] ?? 0.0).toDouble(),
      };
    }
    
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'] ?? data['userImage'],
      userImage: data['userImage'] ?? data['photoUrl'],
      bio: data['bio'],
      userLatLng: latLng,
      address: data['address'],
      userType: _parseUserType(data['userType'] ?? 'customer'),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      emailVerified: data['emailVerified'] ?? false,
      isAvailable: data['isAvailable'],
      vehicleType: data['vehicleType'],
      vehicleNumber: data['vehicleNumber'],
      restaurantId: data['restaurantId'],
    );
  }

  /// Parse user type from string
  static UserType _parseUserType(String type) {
    switch (type.toLowerCase()) {
      case 'admin':
        return UserType.admin;
      case 'rider':
        return UserType.rider;
      case 'customer':
      default:
        return UserType.customer;
    }
  }

  /// Create from Firebase User
  /// Note: userType defaults to customer. For full user data, fetch from Firestore.
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      photoUrl: firebaseUser.photoURL,
      userType: UserType.customer, // Default, should be fetched from Firestore
      emailVerified: firebaseUser.emailVerified,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (userImage != null) 'userImage': userImage,
      if (bio != null) 'bio': bio,
      if (userLatLng != null) 'userLatLng': userLatLng,
      if (address != null) 'address': address,
      'userType': userType.name, // 'admin', 'customer', or 'rider'
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'emailVerified': emailVerified,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (restaurantId != null) 'restaurantId': restaurantId,
    };
  }

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? userImage,
    String? bio,
    Map<String, double>? userLatLng,
    String? address,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? emailVerified,
    bool? isAvailable,
    String? vehicleType,
    String? vehicleNumber,
    String? restaurantId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      userImage: userImage ?? this.userImage,
      bio: bio ?? this.bio,
      userLatLng: userLatLng ?? this.userLatLng,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }
}
