import 'package:flutter/material.dart';
import 'package:downtown/modules/reviews/models/review_model.dart';
import 'package:downtown/modules/reviews/models/rider_review_model.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Widget to display review summary with average rating, total count, and rating distribution
/// Supports both rider reviews and product reviews
class ReviewSummaryWidget extends StatelessWidget {
  final List<RiderReviewModel>? riderReviews;
  final List<ProductReviewModel>? productReviews;
  final String? title; // Optional title (e.g., "Rider Name" or "Product Name")

  const ReviewSummaryWidget({super.key, this.riderReviews, this.productReviews, this.title})
    : assert((riderReviews != null && productReviews == null) || (riderReviews == null && productReviews != null), 'Must provide either riderReviews or productReviews, not both');

  List<double> get _ratings {
    if (riderReviews != null) {
      return riderReviews!.map((r) => r.rating.toDouble()).toList();
    } else if (productReviews != null) {
      return productReviews!.map((r) => r.rating.toDouble()).toList();
    }
    return [];
  }

  double get _averageRating {
    final ratings = _ratings;
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.fold<double>(0.0, (a, b) => a + b);
    return sum / ratings.length;
  }

  int get _totalReviews => _ratings.length;

  Map<int, int> get _ratingDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final rating in _ratings) {
      final star = rating.round().clamp(1, 5);
      distribution[star] = (distribution[star] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (optional)
            if (title != null && title!.isNotEmpty) ...[
              Text(
                title!,
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: Sizes.s16),
            ],

            // Average Rating Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large Rating Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold, fontSize: Sizes.s40, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(width: Sizes.s4),
                        Text('/ 5', style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(height: Sizes.s8),
                    RatingStarsWidget(rating: _averageRating, size: Sizes.s20),
                    const SizedBox(height: Sizes.s8),
                    Text('$_totalReviews review${_totalReviews == 1 ? '' : 's'}', style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
                SizedBox(width: 12),

                // Rating Distribution
                Expanded(
                  child: _RatingDistributionBar(distribution: _ratingDistribution, totalReviews: _totalReviews),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display rating distribution as horizontal bars
class _RatingDistributionBar extends StatelessWidget {
  final Map<int, int> distribution;
  final int totalReviews;

  const _RatingDistributionBar({required this.distribution, required this.totalReviews});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 5 stars
        _buildDistributionRow(context: context, stars: 5, count: distribution[5] ?? 0, total: totalReviews, isDark: isDark),
        const SizedBox(height: Sizes.s8),
        // 4 stars
        _buildDistributionRow(context: context, stars: 4, count: distribution[4] ?? 0, total: totalReviews, isDark: isDark),
        const SizedBox(height: Sizes.s8),
        // 3 stars
        _buildDistributionRow(context: context, stars: 3, count: distribution[3] ?? 0, total: totalReviews, isDark: isDark),
        const SizedBox(height: Sizes.s8),
        // 2 stars
        _buildDistributionRow(context: context, stars: 2, count: distribution[2] ?? 0, total: totalReviews, isDark: isDark),
        const SizedBox(height: Sizes.s8),
        // 1 star
        _buildDistributionRow(context: context, stars: 1, count: distribution[1] ?? 0, total: totalReviews, isDark: isDark),
      ],
    );
  }

  Widget _buildDistributionRow({required BuildContext context, required int stars, required int count, required int total, required bool isDark}) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (count / total) : 0.0;
    final barWidth = percentage * 100;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Star count label
        SizedBox(
          width: Sizes.s24,
          child: Text(
            '$stars',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.8)),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: Sizes.s4),
        // Star icon
        Icon(Icons.star, size: Sizes.s14, color: const Color(0xFFFF6B35)),
        const SizedBox(width: Sizes.s8),
        // Progress bar
        SizedBox(
          width: Sizes.s80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.s4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: Sizes.s8,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF6B35).withOpacity(0.7)),
            ),
          ),
        ),
        const SizedBox(width: Sizes.s8),
        // Count label
        SizedBox(
          width: Sizes.s32,
          child: Text(
            '$count',
            style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
