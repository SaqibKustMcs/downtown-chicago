import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String address;
  final String? label; // e.g., "Home", "Work", "Office"
  final String? note; // Note to rider, nearest landmark
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.address,
    this.label,
    this.note,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AddressModel(
      id: id,
      userId: data['userId'] as String,
      address: data['address'] as String,
      label: data['label'] as String?,
      note: data['note'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'address': address,
      if (label != null && label!.isNotEmpty) 'label': label,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? address,
    String? label,
    String? note,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      address: address ?? this.address,
      label: label ?? this.label,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
