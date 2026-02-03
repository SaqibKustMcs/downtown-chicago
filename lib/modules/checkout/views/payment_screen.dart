import 'package:flutter/material.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentScreen({super.key, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'mastercard';
  bool _hasMastercard = false; // Set to true if user has saved mastercard

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(id: 'cash', name: 'Cash', icon: TablerIconsHelper.shoppingBag),
    PaymentMethod(id: 'visa', name: 'Visa', icon: TablerIconsHelper.creditCard),
    PaymentMethod(id: 'mastercard', name: 'Mastercard', icon: TablerIconsHelper.creditCard),
    PaymentMethod(id: 'paypal', name: 'Pay', icon: TablerIconsHelper.creditCard),
  ];

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

                    const SizedBox(height: Sizes.s16),

                    // Add New Payment Method Button
                    _buildAddNewButton(),

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
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                TablerIconsHelper.arrowLeft,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Title
          Expanded(
            child: Text(
              'Payment',
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

  Widget _buildPaymentMethodSelection() {
    return SizedBox(
      height: Sizes.s120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          final isSelected = method.id == _selectedPaymentMethod;

          return AnimatedListItem(
            index: index,
            delay: const Duration(milliseconds: 50),
            child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method.id;
              });
            },
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
                      border: isSelected
                          ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: method.id == 'cash'
                              ? Icon(
                                  method.icon,
                                  size: Sizes.s40,
                                  color: const Color(0xFFFF6B35),
                                )
                              : method.id == 'visa'
                                  ? Container(
                                      padding: const EdgeInsets.all(Sizes.s8),
                                      child: const Text(
                                        'VISA',
                                        style: TextStyle(
                                          fontSize: Sizes.s20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
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
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: Sizes.s4),
                                              Container(
                                                width: Sizes.s20,
                                                height: Sizes.s20,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF6B35),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(Sizes.s8),
                                          child: const Text(
                                            'PayP',
                                            style: TextStyle(
                                              fontSize: Sizes.s16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
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
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                TablerIconsHelper.check,
                                size: Sizes.s12,
                                color: Colors.white,
                              ),
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
          );
        },
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
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              // Card Illustration
              Container(
                height: Sizes.s160,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
                child: Stack(
                  children: [
                    // Card Chip
                    Positioned(
                      left: Sizes.s16,
                      top: Sizes.s16,
                      child: Container(
                        width: Sizes.s40,
                        height: Sizes.s32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(Sizes.s4),
                        ),
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
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Sizes.s4),
                          Container(
                            width: Sizes.s32,
                            height: Sizes.s32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
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
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Sizes.s8),
              Text(
                'You can add a mastercard and save it for later',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
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
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              // Mastercard Icon
              Row(
                children: [
                  Container(
                    width: Sizes.s24,
                    height: Sizes.s24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Sizes.s4),
                  Container(
                    width: Sizes.s24,
                    height: Sizes.s24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s4),
                    Text(
                      '**** **** **** 436',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                TablerIconsHelper.arrowDown,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
            ],
          ),
        );
      }
    } else if (_selectedPaymentMethod == 'cash') {
      return Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        child: Row(
          children: [
            Icon(
              TablerIconsHelper.shoppingBag,
              color: const Color(0xFFFF6B35),
              size: Sizes.s32,
            ),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                'Pay with cash on delivery',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        child: Row(
          children: [
            Icon(
              TablerIconsHelper.creditCard,
              color: const Color(0xFFFF6B35),
              size: Sizes.s32,
            ),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                '${_paymentMethods.firstWhere((m) => m.id == _selectedPaymentMethod).name} payment method',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
        ),
        padding: const EdgeInsets.symmetric(vertical: Sizes.s16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            TablerIconsHelper.plus,
            color: Color(0xFFFF6B35),
            size: Sizes.s20,
          ),
          const SizedBox(width: Sizes.s8),
          Text(
            'ADD NEW',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFFFF6B35),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total
          Row(
            children: [
              Text(
                'TOTAL: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '\$${widget.totalAmount.toInt()}',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s16),

          // Pay & Confirm Button
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  Routes.paymentSuccess,
                  arguments: widget.totalAmount,
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
                'PAY & CONFIRM',
                style: AppTextStyles.buttonLargeBold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethod({required this.id, required this.name, required this.icon});
}
