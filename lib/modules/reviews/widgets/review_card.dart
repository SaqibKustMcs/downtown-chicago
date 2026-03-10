import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/reviews/models/review_model.dart';
import 'package:downtown/modules/reviews/models/rider_review_model.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

/// Card widget to display a single review (rider or product)
/// Fetches customer name from Firestore and displays rating, comment, and date
/// Shows edit/delete buttons if the current user owns the review and it's within the time limit
class ReviewCard extends StatefulWidget {
  final RiderReviewModel? riderReview;
  final ProductReviewModel? productReview;
  final String? currentUserId;
  final VoidCallback? onReviewUpdated;
  final VoidCallback? onReviewDeleted;

  const ReviewCard({
    super.key,
    this.riderReview,
    this.productReview,
    this.currentUserId,
    this.onReviewUpdated,
    this.onReviewDeleted,
  }) : assert(
          (riderReview != null && productReview == null) ||
              (riderReview == null && productReview != null),
          'Must provide either riderReview or productReview, not both',
        );

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {

  String get _customerId {
    return widget.riderReview?.customerId ?? widget.productReview?.customerId ?? '';
  }

  double get _rating {
    return widget.riderReview?.rating ?? widget.productReview?.rating ?? 0.0;
  }

  String? get _comment {
    return widget.riderReview?.comment ?? widget.productReview?.comment;
  }

  DateTime? get _createdAt {
    return widget.riderReview?.createdAt ?? widget.productReview?.createdAt;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = _formatDate(_createdAt);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: Sizes.s12),
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Sizes.s12),
          border: Border.all(color: theme.brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Customer Name + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CustomerNameWidget(customerId: _customerId)),
                if (dateText.isNotEmpty) Text(dateText, style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: Sizes.s12),

            // Rating
            RatingStarsWidget(rating: _rating, size: Sizes.s16),
            const SizedBox(height: Sizes.s12),

            // Comment
            if (_comment != null && _comment!.isNotEmpty) Text(_comment!, style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface, height: 1.5)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}

/// Widget to fetch and display customer name from Firestore
class _CustomerNameWidget extends StatelessWidget {
  final String customerId;

  const _CustomerNameWidget({required this.customerId});

  @override
  Widget build(BuildContext context) {
    if (customerId.isEmpty) {
      return Text(
        'Anonymous',
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.firestore.collection('users').doc(customerId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Loading...',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            'Customer',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          );
        }

        final userData = snapshot.data!.data();
        final firstName = userData?['firstName'] as String? ?? '';
        final lastName = userData?['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();

        return Text(
          fullName.isNotEmpty ? fullName : 'Customer',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        );
      },
    );
  }
}