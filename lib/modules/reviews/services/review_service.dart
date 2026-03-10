import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/reviews/models/rider_review_model.dart';
import 'package:downtown/modules/reviews/models/review_model.dart';
import 'package:downtown/modules/reviews/services/restaurant_rating_service.dart';

/// Service for handling reviews (rider + product)
class ReviewService {
  ReviewService._();

  static CollectionReference<Map<String, dynamic>> get _riderReviewsCollection =>
      FirebaseService.firestore.collection('riderReviews');

  /// Check if a rider review already exists for this customer and order
  static Future<bool> hasRiderReview({
    required String customerId,
    required String orderId,
  }) async {
    final snapshot = await _riderReviewsCollection
        .where('customerId', isEqualTo: customerId)
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Create a rider review
  /// Throws [Exception] if a review already exists for this customer and order
  static Future<String> createRiderReview({
    required String orderId,
    required String customerId,
    required String riderId,
    required double rating,
    String? comment,
  }) async {
    // Check for duplicate review
    final exists = await hasRiderReview(
      customerId: customerId,
      orderId: orderId,
    );

    if (exists) {
      throw Exception(
        'You have already reviewed this rider for order #${orderId.substring(0, 8).toUpperCase()}',
      );
    }

    final now = DateTime.now();
    final data = RiderReviewModel(
      id: '',
      orderId: orderId,
      customerId: customerId,
      riderId: riderId,
      rating: rating,
      comment: comment,
      createdAt: now,
    ).toFirestore();

    final docRef = await _riderReviewsCollection.add(data);

    // Mark order as having rider review
    await FirebaseService.firestore.collection('orders').doc(orderId).update({
      'hasRiderReview': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    return docRef.id;
  }

  /// Get all reviews for a rider (real-time)
  static Stream<List<RiderReviewModel>> getRiderReviews(String riderId) {
    return _riderReviewsCollection
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => RiderReviewModel.fromFirestore(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
    });
  }

  /// Get average rating for a rider
  static Future<double> getRiderAverageRating(String riderId) async {
    final snapshot = await _riderReviewsCollection
        .where('riderId', isEqualTo: riderId)
        .get();

    if (snapshot.docs.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      if (rating > 0) {
        total += rating;
        count++;
      }
    }

    if (count == 0) return 0.0;
    return total / count;
  }

  /// Check if a product review already exists for this customer, product, and order
  static Future<bool> hasProductReview({
    required String productId,
    required String customerId,
    String? orderId,
  }) async {
    final collection = FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews');

    Query<Map<String, dynamic>> query = collection.where(
      'customerId',
      isEqualTo: customerId,
    );

    // If orderId is provided, also check for orderId to prevent duplicates per order
    if (orderId != null && orderId.isNotEmpty) {
      query = query.where('orderId', isEqualTo: orderId);
    }

    final snapshot = await query.limit(1).get();

    return snapshot.docs.isNotEmpty;
  }

  /// Create a product review under products/{productId}/reviews/{reviewId}
  /// Throws [Exception] if a review already exists for this customer, product, and order
  static Future<String> createProductReview({
    required String productId,
    required String customerId,
    String? orderId,
    required double rating,
    String? comment,
  }) async {
    // Check for duplicate review
    final exists = await hasProductReview(
      productId: productId,
      customerId: customerId,
      orderId: orderId,
    );

    if (exists) {
      final orderText = orderId != null
          ? ' for order #${orderId.substring(0, 8).toUpperCase()}'
          : '';
      throw Exception(
        'You have already reviewed this product$orderText',
      );
    }

    final now = DateTime.now();
    final data = ProductReviewModel(
      id: '',
      productId: productId,
      customerId: customerId,
      orderId: orderId,
      rating: rating,
      comment: comment,
      createdAt: now,
      isApproved: false, // New reviews require admin approval
    ).toFirestore();

    final collection = FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews');

    final docRef = await collection.add(data);

    // If orderId is provided, mark order as having product reviews
    if (orderId != null && orderId.isNotEmpty) {
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'hasProductReviews': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }

    // Recalculate restaurant rating after adding a review
    _recalculateRestaurantRatingForProduct(productId).catchError((_) {
      // Silently handle errors - rating recalculation is not critical for user experience
    });

    return docRef.id;
  }

  /// Get all reviews for a product (real-time)
  /// For customers: only shows approved reviews
  /// For admins: shows all reviews
  static Stream<List<ProductReviewModel>> getProductReviews(
    String productId, {
    bool adminView = false, // If true, shows all reviews including pending
  }) {
    final collection = FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews');

    Query<Map<String, dynamic>> query = collection.orderBy('createdAt', descending: true);
    
    // For customer view, only show approved reviews
    if (!adminView) {
      query = query.where('isApproved', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => ProductReviewModel.fromFirestore(
              doc.data(),
              doc.id,
              productId,
            ),
          )
          .toList();
    });
  }

  /// Get average rating for a product (only counts approved reviews)
  static Future<double> getProductAverageRating(String productId) async {
    final collection = FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews');

    final snapshot = await collection.where('isApproved', isEqualTo: true).get();
    if (snapshot.docs.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      if (rating > 0) {
        total += rating;
        count++;
      }
    }

    if (count == 0) return 0.0;
    return total / count;
  }


  /// Get a rider review by ID
  static Future<RiderReviewModel?> getRiderReviewById(String reviewId) async {
    try {
      final doc = await _riderReviewsCollection.doc(reviewId).get();
      if (!doc.exists) return null;

      return RiderReviewModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Update a rider review
  /// Throws [Exception] if review doesn't exist or customer doesn't own it
  static Future<void> updateRiderReview({
    required String reviewId,
    required String customerId,
    required double rating,
    String? comment,
  }) async {
    final review = await getRiderReviewById(reviewId);
    if (review == null) {
      throw Exception('Review not found');
    }

    // Verify customer owns the review
    if (review.customerId != customerId) {
      throw Exception('You can only edit your own reviews');
    }

    // Update the review
    await _riderReviewsCollection.doc(reviewId).update({
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a rider review
  /// Throws [Exception] if review doesn't exist or customer doesn't own it
  static Future<void> deleteRiderReview({
    required String reviewId,
    required String customerId,
    required String orderId,
  }) async {
    final review = await getRiderReviewById(reviewId);
    if (review == null) {
      throw Exception('Review not found');
    }

    // Verify customer owns the review
    if (review.customerId != customerId) {
      throw Exception('You can only delete your own reviews');
    }

    // Delete the review
    await _riderReviewsCollection.doc(reviewId).delete();

    // Check if there are any other rider reviews for this order
    final otherReviews = await _riderReviewsCollection
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    // If no other reviews exist, unmark the order
    if (otherReviews.docs.isEmpty) {
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'hasRiderReview': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }
  }

  /// Get a product review by ID
  static Future<ProductReviewModel?> getProductReviewById({
    required String productId,
    required String reviewId,
  }) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (!doc.exists) return null;

      return ProductReviewModel.fromFirestore(doc.data()!, doc.id, productId);
    } catch (e) {
      return null;
    }
  }

  /// Update a product review
  /// Throws [Exception] if review doesn't exist or customer doesn't own it
  static Future<void> updateProductReview({
    required String productId,
    required String reviewId,
    required String customerId,
    required double rating,
    String? comment,
  }) async {
    final review = await getProductReviewById(
      productId: productId,
      reviewId: reviewId,
    );

    if (review == null) {
      throw Exception('Review not found');
    }

    // Verify customer owns the review
    if (review.customerId != customerId) {
      throw Exception('You can only edit your own reviews');
    }

    // Update the review
    await FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Recalculate restaurant rating after updating a review
    _recalculateRestaurantRatingForProduct(productId).catchError((_) {
      // Silently handle errors - rating recalculation is not critical for user experience
    });
  }

  /// Delete a product review
  /// Throws [Exception] if review doesn't exist or customer doesn't own it
  static Future<void> deleteProductReview({
    required String productId,
    required String reviewId,
    required String customerId,
    String? orderId,
  }) async {
    final review = await getProductReviewById(
      productId: productId,
      reviewId: reviewId,
    );

    if (review == null) {
      throw Exception('Review not found');
    }

    // Verify customer owns the review
    if (review.customerId != customerId) {
      throw Exception('You can only delete your own reviews');
    }

    // Delete the review
    await FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Recalculate restaurant rating after deleting a review
    _recalculateRestaurantRatingForProduct(productId).catchError((_) {
      // Silently handle errors - rating recalculation is not critical for user experience
    });

    // If orderId is provided, check if there are any other product reviews for this order
    if (orderId != null && orderId.isNotEmpty) {
      // Check if any product reviews exist for this order
      // Note: This is a simplified check - in production, you might want to check all products in the order
      final orderDoc = await FirebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        // Check if there are any other product reviews for products in this order
        final items = orderDoc.data()?['items'] as List<dynamic>? ?? [];
        bool hasOtherReviews = false;

        for (final item in items) {
          final itemProductId = item['productId'] as String?;
          if (itemProductId != null && itemProductId != productId) {
            final productReviews = await FirebaseService.firestore
                .collection('products')
                .doc(itemProductId)
                .collection('reviews')
                .where('customerId', isEqualTo: customerId)
                .where('orderId', isEqualTo: orderId)
                .limit(1)
                .get();

            if (productReviews.docs.isNotEmpty) {
              hasOtherReviews = true;
              break;
            }
          }
        }

        // If no other product reviews exist, unmark the order
        if (!hasOtherReviews) {
          await FirebaseService.firestore.collection('orders').doc(orderId).update({
            'hasProductReviews': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }).catchError((_) {});
        }
      }
    }
  }

  /// Check if a rider review can be edited/deleted (for UI display)
  /// Returns true if the customer owns the review
  static Future<bool> canEditRiderReview({
    required String reviewId,
    required String customerId,
  }) async {
    final review = await getRiderReviewById(reviewId);
    if (review == null) return false;
    return review.customerId == customerId;
  }

  /// Check if a product review can be edited/deleted (for UI display)
  /// Returns true if the customer owns the review
  static Future<bool> canEditProductReview({
    required String productId,
    required String reviewId,
    required String customerId,
  }) async {
    final review = await getProductReviewById(
      productId: productId,
      reviewId: reviewId,
    );
    if (review == null) return false;
    return review.customerId == customerId;
  }

  /// Helper method to recalculate restaurant rating for a product
  /// Fetches the product's restaurantId and triggers rating recalculation
  static Future<void> _recalculateRestaurantRatingForProduct(
    String productId,
  ) async {
    try {
      // Fetch the product document to get restaurantId
      final productDoc = await FirebaseService.firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) return;

      final productData = productDoc.data();
      final restaurantId = productData?['restaurantId'] as String?;

      if (restaurantId != null && restaurantId.isNotEmpty) {
        // Recalculate and update the restaurant's rating
        await RestaurantRatingService.recalculateAndUpdateRestaurantRating(
          restaurantId,
        );
      }
    } catch (e) {
      // Silently handle errors - rating recalculation is not critical
      // for the user experience, and we don't want to block review operations
    }
  }

  // ==================== ADMIN METHODS ====================

  /// Get all pending product reviews (for admin)
  /// Note: This uses collectionGroup which requires a Firestore index
  /// If index doesn't exist, Firestore will provide a link to create it
  static Stream<List<ProductReviewModel>> getPendingProductReviews() {
    try {
      return FirebaseService.firestore
          .collectionGroup('reviews')
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          // Extract productId from the document path: products/{productId}/reviews/{reviewId}
          final path = doc.reference.path;
          final parts = path.split('/');
          final productId = parts.length >= 4 && parts[0] == 'products' ? parts[1] : '';
          
          return ProductReviewModel.fromFirestore(
            doc.data(),
            doc.id,
            productId,
          );
        }).toList();
      });
    } catch (e) {
      // If collectionGroup query fails (e.g., missing index), return empty stream
      // Admin will need to create the Firestore index
      debugPrint('Error fetching pending reviews: $e');
      return Stream.value(<ProductReviewModel>[]);
    }
  }

  /// Get all product reviews (for admin - includes approved and pending)
  /// Note: This uses collectionGroup which requires a Firestore index
  /// If index doesn't exist, Firestore will provide a link to create it
  static Stream<List<ProductReviewModel>> getAllProductReviews() {
    try {
      return FirebaseService.firestore
          .collectionGroup('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          // Extract productId from the document path: products/{productId}/reviews/{reviewId}
          final path = doc.reference.path;
          final parts = path.split('/');
          final productId = parts.length >= 4 && parts[0] == 'products' ? parts[1] : '';
          
          return ProductReviewModel.fromFirestore(
            doc.data(),
            doc.id,
            productId,
          );
        }).toList();
      });
    } catch (e) {
      // If collectionGroup query fails (e.g., missing index), return empty stream
      // Admin will need to create the Firestore index
      debugPrint('Error fetching all reviews: $e');
      return Stream.value(<ProductReviewModel>[]);
    }
  }

  /// Approve a product review (admin only)
  static Future<void> approveProductReview({
    required String productId,
    required String reviewId,
    required String adminId,
  }) async {
    final now = DateTime.now();
    await FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'isApproved': true,
      'approvedBy': adminId,
      'approvedAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Recalculate restaurant rating after approving a review
    _recalculateRestaurantRatingForProduct(productId).catchError((_) {});
  }

  /// Disapprove/reject a product review (admin only)
  static Future<void> disapproveProductReview({
    required String productId,
    required String reviewId,
    required String adminId,
  }) async {
    final now = DateTime.now();
    await FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'isApproved': false,
      'approvedBy': adminId,
      'approvedAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Recalculate restaurant rating after disapproving a review
    _recalculateRestaurantRatingForProduct(productId).catchError((_) {});
  }

  /// Delete a product review (admin only)
  static Future<void> deleteProductReviewByAdmin({
    required String productId,
    required String reviewId,
  }) async {
    await FirebaseService.firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    // Recalculate restaurant rating after deleting a review
    _recalculateRestaurantRatingForProduct(productId).catchError((_) {});
  }

  /// Check if user can review a product (within 1 hour of delivery)
  static Future<bool> canReviewProduct({
    required String orderId,
  }) async {
    try {
      final orderDoc = await FirebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return false;

      final orderData = orderDoc.data();
      final status = orderData?['status'] as String?;
      
      // Only allow reviews for delivered orders
      if (status != 'delivered') return false;

      // Prefer deliveredAt, fallback to updatedAt if deliveredAt doesn't exist
      Timestamp? deliveryTimestamp = orderData?['deliveredAt'] as Timestamp?;
      if (deliveryTimestamp == null) {
        deliveryTimestamp = orderData?['updatedAt'] as Timestamp?;
      }
      
      if (deliveryTimestamp == null) return false;

      final deliveryTime = deliveryTimestamp.toDate();
      final now = DateTime.now();
      final timeDifference = now.difference(deliveryTime);

      // Allow review only within 1 hour (60 minutes)
      return timeDifference.inHours < 1;
    } catch (e) {
      return false;
    }
  }
}
