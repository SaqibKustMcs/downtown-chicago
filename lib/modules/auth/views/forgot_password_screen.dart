import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/auth/widgets/auth_header.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authController = DependencyInjection.instance.authController;
        
        // Send password reset email
        final success = await authController.sendPasswordResetEmail(
          _emailController.text.trim(),
        );

        if (success && mounted) {
          // Show success message and navigate to verification screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent. Please check your inbox.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to verification screen
          Navigator.pushNamed(
            context,
            Routes.forgotPasswordVerification,
            arguments: _emailController.text.trim(),
          );
        } else if (mounted) {
          // Show error message
          final errorMsg = authController.error ?? 'Failed to send reset email. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Failed to send reset email. Please try again.';
        
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your internet connection and try again.';
            break;
          case 'user-not-found':
            errorMessage = 'No account found with this email. Please check your email address.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address. Please enter a valid email.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          default:
            errorMessage = e.message ?? 'Failed to send reset email. Please try again.';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
              title: 'Forgot Password',
              subtitle: 'Enter your email to receive reset code',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Sizes.s32),

                        // Instructions
                        Text(
                          'Reset Password',
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
                          'We\'ll send you a verification code to reset your password',
                          style: AppTextStyles.bodyLargeSecondary.copyWith(
                            fontSize: Sizes.s14,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sizes.s40),

                        // Email Field
                        Text(
                          'EMAIL',
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
                          controller: _emailController,
                          hintText: 'example@gmail.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Sizes.s32),

                        // Send Reset Code Button
                        SizedBox(
                          height: Sizes.s56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendResetCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Sizes.s12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: Sizes.s20,
                                    width: Sizes.s20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'SEND RESET CODE',
                                    style: AppTextStyles.buttonLargeBold.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Back to Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Remember your password? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                    : CustomColors.secondaryTextColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'LOG IN',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: const Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sizes.s32),
                      ],
                    ),
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
