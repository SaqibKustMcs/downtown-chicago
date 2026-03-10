import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/checkout/controllers/cart_controller.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/modules/location/services/address_service.dart';
import 'package:downtown/modules/location/models/address_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/models/cart_item_model.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:get/get.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CartController _cartController;
  String? _deliveryAddress;
  OrderType _orderType = OrderType.delivery; // Default to delivery
  final _authController = DependencyInjection.instance.authController;

  @override
  void initState() {
    super.initState();
    _cartController = DependencyInjection.instance.cartController;
    _cartController.addListener(_onCartChanged);
    // Load user's current address
    _loadUserAddress();
    // Check if user is admin and default to takeaway
    _checkUserType();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _checkUserType() {
    final currentUser = _authController.currentUser;
    if (currentUser != null && currentUser.userType == UserType.admin) {
      setState(() {
        _orderType = OrderType.takeaway; // Default to takeaway for admin
      });
    }
  }

  void _loadUserAddress() {
    final currentUser = DependencyInjection.instance.authController.currentUser;
    setState(() {
      // Only set default if user has no address, otherwise use user's address
      if (currentUser?.address != null && currentUser!.address!.isNotEmpty) {
        _deliveryAddress = currentUser.address;
      } else {
        _deliveryAddress = null; // Will show placeholder text
      }
    });
  }

  @override
  void dispose() {
    _cartController.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() {});
  }

  double get _subtotal => _cartController.subtotal;

  Future<void> _handlePlaceOrder(BuildContext context, bool isNewUser, double total) async {
    // Check if restaurant is currently open
    if (_cartController.cartItems.isNotEmpty) {
      final restaurantId = _cartController.cartItems.first.restaurantId;
      if (restaurantId != null) {
        try {
          final restaurantDoc = await FirebaseService.firestore
              .collection('restaurants')
              .doc(restaurantId)
              .get();

          if (restaurantDoc.exists) {
            final restaurant = Restaurant.fromFirestore(
              restaurantDoc.data() as Map<String, dynamic>,
              restaurantDoc.id,
            );

            if (!restaurant.isCurrentlyOpen) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'This restaurant is currently closed. Opening hours: ${restaurant.formattedOpeningHours ?? "N/A"}',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
          }
        } catch (e) {
          debugPrint('Error checking restaurant status: $e');
        }
      }
    }

    // For takeaway orders, skip address confirmation and go directly to payment
    if (_orderType == OrderType.takeaway) {
      Navigator.pushNamed(
        context,
        Routes.payment,
        arguments: {'total': total, 'orderType': _orderType},
      );
    } else if (isNewUser) {
      // Navigate to delivery address confirmation screen
      Navigator.pushNamed(
        context,
        Routes.deliveryAddressConfirmation,
        arguments: {'total': total, 'initialAddress': _deliveryAddress},
      );
    } else {
      // Navigate directly to payment screen; include default address note (extra details for rider) so it shows on order
      final addressToPass =
          (_deliveryAddress != null &&
              _deliveryAddress!.isNotEmpty &&
              _deliveryAddress != 'Tap to set delivery address')
          ? _deliveryAddress
          : null;

      final currentUser = _authController.currentUser;
      String? deliveryNote;
      if (currentUser != null && addressToPass != null) {
        final defaultAddr = await AddressService.getDefaultAddress(currentUser.id);
        deliveryNote = defaultAddr?.note;
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        Routes.payment,
        arguments: {
          'total': total,
          'deliveryAddress': addressToPass,
          'orderType': _orderType,
          if (deliveryNote != null && deliveryNote.isNotEmpty) 'deliveryNote': deliveryNote,
        },
      );
    }
  }

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
            RepaintBoundary(child: _buildTopNavigation(context)),

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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: Sizes.s24),
                            Text(
                              'Your cart is empty',
                              style: AppTextStyles.heading2.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              'Add items to your cart to get started',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sizes.s12,
                          vertical: Sizes.s16,
                        ),
                        itemCount: _cartController.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartController.cartItems[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: _buildDismissibleBackground(),
                            onDismissed: (direction) {
                              _removeItem(item.id);
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('${item.name} removed from cart'),
                              //     duration: const Duration(seconds: 2),
                              //     backgroundColor: Theme.of(context).cardColor,
                              //     behavior: SnackBarBehavior.floating,
                              //     action: SnackBarAction(
                              //       label: 'UNDO',
                              //       textColor: const Color(0xFFFF6B35),
                              //       onPressed: () {
                              //         _cartController.addToCart(item);
                              //       },
                              //     ),
                              //   ),
                              // );
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
            if (!_cartController.isEmpty) RepaintBoundary(child: _buildBottomPanel()),
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
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(Sizes.s16)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Sizes.s20),
      child: Icon(TablerIconsHelper.trash, color: Colors.white, size: Sizes.s24),
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
                  CurrencyFormatter.formatInt(item.price),
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
    final maxHeight = MediaQuery.of(context).size.height * 0.48;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minHeight: MediaQuery.of(context).size.height * 0.1,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Sizes.s20),
            topRight: Radius.circular(Sizes.s20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: Sizes.s8),
              children: [
                // Saved Addresses Section (if user has saved addresses) - Only show for delivery orders
                // if (_orderType == OrderType.delivery)
                //   StreamBuilder<List<AddressModel>>(
                //     stream: _authController.currentUser != null ? AddressService.getUserAddresses(_authController.currentUser!.id!) : Stream<List<AddressModel>>.value([]),
                //     builder: (context, snapshot) {
                //       if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                //         final savedAddresses = snapshot.data!;
                //         return Padding(
                //           padding: const EdgeInsets.fromLTRB(Sizes.s12, Sizes.s10, Sizes.s12, Sizes.s4),
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Text(
                //                 'SAVED ADDRESSES',
                //                 style: AppTextStyles.label.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: Sizes.s10, fontWeight: FontWeight.w600),
                //               ),
                //               const SizedBox(height: Sizes.s4),
                //               SizedBox(
                //                 height: Sizes.s48,
                //                 child: ListView.builder(
                //                   scrollDirection: Axis.horizontal,
                //                   itemCount: savedAddresses.length,
                //                   itemBuilder: (context, index) {
                //                     final address = savedAddresses[index];
                //                     final isSelected = _deliveryAddress == address.address;
                //                     return GestureDetector(
                //                       onTap: () {
                //                         setState(() {
                //                           _deliveryAddress = address.address;
                //                         });
                //                       },
                //                       child: Container(
                //                         width: Sizes.s160,
                //                         margin: EdgeInsets.only(right: index < savedAddresses.length - 1 ? Sizes.s6 : 0),
                //                         padding: const EdgeInsets.all(Sizes.s6),
                //                         decoration: BoxDecoration(
                //                           color: isSelected
                //                               ? const Color(0xFFFF6B35).withOpacity(0.1)
                //                               : Theme.of(context).brightness == Brightness.dark
                //                               ? Colors.grey.shade800
                //                               : Colors.grey.shade100,
                //                           borderRadius: BorderRadius.circular(Sizes.s8),
                //                           border: Border.all(
                //                             color: isSelected
                //                                 ? const Color(0xFFFF6B35)
                //                                 : Theme.of(context).brightness == Brightness.dark
                //                                 ? Colors.grey.shade700
                //                                 : Colors.grey.shade300,
                //                             width: isSelected ? 2 : 1,
                //                           ),
                //                         ),
                //                         child: Column(
                //                           crossAxisAlignment: CrossAxisAlignment.start,
                //                           mainAxisAlignment: MainAxisAlignment.center,
                //                           children: [
                //                             if (address.label != null && address.label!.isNotEmpty)
                //                               Row(
                //                                 children: [
                //                                   Icon(
                //                                     TablerIconsHelper.location,
                //                                     size: Sizes.s12, // Reduced icon size
                //                                     color: isSelected ? const Color(0xFFFF6B35) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                //                                   ),
                //                                   const SizedBox(width: Sizes.s4),
                //                                   Expanded(
                //                                     child: Text(
                //                                       address.label!,
                //                                       style: AppTextStyles.bodySmall.copyWith(
                //                                         color: isSelected ? const Color(0xFFFF6B35) : Theme.of(context).colorScheme.onSurface,
                //                                         fontWeight: FontWeight.w600,
                //                                         fontSize: Sizes.s10, // Smaller font
                //                                       ),
                //                                       maxLines: 1,
                //                                       overflow: TextOverflow.ellipsis,
                //                                     ),
                //                                   ),
                //                                 ],
                //                               ),
                //                             if (address.label != null && address.label!.isNotEmpty) const SizedBox(height: Sizes.s2),
                //                             Text(
                //                               address.address,
                //                               style: AppTextStyles.bodySmall.copyWith(
                //                                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                //                                 fontSize: Sizes.s10, // Smaller font
                //                               ),
                //                               maxLines: 1, // Reduced from 2 to 1
                //                               overflow: TextOverflow.ellipsis,
                //                             ),
                //                           ],
                //                         ),
                //                       ),
                //                     );
                //                   },
                //                 ),
                //               ),
                //             ],
                //           ),
                //         );
                //       }
                //       return const SizedBox.shrink();
                //     },
                //   ),

                // Order Type Selection
                Padding(
                  padding: const EdgeInsets.fromLTRB(Sizes.s12, Sizes.s10, Sizes.s12, Sizes.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER TYPE',
                        style: AppTextStyles.label.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: Sizes.s10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOrderTypeOption(
                              context,
                              OrderType.delivery,
                              'Delivery',
                              TablerIconsHelper.truck,
                            ),
                          ),
                          const SizedBox(width: Sizes.s8),
                          Expanded(
                            child: _buildOrderTypeOption(
                              context,
                              OrderType.takeaway,
                              'Takeaway',
                              TablerIconsHelper.shoppingBag,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delivery Address Section (only for delivery orders)
                if (_orderType == OrderType.delivery)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DELIVERY ADDRESS',
                              style: AppTextStyles.label.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: Sizes.s10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Navigator.pushNamed(context, Routes.addressSelection);
                                if (mounted) {
                                  await _authController.refreshUser();
                                  _loadUserAddress();
                                }
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
                        const SizedBox(height: Sizes.s4),
                        Container(
                          padding: const EdgeInsets.all(Sizes.s8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(Sizes.s8),
                          ),
                          child: Text(
                            _deliveryAddress ?? 'Tap to set delivery address',
                            style: AppTextStyles.bodySmall.copyWith(
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

                // Price Breakdown Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s8),
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(_subtotal),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s4),
                      // Delivery Fee (distance-based: restaurant → customer × price per KM)
                      if (_orderType == OrderType.delivery)
                        FutureBuilder<double>(
                          future: _cartController.getDeliveryFee(
                            customerLat: _authController.currentUser?.userLatLng?['latitude'],
                            customerLon: _authController.currentUser?.userLatLng?['longitude'],
                          ),
                          builder: (context, snapshot) {
                            final deliveryFee = snapshot.data ?? 0.0;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Fee',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatWithFree(deliveryFee),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: Sizes.s6),
                      Divider(
                        height: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                      ),
                      const SizedBox(height: Sizes.s6),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          FutureBuilder<double>(
                            future: _orderType == OrderType.takeaway
                                ? Future.value(_subtotal) // No delivery fee for takeaway
                                : _cartController.getTotalWithDeliveryFee(
                                    customerLat:
                                        _authController.currentUser?.userLatLng?['latitude'],
                                    customerLon:
                                        _authController.currentUser?.userLatLng?['longitude'],
                                  ),
                            builder: (context, snapshot) {
                              final total = snapshot.data ?? _subtotal;
                              return Text(
                                CurrencyFormatter.format(total),
                                style: AppTextStyles.heading2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Place Order button (fixed at bottom so always visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sizes.s12, Sizes.s4, Sizes.s12, Sizes.s12),
              child: SizedBox(
                width: double.infinity,
                height: Sizes.s48,
                child: FutureBuilder<double>(
                  future: _orderType == OrderType.takeaway
                      ? Future.value(_subtotal) // No delivery fee for takeaway
                      : _cartController.getTotalWithDeliveryFee(
                          customerLat: _authController.currentUser?.userLatLng?['latitude'],
                          customerLon: _authController.currentUser?.userLatLng?['longitude'],
                        ),
                  builder: (context, snapshot) {
                    final total = snapshot.data ?? _subtotal;
                    final currentUser = DependencyInjection.instance.authController.currentUser;

                    // For takeaway orders, skip new user check (no address/phone needed)
                    // For delivery orders, check if address is missing or user is new
                    final hasAddress = _orderType == OrderType.delivery
                        ? (_deliveryAddress != null &&
                              _deliveryAddress!.isNotEmpty &&
                              _deliveryAddress != 'Tap to set delivery address')
                        : true; // Takeaway doesn't need address

                    final isNewUser =
                        _orderType == OrderType.delivery &&
                        ((currentUser?.address == null || currentUser!.address!.isEmpty) ||
                            (currentUser.phoneNumber == null || currentUser.phoneNumber!.isEmpty));

                    final needsAddress = _orderType == OrderType.delivery && !hasAddress;

                    return AnimatedButton(
                      onPressed: needsAddress
                          ? null
                          : () => _handlePlaceOrder(context, isNewUser || needsAddress, total),
                      child: ElevatedButton(
                        onPressed: needsAddress
                            ? null
                            : () => _handlePlaceOrder(context, isNewUser || needsAddress, total),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: needsAddress
                              ? const Color(0xFFFF6B35).withOpacity(0.5)
                              : const Color(0xFFFF6B35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _orderType == OrderType.takeaway
                              ? 'PLACE TAKEAWAY ORDER'
                              : needsAddress
                              ? 'SELECT DELIVERY ADDRESS'
                              : (isNewUser ? 'CONFIRM PAYMENT AND ADDRESS' : 'PLACE ORDER'),
                          style: AppTextStyles.buttonLargeBold.copyWith(
                            color: Colors.white,
                            fontSize: Sizes.s14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeOption(BuildContext context, OrderType type, String label, IconData icon) {
    final isSelected = _orderType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _orderType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Sizes.s8, horizontal: Sizes.s12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.1)
              : Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(Sizes.s8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B35)
                : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Sizes.s18,
              color: isSelected
                  ? const Color(0xFFFF6B35)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: Sizes.s6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressEditDialog() {
    final addressController = TextEditingController(text: _deliveryAddress);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s16)),
        title: Text(
          'Edit Delivery Address',
          style: AppTextStyles.heading3.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: CustomTextField(
          controller: addressController,
          hintText: 'Enter delivery address',
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (addressController.text.trim().isNotEmpty) {
                setState(() {
                  _deliveryAddress = addressController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
