import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/checkout/controllers/cart_controller.dart';
import 'package:food_flow_app/models/cart_item_model.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CartController _cartController;
  String _deliveryAddress = '2118 Thornridge Cir. Syracuse';

  @override
  void initState() {
    super.initState();
    _cartController = DependencyInjection.instance.cartController;
    _cartController.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartController.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() {});
  }

  double get _totalPrice => _cartController.totalPrice;

  void _updateQuantity(int index, int newQuantity) {
    _cartController.updateQuantity(index, newQuantity);
  }

  void _removeItem(String itemId) {
    _cartController.removeItem(itemId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            RepaintBoundary(
              child: _buildTopNavigation(context),
            ),

            // Cart Items List
            Expanded(
              child: RepaintBoundary(
                child: _cartController.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            TablerIconsHelper.shoppingCart,
                            size: Sizes.s80,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: Sizes.s24),
                          Text(
                            'Your cart is empty',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                      itemCount: _cartController.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartController.cartItems[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: _buildDismissibleBackground(),
                          onDismissed: (direction) {
                            _removeItem(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.name} removed from cart'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Theme.of(context).cardColor,
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: const Color(0xFFFF6B35),
                                  onPressed: () {
                                    _cartController.addToCart(item);
                                  },
                                ),
                              ),
                            );
                          },
                          child: AnimatedListItem(
                            index: index,
                            child: _buildCartItemCard(item, index),
                          ),
                        );
                      },
                    ),
              ),
            ),

            // Bottom Summary Panel
            if (!_cartController.isEmpty)
              RepaintBoundary(
                child: _buildBottomPanel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Text(
              'Cart',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Sizes.s20),
      child: Icon(
        TablerIconsHelper.trash,
        color: Colors.white,
        size: Sizes.s24,
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s16),
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: Sizes.s80,
              height: Sizes.s80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: Sizes.s80,
                height: Sizes.s80,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: Sizes.s80,
                height: Sizes.s80,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Sizes.s4),

                // Price
                Text(
                  '\$${item.price.toInt()}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Sizes.s4),

                // Size and Variations
                if (item.selectedVariation != null || item.selectedFlavor != null) ...[
                  if (item.selectedVariation != null)
                    Text(
                      'Size: ${item.selectedVariation}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  if (item.selectedVariation != null && item.selectedFlavor != null)
                    const SizedBox(height: Sizes.s2),
                  if (item.selectedFlavor != null)
                    Text(
                      'Flavor: ${item.selectedFlavor}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ] else
                  Text(
                    item.size,
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
              // Minus Button
              Container(
                width: Sizes.s32,
                height: Sizes.s32,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    TablerIconsHelper.minus,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: Sizes.s16,
                  ),
                  onPressed: () {
                    _updateQuantity(index, item.quantity - 1);
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: Sizes.s12),

              // Quantity
              Text(
                item.quantity.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: Sizes.s12),

              // Plus Button
              Container(
                width: Sizes.s32,
                height: Sizes.s32,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    TablerIconsHelper.plus,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: Sizes.s16,
                  ),
                  onPressed: () {
                    _updateQuantity(index, item.quantity + 1);
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Sizes.s24),
          topRight: Radius.circular(Sizes.s24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delivery Address Section
          Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DELIVERY ADDRESS',
                      style: AppTextStyles.label.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: Sizes.s12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to address selection
                      },
                      child: Text(
                        'EDIT',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sizes.s8),
                Container(
                  padding: const EdgeInsets.all(Sizes.s12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(Sizes.s8),
                  ),
                  child: Text(
                    _deliveryAddress,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),

          // Total Section
          Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'TOTAL: ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '\$${_totalPrice.toInt()}',
                      style: AppTextStyles.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Show breakdown
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Breakdown',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: Sizes.s4),
                      const Icon(
                        TablerIconsHelper.chevronRight,
                        color: Color(0xFFFF6B35),
                        size: Sizes.s16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Place Order Button
          Padding(
            padding: const EdgeInsets.fromLTRB(Sizes.s16, Sizes.s0, Sizes.s16, Sizes.s16),
            child: SizedBox(
              width: double.infinity,
              height: Sizes.s56,
              child: AnimatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.payment,
                    arguments: _totalPrice,
                  );
                },
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.payment,
                      arguments: _totalPrice,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.s12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'PLACE ORDER',
                    style: AppTextStyles.buttonLargeBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
