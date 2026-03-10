import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/services/password_reset_code_service.dart';
import 'package:downtown/modules/auth/widgets/auth_header.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class ForgotPasswordVerificationScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordVerificationScreen({super.key, required this.email});

  @override
  State<ForgotPasswordVerificationScreen> createState() => _ForgotPasswordVerificationScreenState();
}

class _ForgotPasswordVerificationScreenState extends State<ForgotPasswordVerificationScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the code input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  String get _verificationCode {
    return _codeController.text.trim().replaceAll(' ', '');
  }

  /// Format code input to show 6 digits with spaces (e.g., "123 456")
  void _formatCodeInput(String value) {
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 6 digits
    final limitedDigits = digitsOnly.length > 6 ? digitsOnly.substring(0, 6) : digitsOnly;

    // Format with space after 3 digits
    String formatted = '';
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += ' ';
      }
      formatted += limitedDigits[i];
    }

    if (_codeController.text != formatted) {
      _codeController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _handleVerification() async {
    final code = _verificationCode;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the 6-digit code sent to your email'), backgroundColor: Colors.red));
      return;
    }

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the complete 6-digit code'), backgroundColor: Colors.red));
      return;
    }

    // Validate that code contains only digits
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code must contain only numbers'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify the 6-digit code and get Firebase action code
      final firebaseActionCode = await PasswordResetCodeService.instance.verifyCode(widget.email, code);

      if (firebaseActionCode == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid or expired code. Please request a new code.'), backgroundColor: Colors.red, duration: Duration(seconds: 4)));
        }
        return;
      }

      // Navigate to update password screen with the Firebase action code
      if (mounted) {
        Navigator.pushNamed(
          context,
          Routes.updatePassword,
          arguments: {
            'email': widget.email,
            'code': firebaseActionCode, // Use Firebase action code
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred. Please try again.'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
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
          // Generate new 6-digit code
          try {
            await PasswordResetCodeService.instance.generateAndStoreCode(
              widget.email,
              'temp_action_code', // Should be replaced with actual Firebase action code
            );
          } catch (e) {
            debugPrint('Error generating reset code: $e');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A new 6-digit verification code has been sent to your email'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authController.error ?? 'Failed to resend code. Please try again.'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('An error occurred. Please try again.'), backgroundColor: Colors.red, duration: Duration(seconds: 4)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFF2E2739), // Dark blue-grey
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            AuthHeader(title: 'Verification', subtitle: 'Please enter the code sent to your provided email', showBackButton: true),

            // Content Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s32), topRight: Radius.circular(Sizes.s32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sizes.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Sizes.s32),

                      // Instructions
                      Text(
                        'Enter Verification Code',
                        style: AppTextStyles.heading2.copyWith(color: isDark ? Theme.of(context).colorScheme.onSurface : CustomColors.textBoldColor, fontSize: Sizes.s18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s8),
                      Text(
                        'We\'ve sent a 6-digit verification code to your email.\nPlease check your inbox and enter the code below.',
                        style: AppTextStyles.bodyLargeSecondary.copyWith(fontSize: Sizes.s14, color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : null),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s24),

                      // Code Input Field
                      Text(
                        'VERIFICATION CODE',
                        style: AppTextStyles.label.copyWith(
                          color: isDark ? Theme.of(context).colorScheme.onSurface : CustomColors.textBoldColor,
                          fontSize: Sizes.s12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      CustomTextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        hintText: 'Enter 6-digit code',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onChanged: _formatCodeInput,
                        onSubmitted: (_) => _handleVerification(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the 6-digit code';
                          }
                          final code = value.replaceAll(' ', '');
                          if (code.length != 6) {
                            return 'Code must be 6 digits';
                          }
                          if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
                            return 'Code must contain only numbers';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Resend Code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : CustomColors.secondaryTextColor),
                          ),
                          GestureDetector(
                            onTap: _resendCode,
                            child: Text(
                              'Resend',
                              style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s40),

                      // Verify Button
                      // SizedBox(
                      //   height: Sizes.s56,
                      //   child: ElevatedButton(
                      //     onPressed: _isVerifying ? null : _handleVerification,
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: const Color(0xFFFF6B35),
                      //       disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(Sizes.s12),
                      //       ),
                      //       elevation: 0,
                      //     ),
                      //     child: _isVerifying
                      //         ? const SizedBox(
                      //             height: Sizes.s20,
                      //             width: Sizes.s20,
                      //             child: CircularProgressIndicator(
                      //               strokeWidth: 2,
                      //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      //             ),
                      //           )
                      //         : Text(
                      //             'VERIFY',
                      //             style: AppTextStyles.buttonLargeBold.copyWith(
                      //               color: Colors.white,
                      //             ),
                      //           ),
                      //   ),
                      // ),
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
