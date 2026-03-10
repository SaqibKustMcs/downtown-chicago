import 'package:cloud_firestore/cloud_firestore.dart';

/// Product review model
class ProductReviewModel {
  final String id;
  final String productId;
  final String customerId;
  final String? orderId;
  final double rating; // 1.0 - 5.0
  final String? comment;
  final DateTime? createdAt;
  final bool isApproved; // Admin approval status
  final String? approvedBy; // Admin ID who approved/disapproved
  final DateTime? approvedAt; // When admin approved/disapproved

  const ProductReviewModel({
    required this.id,
    required this.productId,
    required this.customerId,
    this.orderId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.isApproved = false, // Default to false (pending approval)
    this.approvedBy,
    this.approvedAt,
  });

  factory ProductReviewModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String productId,
  ) {
    return ProductReviewModel(
      id: id,
      productId: productId,
      customerId: data['customerId'] as String? ?? '',
      orderId: data['orderId'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isApproved: data['isApproved'] as bool? ?? false,
      approvedBy: data['approvedBy'] as String?,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'customerId': customerId,
      if (orderId != null && orderId!.isNotEmpty) 'orderId': orderId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'isApproved': isApproved,
      if (approvedBy != null && approvedBy!.isNotEmpty) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
    };
  }
}
