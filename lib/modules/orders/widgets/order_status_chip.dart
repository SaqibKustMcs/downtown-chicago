import 'package:flutter/material.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  /// When true (e.g. customer ongoing tab), show "Preparing" for created/sentToAdmin instead of "New Order".
  final bool showNewOrderAsPreparing;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.showNewOrderAsPreparing = false,
  });

  String get _statusText {
    switch (status) {
      case OrderStatus.created:
        return showNewOrderAsPreparing ? 'Preparing' : 'New Order';
      case OrderStatus.sentToAdmin:
        return showNewOrderAsPreparing ? 'Preparing' : 'Sent to Admin';
      case OrderStatus.assignedToRider:
        return 'Assigned to Rider';
      case OrderStatus.acceptedByRider:
        return 'Accepted by Rider';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.nearAddress:
        return 'Near Your Address';
      case OrderStatus.atLocation:
        return 'At Location';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get _statusColor {
    switch (status) {
      case OrderStatus.created:
      case OrderStatus.sentToAdmin:
        return Colors.blue;
      case OrderStatus.assignedToRider:
      case OrderStatus.acceptedByRider:
        return Colors.orange;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
      case OrderStatus.nearAddress:
      case OrderStatus.atLocation:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.s12,
        vertical: Sizes.s6,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Sizes.s8,
            height: Sizes.s8,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Sizes.s6),
          Text(
            _statusText,
            style: AppTextStyles.bodySmall.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
