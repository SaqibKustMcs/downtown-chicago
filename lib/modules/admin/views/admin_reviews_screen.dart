import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/reviews/models/review_model.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authController = DependencyInjection.instance.authController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    
    // Role guard - only admins can access
    if (currentUser == null || currentUser.userType != UserType.admin) {
      return RoleGuard.guard(
        context: context,
        requiredRole: UserType.admin,
        child: const SizedBox.shrink(),
        accessDeniedMessage: 'Access denied. Admin only.',
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopNavigationBar(title: 'Product Reviews', showBackButton: true),
            
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
              child: Row(
                children: [
                  _buildTab('Pending', 0),
                  const SizedBox(width: Sizes.s24),
                  _buildTab('All Reviews', 1),
                ],
              ),
            ),
            const SizedBox(height: Sizes.s8),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingReviewsTab(),
                  _buildAllReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: _tabController.index == index
                  ? const Color(0xFFFF6B35)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: _tabController.index == index ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: Sizes.s8),
          Container(
            width: Sizes.s40,
            height: Sizes.s2,
            decoration: BoxDecoration(
              color: _tabController.index == index ? const Color(0xFFFF6B35) : Colors.transparent,
              borderRadius: BorderRadius.circular(Sizes.s1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewsTab() {
    return StreamBuilder<List<ProductReviewModel>>(
      stream: ReviewService.getPendingProductReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reviews: ${snapshot.error}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  TablerIconsHelper.check,
                  size: Sizes.s80,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s24),
                Text(
                  'No pending reviews',
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                Text(
                  'All reviews have been reviewed',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Sizes.s12),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            return _buildReviewCard(reviews[index], isPending: true);
          },
        );
      },
    );
  }

  Widget _buildAllReviewsTab() {
    return StreamBuilder<List<ProductReviewModel>>(
      stream: ReviewService.getAllProductReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reviews: ${snapshot.error}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  TablerIconsHelper.star,
                  size: Sizes.s80,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s24),
                Text(
                  'No reviews yet',
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Sizes.s12),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            return _buildReviewCard(reviews[index], isPending: false);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(ProductReviewModel review, {required bool isPending}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProductAndCustomerInfo(review),
      builder: (context, snapshot) {
        final productData = snapshot.data;
        final productName = productData?['productName'] as String? ?? 'Unknown Product';
        final productImage = productData?['productImage'] as String? ?? '';
        final customerName = productData?['customerName'] as String? ?? 'Customer';

        return Container(
          margin: const EdgeInsets.only(bottom: Sizes.s16),
          padding: const EdgeInsets.all(Sizes.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(
              color: isPending
                  ? Colors.orange.withOpacity(0.5)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              width: isPending ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info
              Row(
                children: [
                  if (productImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Sizes.s8),
                      child: CachedNetworkImage(
                        imageUrl: productImage,
                        width: Sizes.s60,
                        height: Sizes.s60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: Sizes.s60,
                          height: Sizes.s60,
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: Sizes.s60,
                          height: Sizes.s60,
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: Icon(
                            TablerIconsHelper.restaurant,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  if (productImage.isNotEmpty) const SizedBox(width: Sizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Sizes.s4),
                        Text(
                          'By: $customerName',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sizes.s8,
                        vertical: Sizes.s4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Sizes.s4),
                      ),
                      child: Text(
                        'PENDING',
                        style: AppTextStyles.captionTiny.copyWith(
                          color: Colors.orange,
                          fontSize: Sizes.s10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Sizes.s12),

              // Rating
              Row(
                children: [
                  RatingStarsWidget(rating: review.rating, size: Sizes.s20),
                  const SizedBox(width: Sizes.s8),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s8),

              // Comment
              if (review.comment != null && review.comment!.isNotEmpty)
                Text(
                  review.comment!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              const SizedBox(height: Sizes.s8),

              // Date
              if (review.createdAt != null)
                Text(
                  'Reviewed: ${dateFormat.format(review.createdAt!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),

              // Approval Status
              if (review.isApproved && review.approvedAt != null) ...[
                const SizedBox(height: Sizes.s4),
                Row(
                  children: [
                    Icon(
                      TablerIconsHelper.check,
                      size: Sizes.s14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: Sizes.s4),
                    Text(
                      'Approved ${dateFormat.format(review.approvedAt!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],

              // Action Buttons
              if (isPending) ...[
                const SizedBox(height: Sizes.s16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveReview(review),
                        icon: const Icon(Icons.check, color: Colors.white, size: Sizes.s16),
                        label: Text(
                          'Approve',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Sizes.s8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                        ),
                      ),
                    ),
                    const SizedBox(width: Sizes.s12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _disapproveReview(review),
                        icon: const Icon(Icons.close, color: Colors.red, size: Sizes.s16),
                        label: Text(
                          'Reject',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Sizes.s8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                        ),
                      ),
                    ),
                    const SizedBox(width: Sizes.s8),
                    IconButton(
                      icon: Icon(
                        TablerIconsHelper.trash,
                        color: Colors.red,
                        size: Sizes.s20,
                      ),
                      onPressed: () => _deleteReview(review),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: Sizes.s12),
                Row(
                  children: [
                    if (!review.isApproved)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveReview(review),
                          icon: const Icon(Icons.check, color: Colors.white, size: Sizes.s16),
                          label: Text(
                            'Approve',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Sizes.s8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                          ),
                        ),
                      ),
                    if (!review.isApproved) const SizedBox(width: Sizes.s12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteReview(review),
                        icon: const Icon(Icons.delete, color: Colors.red, size: Sizes.s16),
                        label: Text(
                          'Delete',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Sizes.s8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getProductAndCustomerInfo(ProductReviewModel review) async {
    try {
      // Get product info
      final productDoc = await FirebaseService.firestore
          .collection('products')
          .doc(review.productId)
          .get();

      final productData = productDoc.data();
      final productName = productData?['name'] as String? ?? 'Unknown Product';
      final productImage = productData?['imageUrl'] as String? ?? '';

      // Get customer info
      String customerName = 'Customer';
      if (review.customerId.isNotEmpty) {
        final customerDoc = await FirebaseService.firestore
            .collection('users')
            .doc(review.customerId)
            .get();

        final customerData = customerDoc.data();
        customerName = customerData?['name'] as String? ?? 'Customer';
      }

      return {
        'productName': productName,
        'productImage': productImage,
        'customerName': customerName,
      };
    } catch (e) {
      return {
        'productName': 'Unknown Product',
        'productImage': '',
        'customerName': 'Customer',
      };
    }
  }

  Future<void> _approveReview(ProductReviewModel review) async {
    final currentUser = _authController.currentUser;
    if (currentUser?.id == null) return;

    try {
      await ReviewService.approveProductReview(
        productId: review.productId,
        reviewId: review.id,
        adminId: currentUser!.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Review approved successfully',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error approving review: ${e.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disapproveReview(ProductReviewModel review) async {
    final currentUser = _authController.currentUser;
    if (currentUser?.id == null) return;

    try {
      await ReviewService.disapproveProductReview(
        productId: review.productId,
        reviewId: review.id,
        adminId: currentUser!.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Review rejected',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error rejecting review: ${e.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(ProductReviewModel review) async {
    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: Sizes.s24,
            ),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                'Delete Review',
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this review? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReviewService.deleteProductReviewByAdmin(
        productId: review.productId,
        reviewId: review.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Review deleted successfully',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting review: ${e.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
