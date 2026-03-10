import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';

/// Service responsible for calculating and updating restaurant ratings
/// based on product reviews.
class RestaurantRatingService {
  RestaurantRatingService._();

  /// Recalculate and update the restaurant's average rating and totalRatings
  /// based on all product reviews for products belonging to this restaurant.
  static Future<void> recalculateAndUpdateRestaurantRating(
    String restaurantId,
  ) async {
    final firestore = FirebaseService.firestore;

    // 1. Fetch all products for this restaurant
    final productsSnapshot = await firestore
        .collection('products')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    if (productsSnapshot.docs.isEmpty) {
      // No products: reset rating and totalRatings to 0
      await _updateRestaurantRatingFields(
        restaurantId: restaurantId,
        averageRating: 0.0,
        totalRatings: 0,
      );
      return;
    }

    double totalRating = 0.0;
    int ratingCount = 0;

    // 2. For each product, sum ratings from its reviews subcollection
    for (final productDoc in productsSnapshot.docs) {
      final productId = productDoc.id;
      final reviewsSnapshot = await firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .get();

      for (final reviewDoc in reviewsSnapshot.docs) {
        final data = reviewDoc.data();
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        if (rating > 0) {
          totalRating += rating;
          ratingCount++;
        }
      }
    }

    final averageRating = ratingCount == 0 ? 0.0 : totalRating / ratingCount;

    // 3. Update restaurant document with aggregate rating
    await _updateRestaurantRatingFields(
      restaurantId: restaurantId,
      averageRating: averageRating,
      totalRatings: ratingCount,
    );
  }

  /// Get the current average rating for a restaurant from its document.
  /// This assumes `rating` field is maintained via [recalculateAndUpdateRestaurantRating].
  static Future<double> getRestaurantRating(String restaurantId) async {
    final doc = await FirebaseService.firestore
        .collection('restaurants')
        .doc(restaurantId)
        .get();

    if (!doc.exists) return 0.0;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return 0.0;
    return (data['rating'] ?? 0.0).toDouble();
  }

  static Future<void> _updateRestaurantRatingFields({
    required String restaurantId,
    required double averageRating,
    required int totalRatings,
  }) async {
    await FirebaseService.firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update(<String, dynamic>{
      'rating': averageRating,
      'totalRatings': totalRatings,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {
      // If restaurant doesn't exist or update fails, we silently ignore here.
    });
  }
}

