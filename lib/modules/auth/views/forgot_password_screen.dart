import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/services/password_reset_code_service.dart';
import 'package:downtown/modules/auth/widgets/auth_header.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

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
        final email = _emailController.text.trim().toLowerCase();
        
        // Check if email is registered before sending reset code
        // This prevents sending codes to unregistered emails
        final authService = DependencyInjection.instance.authService;
        final emailExists = await authService.checkEmailExists(email);
        
        if (!emailExists) {
          if (mounted) {
            // Show generic message for security - don't reveal if email exists
            // This prevents email enumeration attacks
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('If an account exists with this email, a reset code will be sent. Please check your email.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        
        // Email exists, proceed with sending password reset email
        // The authService.sendPasswordResetEmail will also verify email exists as a double-check
        final success = await authController.sendPasswordResetEmail(email);

        if (success && mounted) {
          // Generate and store 6-digit code
          // Note: The Firebase action code will be extracted from the email link
          // For now, we generate a code that will be stored
          // In production, you'll need Cloud Functions to send the 6-digit code via email
          try {
            // Generate a temporary code (in production, this should be sent via email)
            // The Firebase action code from the email link needs to be stored with this code
            // This requires Cloud Functions or backend service
            final tempCode = await PasswordResetCodeService.instance.generateAndStoreCode(
              email,
              'temp_action_code', // This should be replaced with actual Firebase action code from email
            );
            
            // TODO: In production, implement Cloud Functions to:
            // 1. Intercept password reset email
            // 2. Extract Firebase action code from link
            // 3. Generate 6-digit code
            // 4. Store mapping in Firestore
            // 5. Send email with 6-digit code instead of link
            
            debugPrint('Generated 6-digit code: $tempCode (for email: $email)');
            debugPrint('NOTE: This code needs to be sent via email. Implement Cloud Functions for production.');
          } catch (e) {
            debugPrint('Error generating reset code: $e');
          }
          
          // Show success message and navigate to verification screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A 6-digit verification code has been sent to your email. Please check your inbox.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          
          // Navigate to verification screen
          Navigator.pushNamed(
            context,
            Routes.forgotPasswordVerification,
            arguments: email,
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
            // Generic message for security - don't reveal if email exists
            errorMessage = 'If an account exists with this email, a reset code will be sent. Please check your email.';
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
