import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_status_chip.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<OrderModel?>(
          stream: OrderService.getOrderStream(widget.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Column(
                children: [
                  TopNavigationBar(
                    title: 'Order Details',
                    showBackButton: true,
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: Sizes.s64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'Order not found',
                            style: AppTextStyles.heading3.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final order = snapshot.data!;
            return Column(
              children: [
                TopNavigationBar(
                  title: 'Order Details',
                  showBackButton: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Sizes.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Status
                        Center(
                          child: OrderStatusChip(status: order.status),
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Modification Notice (if order was modified)
                        if (order.isModified) _buildModificationNotice(order),
                        if (order.isModified) const SizedBox(height: Sizes.s16),

                        // Order Info Card
                        _buildOrderInfoCard(order),
                        const SizedBox(height: Sizes.s16),

                        // Items List
                        _buildItemsSection(order),
                        const SizedBox(height: Sizes.s16),

                        // Delivery Address
                        if (order.deliveryAddress != null)
                          _buildAddressSection(order),
                        const SizedBox(height: Sizes.s16),

                        // Price Summary
                        _buildPriceSummary(order),
                        const SizedBox(height: Sizes.s16),

                        // Action Buttons
                        _buildActionButtons(order),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s16),
          _buildInfoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
          if (order.restaurantName != null)
            _buildInfoRow('Restaurant', order.restaurantName!),
          if (order.createdAt != null)
            _buildInfoRow('Order Date', dateFormat.format(order.createdAt!)),
          _buildInfoRow('Payment Method', 'Cash on Delivery'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sizes.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModificationNotice(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: Sizes.s20,
              ),
              const SizedBox(width: Sizes.s8),
              Text(
                'Order Modified',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s8),
          if (order.modificationNote != null && order.modificationNote!.isNotEmpty) ...[
            Text(
              order.modificationNote!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: Sizes.s8),
          ],
          Text(
            'Some items in your order have been modified. Please review the updated order below.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.orange.shade700,
            ),
          ),
          if (order.modifiedAt != null) ...[
            const SizedBox(height: Sizes.s8),
            Text(
              'Modified on: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.modifiedAt!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.orange.shade700.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Sizes.s12),
        ...order.items.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }

  Widget _buildOrderItemCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.s8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'] as String? ?? '',
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
                  Icons.fastfood,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: Sizes.s12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? 'Item',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (item['selectedVariation'] != null ||
                    item['selectedFlavor'] != null) ...[
                  const SizedBox(height: Sizes.s4),
                  Text(
                    [
                      if (item['selectedVariation'] != null)
                        item['selectedVariation'],
                      if (item['selectedFlavor'] != null) item['selectedFlavor'],
                    ].join(' • '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: Sizes.s4),
                Text(
                  'Qty: ${item['quantity'] ?? 0} × ${CurrencyFormatter.format((item['unitPrice'] as num?)?.toDouble() ?? 0.0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Item Total
          Text(
            CurrencyFormatter.format(((item['quantity'] as int? ?? 0) * ((item['unitPrice'] as num?)?.toDouble() ?? 0.0))),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                TablerIconsHelper.location,
                color: const Color(0xFFFF6B35),
                size: Sizes.s20,
              ),
              const SizedBox(width: Sizes.s8),
              Text(
                'Delivery Address',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
          Text(
            order.deliveryAddress!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (order.deliveryNote != null && order.deliveryNote!.isNotEmpty) ...[
            const SizedBox(height: Sizes.s8),
            Text(
              'Extra details for rider: ${order.deliveryNote!}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', order.totalAmount),
          const Divider(),
          _buildPriceRow(
            'Total',
            order.totalAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final currentUser = DependencyInjection.instance.authController.currentUser;
    final canCancelByStatus = order.status == OrderStatus.created ||
        order.status == OrderStatus.sentToAdmin;
    // Customer can cancel only within 30 seconds of order creation
    final withinCancelWindow = order.createdAt != null &&
        DateTime.now().difference(order.createdAt!) <= const Duration(seconds: 30);
    final canCancel = canCancelByStatus && withinCancelWindow;
    final canTrack = order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled;
    // Check if order is delivered and user is the customer
    final isDelivered = order.status == OrderStatus.delivered &&
        currentUser?.id == order.customerId;
    // Check if order is delivered for call rider button
    final isDeliveredForCall = order.status == OrderStatus.delivered;

    return Column(
      children: [
        if (canTrack)
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.trackOrder,
                  arguments: order.id,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: Sizes.s8),
                  Text(
                    'Track Order',
                    style: AppTextStyles.buttonLargeBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (canTrack && canCancel) const SizedBox(height: Sizes.s12),
        if (canCancel && currentUser?.id == order.customerId)
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: OutlinedButton(
              onPressed: () => _handleCancelOrder(order),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
              ),
              child: Text(
                'Cancel Order',
                style: AppTextStyles.buttonLargeBold.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        // Only show Call Rider button if order is not delivered
        if (order.riderId != null && !isDeliveredForCall) ...[
          const SizedBox(height: Sizes.s12),
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: OutlinedButton.icon(
              onPressed: () => _callRider(order.riderId!),
              icon: const Icon(Icons.phone, color: Color(0xFFFF6B35)),
              label: Text(
                'Call Rider',
                style: AppTextStyles.buttonLargeBold.copyWith(
                  color: const Color(0xFFFF6B35),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
              ),
            ),
          ),
        ],
        // Check time restriction and existing reviews for reviews
        if (isDelivered)
          FutureBuilder<Map<String, bool>>(
            future: _checkReviewStatus(order),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink(); // Don't show anything while checking
              }

              final reviewStatus = snapshot.data ?? {};
              final canReviewByTime = reviewStatus['canReviewByTime'] ?? false;
              final hasRiderReview = reviewStatus['hasRiderReview'] ?? false;
              final hasProductReviews = reviewStatus['hasProductReviews'] ?? false;
              
              // Hide all review buttons if time expired or if customer already reviewed products
              if (!canReviewByTime || hasProductReviews) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  // Only show Rate Rider button if rider exists and hasn't been reviewed
                  if (order.riderId != null && !hasRiderReview) ...[
                    const SizedBox(height: Sizes.s12),
                    SizedBox(
                      width: double.infinity,
                      height: Sizes.s52,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRiderReviewDialog(order),
                        icon: const Icon(Icons.rate_review, color: Colors.white),
                        label: Text(
                          'Rate Rider',
                          style: AppTextStyles.buttonLargeBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                  // Only show Rate Products button if products haven't been reviewed
                  if (!hasProductReviews) ...[
                    const SizedBox(height: Sizes.s12),
                    SizedBox(
                      width: double.infinity,
                      height: Sizes.s52,
                      child: OutlinedButton.icon(
                        onPressed: () => _showProductReviewDialog(order),
                        icon: const Icon(Icons.fastfood_outlined, color: Color(0xFFFF6B35)),
                        label: Text(
                          'Rate Products',
                          style: AppTextStyles.buttonLargeBold.copyWith(
                            color: const Color(0xFFFF6B35),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF6B35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleCancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentUser = DependencyInjection.instance.authController.currentUser;
      if (currentUser == null) return;

      final success = await OrderService.cancelOrder(order.id, currentUser.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Order cancelled successfully'
                : 'Failed to cancel order'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  /// Check review status for an order
  /// Returns a map with:
  /// - 'canReviewByTime': bool - whether reviews can be submitted based on time window
  /// - 'hasRiderReview': bool - whether rider has been reviewed
  /// - 'hasProductReviews': bool - whether any products have been reviewed
  Future<Map<String, bool>> _checkReviewStatus(OrderModel order) async {
    final currentUser = DependencyInjection.instance.authController.currentUser;
    if (currentUser == null) {
      return {
        'canReviewByTime': false,
        'hasRiderReview': false,
        'hasProductReviews': false,
      };
    }

    // Check time restriction
    final canReviewByTime = await ReviewService.canReviewProduct(
      orderId: order.id,
    );

    // Check if rider has been reviewed
    bool hasRiderReview = false;
    if (order.riderId != null) {
      hasRiderReview = await ReviewService.hasRiderReview(
        customerId: currentUser.id!,
        orderId: order.id,
      );
    }

    // Check if any products have been reviewed
    bool hasProductReviews = false;
    for (final item in order.items) {
      final productId = item['productId'] as String? ?? '';
      if (productId.isNotEmpty) {
        final hasReview = await ReviewService.hasProductReview(
          productId: productId,
          customerId: currentUser.id!,
          orderId: order.id,
        );
        if (hasReview) {
          hasProductReviews = true;
          break; // If any product is reviewed, hide the buttons
        }
      }
    }

    return {
      'canReviewByTime': canReviewByTime,
      'hasRiderReview': hasRiderReview,
      'hasProductReviews': hasProductReviews,
    };
  }

  Future<void> _callRider(String riderId) async {
    try {
      // Fetch rider phone number from Firestore
      final riderDoc = await FirebaseService.firestore
          .collection('users')
          .doc(riderId)
          .get();

      if (!riderDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider information not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final riderData = riderDoc.data();
      final phoneNumber = riderData?['phoneNumber'] as String?;

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider phone number not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Make phone call
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calling rider: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRiderReviewDialog(OrderModel order) async {
    final currentUser = DependencyInjection.instance.authController.currentUser;
    if (currentUser == null || order.riderId == null) return;

    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate Rider'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStarsWidget(
                    rating: rating,
                    isInteractive: true,
                    onRatingSelected: (value) {
                      setState(() {
                        rating = value;
                      });
                    },
                  ),
                  const SizedBox(height: Sizes.s12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await ReviewService.createRiderReview(
          orderId: order.id,
          customerId: currentUser.id,
          riderId: order.riderId!,
          rating: rating,
          comment: commentController.text.trim().isEmpty
              ? null
              : commentController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for rating the rider!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _showProductReviewDialog(OrderModel order) async {
    final currentUser = DependencyInjection.instance.authController.currentUser;
    if (currentUser == null) return;

    final items = order.items;
    if (items.isEmpty) return;

    // Let user pick which product to review
    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select a product to review'),
          children: [
            for (int i = 0; i < items.length; i++)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, i),
                child: Text(items[i]['name'] as String? ?? 'Product'),
              ),
          ],
        );
      },
    );

    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= items.length) {
      return;
    }

    final item = items[selectedIndex];
    final productId = item['productId'] as String? ?? '';
    if (productId.isEmpty) return;

    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rate ${item['name'] as String? ?? 'Product'}'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStarsWidget(
                    rating: rating,
                    isInteractive: true,
                    onRatingSelected: (value) {
                      setState(() {
                        rating = value;
                      });
                    },
                  ),
                  const SizedBox(height: Sizes.s12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await ReviewService.createProductReview(
          productId: productId,
          customerId: currentUser.id,
          orderId: order.id,
          rating: rating,
          comment: commentController.text.trim().isEmpty
              ? null
              : commentController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for reviewing the product!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }
}
