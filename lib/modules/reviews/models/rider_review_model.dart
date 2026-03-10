import 'package:cloud_firestore/cloud_firestore.dart';

/// Rider review model
class RiderReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String riderId;
  final double rating; // 1.0 - 5.0
  final String? comment;
  final DateTime? createdAt;

  const RiderReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.riderId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory RiderReviewModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return RiderReviewModel(
      id: id,
      orderId: data['orderId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      riderId: data['riderId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'orderId': orderId,
      'customerId': customerId,
      'riderId': riderId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

