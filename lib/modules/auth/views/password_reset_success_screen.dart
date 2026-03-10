import 'package:flutter/material.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

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
                  Icons.lock_reset,
                  size: Sizes.s80,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: Sizes.s32),

              // Success Title
              Text(
                'Password Reset Successful!',
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
                'Your password has been successfully reset. You can now log in with your new password.',
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

              // Login Button
              SizedBox(
                width: double.infinity,
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: () => _navigateToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.s12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'LOG IN',
                    style: AppTextStyles.buttonLargeBold.copyWith(
                      color: Colors.white,
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
}
