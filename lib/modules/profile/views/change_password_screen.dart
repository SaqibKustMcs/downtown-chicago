import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChanging = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChanging = true;
    });

    try {
      final authController = DependencyInjection.instance.authController;
      final currentUser = FirebaseService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );

      try {
        await currentUser.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Generic error message for security - don't reveal which credential is wrong
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw Exception('AUTH_FAILED'); // Generic marker, will show generic message
        } else if (e.code == 'user-mismatch' || e.code == 'user-not-found') {
          throw Exception('AUTH_FAILED'); // Generic marker
        } else {
          throw Exception('AUTH_FAILED'); // Generic marker
        }
      }

      // Update password
      final success = await authController.updatePassword(_newPasswordController.text);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Clear form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Navigate back
        Navigator.pop(context);
      } else if (mounted) {
        final errorMsg = authController.error ?? 'Failed to change password. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password. Please try again.';
      
      switch (e.code) {
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use a stronger password.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log out and log back in first.';
          break;
        default:
          // Always use generic message - never show raw Firebase error messages
          errorMessage = 'Failed to change password. Please try again.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Always show generic error message for security - never reveal specific error details
        String errorMessage = 'Failed to change password. Please check your credentials and try again.';
        
        // Check if it's our generic auth failure marker
        if (e is Exception && e.toString().contains('AUTH_FAILED')) {
          errorMessage = 'Authentication failed. Please check your current password.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChanging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Top Navigation
              _buildTopNavigation(isDark),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sizes.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Sizes.s16),

                      // Title
                      Text(
                        'Change Password',
                        style: AppTextStyles.heading1.copyWith(
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface
                              : CustomColors.textBoldColor,
                          fontSize: Sizes.s24,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      Text(
                        'Enter your current password and choose a new one',
                        style: AppTextStyles.bodyLargeSecondary.copyWith(
                          fontSize: Sizes.s14,
                          color: isDark
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                              : null,
                        ),
                      ),
                      const SizedBox(height: Sizes.s40),

                      // Current Password Field
                      Text(
                        'CURRENT PASSWORD',
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
                        controller: _currentPasswordController,
                        hintText: 'Enter your current password',
                        obscureText: _obscureCurrentPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : CustomColors.secondaryTextColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                        onChanged: (value) {
                          // Re-validate new password field when current password changes
                          if (_formKey.currentState != null && _newPasswordController.text.isNotEmpty) {
                            _formKey.currentState!.validate();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s24),

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
                        hintText: 'Enter your new password',
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
                        onChanged: (value) {
                          // Clear validation errors when user types
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.validate();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          if (value == _currentPasswordController.text.trim()) {
                            return 'New password must be different';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s24),

                      // Confirm Password Field
                      Text(
                        'CONFIRM NEW PASSWORD',
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
                        hintText: 'Re-enter your new password',
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
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Change Password Button
                      SizedBox(
                        height: Sizes.s56,
                        child: ElevatedButton(
                          onPressed: _isChanging ? null : _handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Sizes.s12),
                            ),
                            elevation: 0,
                          ),
                          child: _isChanging
                              ? const SizedBox(
                                  height: Sizes.s20,
                                  width: Sizes.s20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'CHANGE PASSWORD',
                                  style: AppTextStyles.buttonLargeBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: Sizes.s24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigation(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Back Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                TablerIconsHelper.arrowLeft,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Title
          Text(
            'Change Password',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
