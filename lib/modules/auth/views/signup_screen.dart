import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/auth/widgets/auth_header.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

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

  // Reactive validation errors (null = no error)
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _retypePasswordError;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your name';
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) return 'Name must be at least 2 characters';
    if (trimmedValue.length > 50) return 'Name must be less than 50 characters';
    if (trimmedValue.contains('  ')) return 'Name cannot contain multiple spaces';
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(trimmedValue)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final trimmedValue = value.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedValue)) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateRetypePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please re-enter your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  bool get _isFormValid =>
      _nameError == null &&
      _emailError == null &&
      _passwordError == null &&
      _retypePasswordError == null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _nameError = _validateName(_nameController.text);
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _retypePasswordError = _validateRetypePassword(_retypePasswordController.text);
    });

    if (!_isFormValid) return;

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = _getFirebaseAuthErrorMessage(e.code, e.message);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'An unexpected error occurred. Please try again.';

          // Check if it's a platform-specific error
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('network') || errorString.contains('connection')) {
            errorMessage = 'Network error. Please check your internet connection and try again.';
          } else if (errorString.contains('credential') ||
              errorString.contains('incorrect') ||
              errorString.contains('malformed') ||
              errorString.contains('expired')) {
            errorMessage =
                'Invalid email or password. Please check your credentials and try again.';
          } else if (errorString.contains('timeout')) {
            errorMessage =
                'Request timed out. Please check your internet connection and try again.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
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
                  color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
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
                          hintText: 'John Doe',
                          errorText: _nameError,
                          onChanged: (value) {
                            setState(() {
                              _nameError = _validateName(value);
                            });
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
                          errorText: _emailError,
                          onChanged: (value) {
                            setState(() {
                              _emailError = _validateEmail(value);
                            });
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
                          errorText: _passwordError,
                          onChanged: (value) {
                            setState(() {
                              _passwordError = _validatePassword(value);
                              _retypePasswordError =
                                  _validateRetypePassword(_retypePasswordController.text);
                            });
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                        ),
                        // const SizedBox(height: Sizes.s24),

                        // User Role Selection
                        // Text(
                        //   'SELECT ROLE',
                        //   style: AppTextStyles.label.copyWith(
                        //     color: isDark ? Theme.of(context).colorScheme.onSurface : CustomColors.textBoldColor,
                        //     fontSize: Sizes.s12,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        // const SizedBox(height: Sizes.s8),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _buildRoleOption(
                        //         context: context,
                        //         title: 'Customer',
                        //         icon: Icons.person,
                        //         userType: UserType.customer,
                        //         isSelected: _selectedUserType == UserType.customer,
                        //       ),
                        //     ),
                        //     const SizedBox(width: Sizes.s12),
                        //     Expanded(
                        //       child: _buildRoleOption(
                        //         context: context,
                        //         title: 'Admin',
                        //         icon: Icons.admin_panel_settings,
                        //         userType: UserType.admin,
                        //         isSelected: _selectedUserType == UserType.admin,
                        //       ),
                        //     ),
                        //     const SizedBox(width: Sizes.s12),
                        //     Expanded(
                        //       child: _buildRoleOption(
                        //         context: context,
                        //         title: 'Rider',
                        //         icon: Icons.delivery_dining,
                        //         userType: UserType.rider,
                        //         isSelected: _selectedUserType == UserType.rider,
                        //       ),
                        //     ),
                        //   ],
                        // ),
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
                          errorText: _retypePasswordError,
                          onChanged: (value) {
                            setState(() {
                              _retypePasswordError = _validateRetypePassword(value);
                            });
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureRetypePassword ? Icons.visibility_off : Icons.visibility,
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

  /// Get user-friendly error message from Firebase Auth error code
  String _getFirebaseAuthErrorMessage(String code, String? message) {
    switch (code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';

      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead or use a different email.';

      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email format (e.g., example@email.com).';

      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';

      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled. Please contact support for assistance.';

      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'Invalid credentials. Please check your information and try again.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';

      case 'too-many-requests':
        return 'Too many sign-up attempts. Please wait a few minutes and try again.';

      case 'requires-recent-login':
        return 'Please sign out and sign in again to complete this action.';

      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';

      case 'invalid-action-code':
        return 'The action code is invalid or has expired. Please request a new one.';

      case 'expired-action-code':
        return 'The action code has expired. Please request a new one.';

      case 'session-expired':
        return 'Your session has expired. Please try again.';

      default:
        // Try to extract a user-friendly message from the error message
        if (message != null && message.isNotEmpty) {
          final lowerMessage = message.toLowerCase();

          if (lowerMessage.contains('credential') ||
              lowerMessage.contains('incorrect') ||
              lowerMessage.contains('malformed') ||
              lowerMessage.contains('expired')) {
            return 'Invalid email or password. Please check your credentials and try again.';
          }

          if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
            return 'Network error. Please check your internet connection and try again.';
          }

          if (lowerMessage.contains('timeout')) {
            return 'Request timed out. Please check your internet connection and try again.';
          }

          // Return a sanitized version of the message if it's user-friendly
          if (!lowerMessage.contains('exception') &&
              !lowerMessage.contains('error') &&
              !lowerMessage.contains('failed')) {
            return message;
          }
        }

        return 'Sign up failed. Please check your information and try again.';
    }
  }
}
