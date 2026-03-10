import 'package:flutter/material.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/checkout/controllers/cart_controller.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/location/services/address_service.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final OrderType orderType; // Added order type
  final String? deliveryAddress;
  final String? deliveryNote;
  final String? addressTitle;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    this.orderType = OrderType.delivery, // Default to delivery
    this.deliveryAddress,
    this.deliveryNote,
    this.addressTitle,
    this.latitude,
    this.longitude,
    this.phoneNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'cash'; // Default to cash since it's the only supported method
  bool _hasMastercard = false; // Set to true if user has saved mastercard
  bool _isPlacingOrder = false;
  late final CartController _cartController;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(id: 'cash', name: 'Cash', icon: TablerIconsHelper.shoppingBag),
    PaymentMethod(id: 'visa', name: 'Visa', icon: TablerIconsHelper.creditCard),
    PaymentMethod(id: 'mastercard', name: 'Mastercard', icon: TablerIconsHelper.creditCard),
    PaymentMethod(id: 'paypal', name: 'Pay', icon: TablerIconsHelper.creditCard),
  ];

  OrderType _orderType = OrderType.delivery; // Default to delivery

  @override
  void initState() {
    super.initState();
    _cartController = DependencyInjection.instance.cartController;
    // Use widget.orderType directly instead of reading from context
    _orderType = widget.orderType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            _buildTopNavigation(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Sizes.s16),

                    // Payment Method Selection
                    _buildPaymentMethodSelection(),

                    const SizedBox(height: Sizes.s24),

                    // Selected Payment Method Details
                    _buildSelectedPaymentMethodDetails(),

                    // Add New Payment Method Button (only show for card payment methods, not cash)
                    if (_selectedPaymentMethod != 'cash') ...[const SizedBox(height: Sizes.s16), _buildAddNewButton()],

                    const SizedBox(height: Sizes.s32),
                  ],
                ),
              ),
            ),

            // Bottom Total and Pay Button
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Back Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(TablerIconsHelper.arrowLeft, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Title
          Expanded(
            child: Text(
              'Payment',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return SizedBox(
      height: Sizes.s120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          final isSelected = method.id == _selectedPaymentMethod;
          final isEnabled = method.id == 'cash';

          return AnimatedListItem(
            index: index,
            delay: const Duration(milliseconds: 50),
            child: GestureDetector(
              onTap: () {
                if (isEnabled) {
                  setState(() {
                    _selectedPaymentMethod = method.id;
                  });
                } else {
                  _showComingSoonDialog();
                }
              },
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.5,
                child: Container(
                  width: Sizes.s100,
                  margin: EdgeInsets.only(right: index < _paymentMethods.length - 1 ? Sizes.s12 : 0),
                  child: Column(
                    children: [
                      // Payment Method Card
                      Container(
                        width: Sizes.s100,
                        height: Sizes.s80,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).cardColor
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(Sizes.s12),
                          border: isSelected ? Border.all(color: const Color(0xFFFF6B35), width: 2) : Border.all(color: Colors.transparent),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: method.id == 'cash'
                                  ? Icon(method.icon, size: Sizes.s40, color: const Color(0xFFFF6B35))
                                  : method.id == 'visa'
                                  ? Container(
                                      padding: const EdgeInsets.all(Sizes.s8),
                                      child: const Text(
                                        'VISA',
                                        style: TextStyle(fontSize: Sizes.s20, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    )
                                  : method.id == 'mastercard'
                                  ? Container(
                                      padding: const EdgeInsets.all(Sizes.s8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: Sizes.s20,
                                            height: Sizes.s20,
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: Sizes.s4),
                                          Container(
                                            width: Sizes.s20,
                                            height: Sizes.s20,
                                            decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(Sizes.s8),
                                      child: const Text(
                                        'PayP',
                                        style: TextStyle(fontSize: Sizes.s16, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ),
                            ),

                            // Selected Indicator
                            if (isSelected)
                              Positioned(
                                top: Sizes.s4,
                                right: Sizes.s4,
                                child: Container(
                                  width: Sizes.s20,
                                  height: Sizes.s20,
                                  decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                                  child: const Icon(TablerIconsHelper.check, size: Sizes.s12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),

                      // Payment Method Name
                      Text(
                        method.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming soon'),
        content: const Text(
          'This payment option will be available in a future update. Please use Cash on Delivery for now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPaymentMethodDetails() {
    if (_selectedPaymentMethod == 'mastercard') {
      if (!_hasMastercard) {
        // No mastercard added state
        return Container(
          padding: const EdgeInsets.all(Sizes.s24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Card Illustration
              Container(
                height: Sizes.s160,
                decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(Sizes.s12)),
                child: Stack(
                  children: [
                    // Card Chip
                    Positioned(
                      left: Sizes.s16,
                      top: Sizes.s16,
                      child: Container(
                        width: Sizes.s40,
                        height: Sizes.s32,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(Sizes.s4)),
                      ),
                    ),
                    // Card Pattern
                    Positioned(
                      right: Sizes.s16,
                      top: Sizes.s16,
                      child: Row(
                        children: [
                          Container(
                            width: Sizes.s32,
                            height: Sizes.s32,
                            decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: Sizes.s4),
                          Container(
                            width: Sizes.s32,
                            height: Sizes.s32,
                            decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sizes.s16),
              Text(
                'No master card added',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: Sizes.s8),
              Text(
                'You can add a mastercard and save it for later',
                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else {
        // Mastercard details
        return Container(
          padding: const EdgeInsets.all(Sizes.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Mastercard Icon
              Row(
                children: [
                  Container(
                    width: Sizes.s24,
                    height: Sizes.s24,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: Sizes.s4),
                  Container(
                    width: Sizes.s24,
                    height: Sizes.s24,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master Card',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: Sizes.s4),
                    Text('**** **** **** 436', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Icon(TablerIconsHelper.arrowDown, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
            ],
          ),
        );
      }
    } else if (_selectedPaymentMethod == 'cash') {
      return Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        child: Row(
          children: [
            Icon(TablerIconsHelper.shoppingBag, color: const Color(0xFFFF6B35), size: Sizes.s32),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                'Pay with cash on delivery',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    } else {
      // Other payment methods
      return Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        child: Row(
          children: [
            Icon(TablerIconsHelper.creditCard, color: const Color(0xFFFF6B35), size: Sizes.s32),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                '${_paymentMethods.firstWhere((m) => m.id == _selectedPaymentMethod).name} payment method',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAddNewButton() {
    return OutlinedButton(
      onPressed: () {
        Navigator.pushNamed(context, Routes.addCard).then((value) {
          if (value == true) {
            setState(() {
              _hasMastercard = true;
            });
          }
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
        padding: const EdgeInsets.symmetric(vertical: Sizes.s16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(TablerIconsHelper.plus, color: Color(0xFFFF6B35), size: Sizes.s20),
          const SizedBox(width: Sizes.s8),
          Text(
            'ADD NEW',
            style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final isTakeaway = _orderType == OrderType.takeaway;

    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price Breakdown
          Column(
            children: [
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  FutureBuilder<double>(
                    future: Future.value(_cartController.subtotal),
                    builder: (context, snapshot) {
                      final subtotal = snapshot.data ?? 0.0;
                      return Text(
                        CurrencyFormatter.format(subtotal),
                        style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s8),
              // Delivery Fee (only for delivery; takeaway = 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  FutureBuilder<double>(
                    future: isTakeaway
                        ? Future.value(0.0)
                        : _cartController.getDeliveryFee(customerLat: widget.latitude, customerLon: widget.longitude),
                    builder: (context, snapshot) {
                      final deliveryFee = snapshot.data ?? 0.0;
                      return Text(
                        CurrencyFormatter.formatWithFree(deliveryFee),
                        style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s12),
              // Divider
              Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
              const SizedBox(height: Sizes.s12),
              // Total (for takeaway use widget.totalAmount = subtotal; for delivery use computed total)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL',
                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  FutureBuilder<double>(
                    future: isTakeaway
                        ? Future.value(widget.totalAmount)
                        : _cartController.getTotalWithDeliveryFee(customerLat: widget.latitude, customerLon: widget.longitude),
                    builder: (context, snapshot) {
                      final total = snapshot.data ?? widget.totalAmount;
                      return Text(
                        CurrencyFormatter.format(total),
                        style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Sizes.s16),

          // Pay & Confirm Button
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _handlePayAndConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                elevation: 0,
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: Sizes.s20,
                      height: Sizes.s20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text('PAY & CONFIRM', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayAndConfirm() async {
    setState(() => _isPlacingOrder = true);

    try {
      final authController = DependencyInjection.instance.authController;
      final cartController = DependencyInjection.instance.cartController;

      final user = authController.currentUser;
      if (user == null) {
        throw Exception('Please login first');
      }

      if (_selectedPaymentMethod != 'cash') {
        throw Exception('Only Cash on Delivery is available right now');
      }

      // Use delivery note from screen args, or from default saved address (e.g. extra details from Select Address)
      String? deliveryNote = widget.deliveryNote;
      if (_orderType == OrderType.delivery && deliveryNote == null) {
        final defaultAddr = await AddressService.getDefaultAddress(user.id);
        deliveryNote = defaultAddr?.note;
      }

      final orderId = await OrderService.createCashOnDeliveryOrder(
        customer: user,
        cartItems: cartController.cartItems,
        totalAmount: widget.totalAmount,
        orderType: _orderType, // Use orderType from state (extracted from args or default)
        deliveryAddress: widget.deliveryAddress ?? user.address,
        deliveryNote: deliveryNote,
        addressTitle: widget.addressTitle,
        latitude: widget.latitude,
        longitude: widget.longitude,
        phoneNumber: widget.phoneNumber ?? user.phoneNumber,
      );

      cartController.clearCart();

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        Routes.paymentSuccess,
        arguments: {'orderId': orderId, 'totalAmount': widget.totalAmount},
      );

      debugPrint('Order created: $orderId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethod({required this.id, required this.name, required this.icon});
}
