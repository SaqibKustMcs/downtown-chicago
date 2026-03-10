import 'package:flutter/material.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class PaymentMethod {
  final String id;
  final String type;
  final String? cardNumber;
  final String? expiryDate;
  final String? cardHolderName;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.cardNumber,
    this.expiryDate,
    this.cardHolderName,
    this.isDefault = false,
  });
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<PaymentMethod> _paymentMethods = [
    const PaymentMethod(
      id: '1',
      type: 'Mastercard',
      cardNumber: '**** **** **** 1234',
      expiryDate: '12/25',
      cardHolderName: 'Cardholder Name',
      isDefault: true,
    ),
    const PaymentMethod(
      id: '2',
      type: 'Visa',
      cardNumber: '**** **** **** 5678',
      expiryDate: '06/26',
      cardHolderName: 'Cardholder Name',
      isDefault: false,
    ),
  ];

  void _setAsDefault(String id) {
    setState(() {
      _paymentMethods = _paymentMethods.map((method) {
        return PaymentMethod(
          id: method.id,
          type: method.type,
          cardNumber: method.cardNumber,
          expiryDate: method.expiryDate,
          cardHolderName: method.cardHolderName,
          isDefault: method.id == id,
        );
      }).toList();
    });
  }

  Future<void> _deletePaymentMethod(String id) async {
    // First confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        title: Text(
          'Delete Payment Method',
          style: AppTextStyles.heading3.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this payment method?',
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

    // Second confirmation dialog
    final finalConfirm = await showDialog<bool>(
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
                'Final Confirmation',
                style: AppTextStyles.heading3.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone. Are you absolutely sure you want to delete this payment method?',
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
              'Yes, Delete',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    if (mounted) {
      setState(() {
        _paymentMethods.removeWhere((method) => method.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment method removed',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(title: 'Payment Methods'),

            // Payment Methods List
            Expanded(
              child: _paymentMethods.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                      itemCount: _paymentMethods.length + 1, // +1 for Add New button
                      itemBuilder: (context, index) {
                        if (index == _paymentMethods.length) {
                          return AnimatedListItem(
                            index: index,
                            child: _buildAddNewButton(),
                          );
                        }
                        return AnimatedListItem(
                          index: index,
                          child: _buildPaymentMethodCard(_paymentMethods[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIconsHelper.creditCard,
            size: Sizes.s80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: Sizes.s24),
          Text(
            'No payment methods',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s8),
          Text(
            'Add a payment method to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: Sizes.s32),
          _buildAddNewButton(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: method.isDefault
              ? const Color(0xFFFF6B35)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: method.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: Sizes.s8,
            offset: const Offset(0, Sizes.s2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Card Icon
                Container(
                  width: Sizes.s48,
                  height: Sizes.s48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Sizes.s12),
                  ),
                  child: Icon(
                    TablerIconsHelper.creditCard,
                    color: const Color(0xFFFF6B35),
                    size: Sizes.s24,
                  ),
                ),
                const SizedBox(width: Sizes.s12),

                // Card Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.type,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (method.isDefault) ...[
                            const SizedBox(width: Sizes.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Sizes.s8,
                                vertical: Sizes.s4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Sizes.s4),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: AppTextStyles.captionTiny.copyWith(
                                  color: const Color(0xFFFF6B35),
                                  fontSize: Sizes.s10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Sizes.s4),
                      if (method.cardNumber != null)
                        Text(
                          _getLastFourDigits(method.cardNumber!),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: Icon(
                    TablerIconsHelper.menu,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onSelected: (value) async {
                    if (value == 'set_default') {
                      _setAsDefault(method.id);
                    } else if (value == 'delete') {
                      await _deletePaymentMethod(method.id);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!method.isDefault)
                      PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(
                              TablerIconsHelper.check,
                              size: Sizes.s16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: Sizes.s8),
                            Text(
                              'Set as default',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            TablerIconsHelper.trash,
                            size: Sizes.s16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: Sizes.s8),
                          Text(
                            'Delete',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s16),
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.addCard).then((value) {
            if (value == true) {
              // Card added successfully, refresh the list
              setState(() {
                _paymentMethods.add(
                  const PaymentMethod(
                    id: '3',
                    type: 'Mastercard',
                    cardNumber: '**** **** **** 9999',
                    expiryDate: '12/27',
                    cardHolderName: 'Cardholder Name',
                    isDefault: false,
                  ),
                );
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
            borderRadius: BorderRadius.circular(Sizes.s16),
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
              'ADD NEW PAYMENT METHOD',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract last 4 digits from card number
  String _getLastFourDigits(String cardNumber) {
    // Remove all spaces and asterisks, then get last 4 digits
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s*]'), '');
    if (cleaned.length >= 4) {
      final lastFour = cleaned.substring(cleaned.length - 4);
      return '**** **** **** $lastFour';
    }
    return cardNumber; // Return original if can't parse
  }
}
