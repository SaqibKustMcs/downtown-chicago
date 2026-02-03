import 'package:flutter/material.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundColor,
      appBar: AppBar(
        title: Text('Checkout', style: AppTextStyles.appBarTitle),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(TablerIconsHelper.shoppingCart, size: Sizes.s80, color: CustomColors.secondaryTextColor),
              const SizedBox(height: Sizes.s24),
              Text('Your Cart is Empty', style: AppTextStyles.heading2),
              const SizedBox(height: Sizes.s8),
              Text('Add items to your cart to checkout', style: AppTextStyles.bodyLargeSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
