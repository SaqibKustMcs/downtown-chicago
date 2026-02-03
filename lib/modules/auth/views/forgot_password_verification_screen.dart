import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/auth/widgets/auth_header.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class ForgotPasswordVerificationScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<ForgotPasswordVerificationScreen> createState() => _ForgotPasswordVerificationScreenState();
}

class _ForgotPasswordVerificationScreenState extends State<ForgotPasswordVerificationScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  String get _verificationCode {
    return _codeController.text.trim();
  }

  Future<void> _handleVerification() async {
    if (_verificationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the reset code from your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_verificationCode.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete reset code from the email link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Navigate to update password screen with the code
      if (mounted) {
        Navigator.pushNamed(
          context,
          Routes.updatePassword,
          arguments: {
            'email': widget.email,
            'code': _verificationCode,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      final authController = DependencyInjection.instance.authController;
      final success = await authController.sendPasswordResetEmail(widget.email);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code resent to your email'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authController.error ?? 'Failed to resend code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFF2E2739), // Dark blue-grey
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            AuthHeader(
              title: 'Verification',
              subtitle: 'Enter the code sent to ${widget.email}',
              showBackButton: true,
            ),

            // Content Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Sizes.s32),
                    topRight: Radius.circular(Sizes.s32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sizes.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Sizes.s32),

                      // Instructions
                      Text(
                        'Enter Reset Code',
                        style: AppTextStyles.heading2.copyWith(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface
                              : CustomColors.textBoldColor,
                          fontSize: Sizes.s18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s8),
                      Text(
                        'We\'ve sent a password reset link to your email.\nPlease open the email and copy the code from the link.',
                        style: AppTextStyles.bodyLargeSecondary.copyWith(
                          fontSize: Sizes.s14,
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                              : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s16),
                      
                      // Instructions Box
                      Container(
                        padding: const EdgeInsets.all(Sizes.s16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.blue.shade900.withOpacity(0.3)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(Sizes.s12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: Sizes.s20,
                                ),
                                const SizedBox(width: Sizes.s8),
                                Text(
                                  'How to find the code:',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              '1. Open the password reset email\n'
                              '2. Click on the reset link\n'
                              '3. Copy the code from the URL (after "oobCode=")\n'
                              '4. Paste it below',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                                    : Colors.blue.shade900,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Code Input Field
                      Text(
                        'RESET CODE',
                        style: AppTextStyles.label.copyWith(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface
                              : CustomColors.textBoldColor,
                          fontSize: Sizes.s12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      CustomTextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        hintText: 'Paste the code from the email link here',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleVerification(),
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Resend Code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: _resendCode,
                            child: Text(
                              'Resend',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFFFF6B35),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s40),

                      // Verify Button
                      SizedBox(
                        height: Sizes.s56,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _handleVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Sizes.s12),
                            ),
                            elevation: 0,
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  height: Sizes.s20,
                                  width: Sizes.s20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'VERIFY',
                                  style: AppTextStyles.buttonLargeBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: Sizes.s32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
