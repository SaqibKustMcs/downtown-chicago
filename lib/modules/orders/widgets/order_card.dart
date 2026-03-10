import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/widgets/order_status_chip.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final bool showStatus;
  /// When true, show "Preparing" instead of "New Order" for created/sentToAdmin (e.g. customer ongoing tab).
  final bool showNewOrderAsPreparing;
  /// Optional label for the price (e.g. "Order + Delivery" for admin to show total amount received).
  final String? priceLabel;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showStatus = true,
    this.showNewOrderAsPreparing = false,
    this.priceLabel,
  });

  int get _totalItems {
    return order.items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
  }

  String? get _restaurantImageUrl {
    if (order.items.isEmpty) return null;
    return order.items.first['imageUrl'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        margin: const EdgeInsets.only(bottom: Sizes.s12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200, width: 1),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant/Item Image
                if (_restaurantImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Sizes.s12),
                    child: CachedNetworkImage(
                      imageUrl: _restaurantImageUrl!,
                      width: Sizes.s80,
                      height: Sizes.s80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: Sizes.s80,
                        height: Sizes.s80,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: Sizes.s80,
                        height: Sizes.s80,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  ),
                if (_restaurantImageUrl != null) const SizedBox(width: Sizes.s12),

                // Order Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name
                      Text(
                        order.restaurantName ?? 'Restaurant',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Sizes.s4),

                      // Order ID
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: Sizes.s12),

                      // Price (order + delivery = total admin receives) and Items
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.format(order.totalAmount),
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          if (priceLabel != null) ...[
                            const SizedBox(width: Sizes.s4),
                            Text(
                              priceLabel!,
                              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                          Container(
                            width: Sizes.s1,
                            height: Sizes.s16,
                            margin: const EdgeInsets.symmetric(horizontal: Sizes.s8),
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          Text('$_totalItems Items', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: Sizes.s4),
                        Text(dateFormat.format(order.createdAt!), style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      ],

                      if (showStatus)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: Sizes.s8),

                            OrderStatusChip(status: order.status, showNewOrderAsPreparing: showNewOrderAsPreparing),
                            if (order.hasRiderReview || order.hasProductReviews) ...[
                              const SizedBox(height: Sizes.s4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(Sizes.s12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: Sizes.s12, color: Color(0xFFFFA000)),
                                    const SizedBox(width: Sizes.s4),
                                    Text(
                                      'Reviewed',
                                      style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFFFA000), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),

                // Status Chip + Reviewed badge
              ],
            ),
          ],
        ),
      ),
    );
  }
}
