import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/models/rider_review_model.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class RiderCard extends StatelessWidget {
  final UserModel rider;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onSetPassword;
  final VoidCallback? onDelete;

  const RiderCard({
    super.key,
    required this.rider,
    this.onTap,
    this.onEdit,
    this.onSetPassword,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.s16),
        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.s16),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: Sizes.s28,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: rider.photoUrl != null
                            ? CachedNetworkImageProvider(rider.photoUrl!)
                            : null,
                        child: rider.photoUrl == null
                            ? Icon(
                                TablerIconsHelper.truck,
                                color: Theme.of(context).colorScheme.primary,
                                size: Sizes.s28,
                              )
                            : null,
                      ),
                      // Online indicator
                      if (rider.isOnline == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: Sizes.s16,
                            height: Sizes.s16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: Sizes.s16),
                  // Rider Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider.name ?? 'No Name',
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: Sizes.s4),
                        Text(
                          rider.email,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (rider.phoneNumber != null) ...[
                          const SizedBox(height: Sizes.s4),
                          Row(
                            children: [
                              Icon(
                                TablerIconsHelper.phone,
                                size: Sizes.s14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: Sizes.s4),
                              Text(
                                rider.phoneNumber!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      TablerIconsHelper.dotsVertical,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'password':
                          onSetPassword?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(TablerIconsHelper.edit, size: Sizes.s18),
                            const SizedBox(width: Sizes.s8),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'password',
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: Sizes.s18),
                            const SizedBox(width: Sizes.s8),
                            const Text('Set Password'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(TablerIconsHelper.trash, size: Sizes.s18, color: Colors.red),
                            const SizedBox(width: Sizes.s8),
                            const Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s12),
              // Rider Reviews/Rating Section
              StreamBuilder<List<RiderReviewModel>>(
                stream: ReviewService.getRiderReviews(rider.id),
                builder: (context, reviewsSnapshot) {
                  double averageRating = 0.0;
                  int totalReviews = 0;
                  
                  if (reviewsSnapshot.hasData && reviewsSnapshot.data != null) {
                    final reviews = reviewsSnapshot.data!;
                    totalReviews = reviews.length;
                    if (totalReviews > 0) {
                      double totalRating = 0.0;
                      for (final review in reviews) {
                        totalRating += review.rating;
                      }
                      averageRating = totalRating / totalReviews;
                    }
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(Sizes.s12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(Sizes.s12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          TablerIconsHelper.star,
                          size: Sizes.s18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: Sizes.s8),
                        RatingStarsWidget(
                          rating: averageRating,
                          size: Sizes.s16,
                        ),
                        const SizedBox(width: Sizes.s8),
                        Text(
                          averageRating > 0 
                              ? averageRating.toStringAsFixed(1)
                              : 'No ratings',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: Sizes.s8),
                        Text(
                          '($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: Sizes.s12),
              // Status Chips
              Wrap(
                spacing: Sizes.s8,
                runSpacing: Sizes.s8,
                children: [
                  if (rider.isOnline == true)
                    _buildStatusChip(
                      context,
                      'Online',
                      Colors.green,
                    ),
                  if (rider.isAvailable == true)
                    _buildStatusChip(
                      context,
                      'Available',
                      Colors.blue,
                    ),
                  if (rider.cnic != null && rider.cnic!.isNotEmpty)
                    _buildStatusChip(
                      context,
                      'CNIC: ${rider.cnic}',
                      Colors.grey,
                    ),
                ],
              ),
              // Secondary Contact
              if (rider.secondaryContactNumber != null && rider.secondaryContactNumber!.isNotEmpty) ...[
                const SizedBox(height: Sizes.s8),
                Row(
                  children: [
                    Icon(
                      TablerIconsHelper.phone,
                      size: Sizes.s14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: Sizes.s4),
                    Text(
                      'Secondary: ${rider.secondaryContactNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionTiny.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
