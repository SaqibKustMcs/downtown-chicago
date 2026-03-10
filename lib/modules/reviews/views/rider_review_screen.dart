import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/reviews/models/rider_review_model.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/widgets/review_card.dart';
import 'package:downtown/modules/reviews/widgets/review_summary_widget.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Screen where customers (or admins) can see all reviews for a rider
class RiderReviewScreen extends StatelessWidget {
  final String riderId;
  final String? riderName;

  const RiderReviewScreen({
    super.key,
    required this.riderId,
    this.riderName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigationBar(
              title: 'Rider Reviews',
              showBackButton: true,
            ),
            Expanded(
              child: StreamBuilder<List<RiderReviewModel>>(
                stream: ReviewService.getRiderReviews(riderId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Sizes.s16),
                        child: Text(
                          'Error loading reviews: ${snapshot.error}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final reviews = snapshot.data ?? <RiderReviewModel>[];

                  if (reviews.isEmpty) {
                    return _EmptyReviewsState(riderName: riderName);
                  }

                  return RepaintBoundary(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Sizes.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReviewSummaryWidget(
                            riderReviews: reviews,
                            title: riderName,
                          ),
                          const SizedBox(height: Sizes.s16),
                          ListView.builder(
                            itemCount: reviews.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              final currentUserId = DependencyInjection.instance.authController.currentUser?.id;
                              return ReviewCard(
                                riderReview: review,
                                currentUserId: currentUserId,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

class _EmptyReviewsState extends StatelessWidget {
  final String? riderName;

  const _EmptyReviewsState({this.riderName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: Sizes.s64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: Sizes.s16),
            Text(
              'No reviews yet',
              style: AppTextStyles.heading3.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: Sizes.s8),
            Text(
              riderName != null && riderName!.isNotEmpty
                  ? 'Be the first to review ${riderName!}.'
                  : 'Be the first to review this rider.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

