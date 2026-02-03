import 'package:flutter/material.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double totalAmount;

  const PaymentSuccessScreen({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Illustration
              AnimatedCard(
                delay: const Duration(milliseconds: 100),
                child: _buildSuccessIllustration(),
              ),

              const SizedBox(height: Sizes.s32),

              // Congratulations Text
              AnimatedListItem(
                index: 0,
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Congratulations!',
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: Sizes.s16),

              // Success Message
              AnimatedListItem(
                index: 1,
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.s32),
                  child: Text(
                    'You successfully made a payment, enjoy our service!',
                    style: AppTextStyles.bodyLargeSecondary.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: Sizes.s48),

              // Track Order Button
              AnimatedListItem(
                index: 2,
                delay: const Duration(milliseconds: 400),
                child: AnimatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.mainContainer,
                      (route) => false,
                    );
                    // Navigate to orders tab
                    // You might need to pass a parameter to open orders tab
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: Sizes.s56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.mainContainer,
                          (route) => false,
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
                        'TRACK ORDER',
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
        ),
      ),
    );
  }

  Widget _buildSuccessIllustration() {
    return Container(
      width: Sizes.s200,
      height: Sizes.s200,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wallet
          Positioned(
            bottom: Sizes.s20,
            child: Container(
              width: Sizes.s120,
              height: Sizes.s80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(Sizes.s12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: Sizes.s20,
                    offset: const Offset(0, Sizes.s10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Card Chip
                  Positioned(
                    left: Sizes.s12,
                    top: Sizes.s12,
                    child: Container(
                      width: Sizes.s24,
                      height: Sizes.s20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(Sizes.s4),
                      ),
                    ),
                  ),
                  // Coins
                  Positioned(
                    right: Sizes.s8,
                    top: Sizes.s8,
                    child: Row(
                      children: [
                        Container(
                          width: Sizes.s20,
                          height: Sizes.s20,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.shade700.withOpacity(0.5),
                                blurRadius: Sizes.s8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Sizes.s12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Sizes.s4),
                        Container(
                          width: Sizes.s20,
                          height: Sizes.s20,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.shade700.withOpacity(0.5),
                                blurRadius: Sizes.s8,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Sizes.s12,
                                fontWeight: FontWeight.bold,
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
          ),

          // Confetti/Streamers
          ...List.generate(8, (index) {
            final distance = Sizes.s60;
            return Positioned(
              left: Sizes.s100 + distance * (index % 2 == 0 ? 1 : -1) * (index % 4 < 2 ? 1 : -1),
              top: Sizes.s100 + distance * (index % 2 == 0 ? -1 : 1) * (index % 4 < 2 ? 1 : -1),
              child: Container(
                width: Sizes.s8,
                height: Sizes.s8,
                decoration: BoxDecoration(
                  color: [
                    Colors.pink,
                    Colors.purple,
                    Colors.yellow,
                    Colors.blue,
                  ][index % 4],
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),

          // Credit Card
          Positioned(
            top: Sizes.s20,
            child: Container(
              width: Sizes.s80,
              height: Sizes.s50,
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(Sizes.s8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade600.withOpacity(0.3),
                    blurRadius: Sizes.s12,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  TablerIconsHelper.creditCard,
                  color: Colors.white,
                  size: Sizes.s32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
