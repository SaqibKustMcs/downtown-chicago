import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/reviews/models/rider_review_model.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/widgets/review_card.dart';
import 'package:downtown/modules/reviews/widgets/review_summary_widget.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Screen where riders can see reviews they've received
class UserReviewsScreen extends StatelessWidget {
  const UserReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text('Please login to view reviews'),
        ),
      );
    }

    // For riders, show their own reviews
    if (currentUser.userType == UserType.rider) {
      return _RiderReviewsView(riderId: currentUser.id);
    }

    // For admin, show admin reviews screen (product reviews)
    if (currentUser.userType == UserType.admin) {
      // Navigate to admin reviews screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, Routes.adminReviews);
      });
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Fallback for customers (shouldn't reach here)
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('Reviews not available'),
      ),
    );
  }
}

class _RiderReviewsView extends StatelessWidget {
  final String riderId;

  const _RiderReviewsView({required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigationBar(
              title: 'My Reviews',
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Sizes.s32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TablerIconsHelper.star,
                              size: Sizes.s64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            ),
                            const SizedBox(height: Sizes.s16),
                            Text(
                              'No reviews yet',
                              style: AppTextStyles.heading3.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              'You haven\'t received any reviews yet.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RepaintBoundary(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Sizes.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReviewSummaryWidget(
                            riderReviews: reviews,
                            title: 'My Reviews',
                          ),
                          const SizedBox(height: Sizes.s16),
                          ListView.builder(
                            itemCount: reviews.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              final currentUserId =
                                  DependencyInjection.instance.authController.currentUser?.id;
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
