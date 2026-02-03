import 'package:flutter/material.dart';
import 'package:food_flow_app/core/services/app_preferences_service.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class VerificationSuccessScreen extends StatelessWidget {
  final String email;

  const VerificationSuccessScreen({
    super.key,
    required this.email,
  });

  Future<void> _handleVerificationSuccess(BuildContext context) async {
    // Token is already saved in verification screen
    // Just navigate to main container
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.mainContainer,
        (route) => false,
      );
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: Sizes.s120,
                height: Sizes.s120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: Sizes.s80,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: Sizes.s32),

              // Success Title
              Text(
                'Verification Successful!',
                style: AppTextStyles.heading1.copyWith(
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurface
                      : CustomColors.textBoldColor,
                  fontSize: Sizes.s28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sizes.s16),

              // Success Message
              Text(
                'Your account has been successfully verified. You can now log in to your account.',
                style: AppTextStyles.bodyLargeSecondary.copyWith(
                  fontSize: Sizes.s14,
                  height: 1.5,
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sizes.s48),

              // Email Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sizes.s16,
                  vertical: Sizes.s12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: isDark
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                          : CustomColors.secondaryTextColor,
                      size: Sizes.s20,
                    ),
                    const SizedBox(width: Sizes.s8),
                    Text(
                      email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurface
                            : CustomColors.textBoldColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Sizes.s48),

              // Get Started Button (saves token and goes to main)
              SizedBox(
                width: double.infinity,
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: () => _handleVerificationSuccess(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.s12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'GET STARTED',
                    style: AppTextStyles.buttonLargeBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sizes.s16),
              // Login Link
              TextButton(
                onPressed: () => _navigateToLogin(context),
                child: Text(
                  'Already have an account? LOG IN',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFFFF6B35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
