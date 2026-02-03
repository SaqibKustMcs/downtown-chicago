import 'package:cloud_firestore/cloud_firestore.dart';

/// Category Model
class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int? order;
  final bool isActive;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.order,
    this.isActive = true,
    this.createdAt,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      if (order != null) 'order': order,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
