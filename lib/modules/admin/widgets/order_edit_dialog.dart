import 'package:flutter/material.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OrderEditDialog extends StatefulWidget {
  final OrderModel order;

  const OrderEditDialog({
    super.key,
    required this.order,
  });

  @override
  State<OrderEditDialog> createState() => _OrderEditDialogState();
}

class _OrderEditDialogState extends State<OrderEditDialog> {
  late List<Map<String, dynamic>> _editedItems;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of items for editing
    _editedItems = widget.order.items.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _removeItem(int index) {
    setState(() {
      _editedItems.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }
    setState(() {
      _editedItems[index]['quantity'] = newQuantity;
    });
  }

  double _calculateNewTotal() {
    final subtotal = _editedItems.fold(0.0, (sum, item) {
      final quantity = (item['quantity'] as int? ?? 0);
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
      return sum + (quantity * unitPrice);
    });
    return subtotal + widget.order.deliveryFee;
  }

  double _calculateOriginalTotal() {
    return widget.order.totalAmount;
  }

  Future<void> _saveChanges() async {
    if (_editedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save order with no items. Please cancel the order instead.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final modificationNote = _noteController.text.trim().isEmpty
          ? 'Some items were unavailable and have been removed from your order.'
          : _noteController.text.trim();

      final success = await OrderService.updateOrderItems(
        orderId: widget.order.id,
        updatedItems: _editedItems,
        modificationNote: modificationNote,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalTotal = _calculateOriginalTotal();
    final newTotal = _calculateNewTotal();
    final difference = newTotal - originalTotal;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Sizes.s16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Sizes.s16),
                  topRight: Radius.circular(Sizes.s16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    TablerIconsHelper.edit,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: Sizes.s24,
                  ),
                  const SizedBox(width: Sizes.s12),
                  Expanded(
                    child: Text(
                      'Edit Order Items',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      TablerIconsHelper.x,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning
                    Container(
                      padding: const EdgeInsets.all(Sizes.s12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Sizes.s8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: Sizes.s20,
                          ),
                          const SizedBox(width: Sizes.s8),
                          Expanded(
                            child: Text(
                              'Remove unavailable items or adjust quantities. Customer will be notified.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sizes.s16),

                    // Items List
                    Text(
                      'Order Items',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s12),
                    ..._editedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildEditableItemCard(item, index);
                    }),

                    if (_editedItems.isEmpty) ...[
                      const SizedBox(height: Sizes.s16),
                      Center(
                        child: Text(
                          'No items remaining',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: Sizes.s16),

                    // Modification Note
                    Text(
                      'Note to Customer (Optional)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s8),
                    CustomTextField(
                      controller: _noteController,
                      hintText: 'e.g., Product unavailable, replaced with similar item',
                      maxLines: 3,
                    ),

                    const SizedBox(height: Sizes.s16),

                    // Price Summary
                    Container(
                      padding: const EdgeInsets.all(Sizes.s12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(Sizes.s8),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Original Total', originalTotal),
                          _buildPriceRow('New Total', newTotal, isNew: true),
                          if (difference != 0) ...[
                            const SizedBox(height: Sizes.s4),
                            Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                            const SizedBox(height: Sizes.s4),
                            _buildPriceRow(
                              'Difference',
                              difference,
                              isDifference: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(Sizes.s16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(Sizes.s16),
                  bottomRight: Radius.circular(Sizes.s16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Sizes.s12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: Sizes.s20,
                              height: Sizes.s20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: AppTextStyles.buttonLargeBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableItemCard(Map<String, dynamic> item, int index) {
    final quantity = item['quantity'] as int? ?? 0;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final itemTotal = quantity * unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Item Info
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
                if (item['selectedVariation'] != null || item['selectedFlavor'] != null) ...[
                  const SizedBox(height: Sizes.s4),
                  Text(
                    [
                      if (item['selectedVariation'] != null) item['selectedVariation'],
                      if (item['selectedFlavor'] != null) item['selectedFlavor'],
                    ].join(' • '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: Sizes.s4),
                Text(
                  '${CurrencyFormatter.format(unitPrice)} each',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Row(
            children: [
              IconButton(
                icon: Icon(
                  TablerIconsHelper.minus,
                  size: Sizes.s18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _updateQuantity(index, quantity - 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                child: Text(
                  quantity.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  TablerIconsHelper.plus,
                  size: Sizes.s18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _updateQuantity(index, quantity + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(width: Sizes.s8),

          // Item Total
          Text(
            CurrencyFormatter.format(itemTotal),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(width: Sizes.s8),

          // Remove Button
          IconButton(
            icon: Icon(
              TablerIconsHelper.trash,
              color: Colors.red,
              size: Sizes.s20,
            ),
            onPressed: () => _removeItem(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isNew = false, bool isDifference = false}) {
    final isPositive = amount >= 0;
    final color = isDifference
        ? (isPositive ? Colors.green : Colors.red)
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isNew ? FontWeight.w600 : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        Text(
          isDifference && isPositive ? '+${CurrencyFormatter.format(amount)}' : CurrencyFormatter.format(amount),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
