import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/auth/widgets/auth_header.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class UpdatePasswordScreen extends StatefulWidget {
  final dynamic arguments; // Can be String email or Map with email and code

  const UpdatePasswordScreen({
    super.key,
    this.arguments,
  });

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isUpdating = false;
  
  String get _email {
    if (widget.arguments is Map) {
      return widget.arguments['email'] ?? '';
    }
    return widget.arguments is String ? widget.arguments : '';
  }
  
  String? get _code {
    if (widget.arguments is Map) {
      return widget.arguments['code'];
    }
    return null;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      try {
        final authController = DependencyInjection.instance.authController;
        final newPassword = _newPasswordController.text;
        
        bool success = false;
        
        // If we have a code from password reset, use confirmPasswordReset
        if (_code != null && _code!.isNotEmpty) {
          success = await authController.confirmPasswordReset(
            code: _code!,
            newPassword: newPassword,
          );
        } else {
          // Fallback: if user is logged in, use updatePassword
          // Otherwise, show error
          if (authController.isAuthenticated()) {
            success = await authController.updatePassword(newPassword);
          } else {
            throw Exception('No reset code provided. Please request a new password reset.');
          }
        }

        if (success && mounted) {
          // Navigate to success screen
          Navigator.pushReplacementNamed(
            context,
            Routes.passwordResetSuccess,
          );
        } else if (mounted) {
          // Show error message
          final errorMsg = authController.error ?? 'Failed to update password. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Failed to update password. Please try again.';
        
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your internet connection and try again.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please use a stronger password.';
            break;
          case 'invalid-action-code':
            errorMessage = 'Invalid or expired reset code. Please request a new password reset.';
            break;
          case 'expired-action-code':
            errorMessage = 'Reset code has expired. Please request a new password reset.';
            break;
          default:
            errorMessage = e.message ?? 'Failed to update password. Please try again.';
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
            _isUpdating = false;
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
              title: 'Update Password',
              subtitle: 'Enter verification code and new password',
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
                          'Create New Password',
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
                          'Enter your new password below',
                          style: AppTextStyles.bodyLargeSecondary.copyWith(
                            fontSize: Sizes.s14,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sizes.s40),

                        // New Password Field
                        Text(
                          'NEW PASSWORD',
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
                          controller: _newPasswordController,
                          hintText: 'Enter new password',
                          obscureText: _obscureNewPassword,
                            suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Confirm Password Field
                        Text(
                          'CONFIRM PASSWORD',
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
                          controller: _confirmPasswordController,
                          hintText: 'Re-enter new password',
                          obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Sizes.s32),

                        // Update Password Button
                        SizedBox(
                          height: Sizes.s56,
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : _handleUpdatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Sizes.s12),
                              ),
                              elevation: 0,
                            ),
                            child: _isUpdating
                                ? const SizedBox(
                                    height: Sizes.s20,
                                    width: Sizes.s20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'UPDATE PASSWORD',
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
            ),
          ],
        ),
      ),
    );
  }
}
