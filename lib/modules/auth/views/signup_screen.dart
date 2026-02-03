import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/auth/models/user_model.dart';
import 'package:food_flow_app/modules/auth/widgets/auth_header.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;
  UserType _selectedUserType = UserType.customer;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authController = DependencyInjection.instance.authController;
        
        // Sign up with Firebase
        final success = await authController.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          userType: _selectedUserType,
        );

        if (success && mounted) {
          // Send verification email
          await authController.sendEmailVerification();
          
          // Navigate to verification screen
          Navigator.pushNamed(
            context,
            Routes.verification,
            arguments: _emailController.text.trim(),
          );
        } else if (mounted) {
          // Show error message
          final errorMsg = authController.error ?? 'Sign up failed. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Sign up failed. Please try again.';
        
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your internet connection and try again.';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email is already registered. Please use a different email or sign in.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address. Please enter a valid email.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please use a stronger password.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled. Please contact support.';
            break;
          default:
            errorMessage = e.message ?? 'Sign up failed. Please try again.';
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
              title: 'Sign Up',
              subtitle: 'Please sign up to get started',
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

                        // Name Field
                        Text(
                          'NAME',
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
                          controller: _nameController,
                          hintText: 'John doe',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Sizes.s24),

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
                        const SizedBox(height: Sizes.s24),

                        // Password Field
                        Text(
                          'PASSWORD',
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
                          controller: _passwordController,
                          hintText: 'Enter your password',
                          obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Sizes.s24),

                        // User Role Selection
                        Text(
                          'SELECT ROLE',
                          style: AppTextStyles.label.copyWith(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : CustomColors.textBoldColor,
                            fontSize: Sizes.s12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Sizes.s8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleOption(
                                context: context,
                                title: 'Customer',
                                icon: Icons.person,
                                userType: UserType.customer,
                                isSelected: _selectedUserType == UserType.customer,
                              ),
                            ),
                            const SizedBox(width: Sizes.s12),
                            Expanded(
                              child: _buildRoleOption(
                                context: context,
                                title: 'Admin',
                                icon: Icons.admin_panel_settings,
                                userType: UserType.admin,
                                isSelected: _selectedUserType == UserType.admin,
                              ),
                            ),
                            const SizedBox(width: Sizes.s12),
                            Expanded(
                              child: _buildRoleOption(
                                context: context,
                                title: 'Rider',
                                icon: Icons.delivery_dining,
                                userType: UserType.rider,
                                isSelected: _selectedUserType == UserType.rider,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Re-type Password Field
                        Text(
                          'RE-TYPE PASSWORD',
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
                          controller: _retypePasswordController,
                          hintText: 'Re-enter your password',
                          obscureText: _obscureRetypePassword,
                            suffixIcon: IconButton(
                            icon: Icon(
                              _obscureRetypePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureRetypePassword = !_obscureRetypePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please re-enter your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Sizes.s32),

                        // Sign Up Button
                        SizedBox(
                          height: Sizes.s56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Sizes.s12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: Sizes.s24,
                                    width: Sizes.s24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'SIGN UP',
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

  Widget _buildRoleOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required UserType userType,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = userType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Sizes.s12, horizontal: Sizes.s8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withOpacity(0.1)
              : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(Sizes.s12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B35)
                : isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFFF6B35)
                  : isDark
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                      : CustomColors.secondaryTextColor,
              size: Sizes.s24,
            ),
            const SizedBox(height: Sizes.s4),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : isDark
                        ? Theme.of(context).colorScheme.onSurface
                        : CustomColors.textBoldColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
