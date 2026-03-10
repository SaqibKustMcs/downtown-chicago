import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/models/food_item_model.dart';
import 'package:downtown/modules/reviews/models/review_model.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/modules/reviews/widgets/review_card.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';

/// Shows all product reviews for a restaurant, grouped by product.
class RestaurantReviewsScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantReviewsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopNavigationBar(
              title: '$restaurantName Reviews',
              showBackButton: true,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection('products')
                    .where('restaurantId', isEqualTo: restaurantId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Sizes.s16),
                        child: Text(
                          'Error loading products: ${snapshot.error}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final productDocs = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];

                  if (productDocs.isEmpty) {
                    return _EmptyRestaurantReviewsState(restaurantName: restaurantName);
                  }

                  // Map products to FoodItem just to get name and id (lightweight)
                  final products = productDocs
                      .map(
                        (doc) => FoodItem.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(Sizes.s16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductReviewsSection(product: product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductReviewsSection extends StatelessWidget {
  final FoodItem product;

  const _ProductReviewsSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final productId = product.id;
    if (productId == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: Sizes.s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Sizes.s8),
                      child: Image.network(
                        product.imageUrl,
                        width: Sizes.s48,
                        height: Sizes.s48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (product.imageUrl.isNotEmpty) const SizedBox(width: Sizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s12),

              // Reviews list for this product
              StreamBuilder<List<ProductReviewModel>>(
                stream: ReviewService.getProductReviews(productId, adminView: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(Sizes.s8),
                      child: SizedBox(
                        width: Sizes.s20,
                        height: Sizes.s20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final reviews = snapshot.data ?? <ProductReviewModel>[];

                  if (reviews.isEmpty) {
                    return Text(
                      'No reviews for this product yet',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    );
                  }

                  final avg = _calculateAverageRating(reviews);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RatingStarsWidget(
                            rating: avg,
                            size: Sizes.s16,
                          ),
                          const SizedBox(width: Sizes.s6),
                          Text(
                            avg.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: Sizes.s4),
                          Text(
                            '(${reviews.length})',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s8),
                      ListView.builder(
                        itemCount: reviews.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          final currentUserId = DependencyInjection.instance.authController.currentUser?.id;
                          return ReviewCard(
                            productReview: review,
                            currentUserId: currentUserId,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateAverageRating(List<ProductReviewModel> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = 0.0;
    for (final review in reviews) {
      total += review.rating;
    }
    return total / reviews.length;
  }
}


class _EmptyRestaurantReviewsState extends StatelessWidget {
  final String restaurantName;

  const _EmptyRestaurantReviewsState({required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: Sizes.s64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: Sizes.s16),
            Text(
              'No reviews yet',
              style: AppTextStyles.heading3.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: Sizes.s8),
            Text(
              'Be the first to review $restaurantName.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

