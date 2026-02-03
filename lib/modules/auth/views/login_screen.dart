import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/auth/widgets/auth_header.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authController = DependencyInjection.instance.authController;

        // Sign in with Firebase
        final success = await authController.signIn(email: _emailController.text.trim(), password: _passwordController.text);

        if (success && mounted) {
          // Check if email is verified
          // final currentUser = authController.currentUser;
          // if (currentUser != null && !currentUser.emailVerified) {
          //   // Email not verified - show warning but allow login
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: const Text('Please verify your email to access all features.'),
          //       backgroundColor: Colors.orange,
          //       duration: const Duration(seconds: 3),
          //       action: SnackBarAction(
          //         label: 'Resend',
          //         textColor: Colors.white,
          //         onPressed: () async {
          //           await authController.sendEmailVerification();
          //           if (mounted) {
          //             ScaffoldMessenger.of(context).showSnackBar(
          //               const SnackBar(
          //                 content: Text('Verification email sent. Please check your inbox.'),
          //                 backgroundColor: Colors.green,
          //               ),
          //             );
          //           }
          //         },
          //       ),
          //     ),
          //   );
          // }

          // Login successful - navigate to main container
          Navigator.pushReplacementNamed(context, Routes.mainContainer);
        } else if (mounted) {
          // Show error message
          final errorMsg = authController.error ?? 'Login failed. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Login failed. Please try again.';

        switch (e.code) {
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your internet connection and try again.';
            break;
          case 'user-not-found':
            errorMessage = 'No account found with this email. Please sign up first.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address. Please enter a valid email.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled. Please contact support.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed login attempts. Please try again later.';
            break;
          case 'invalid-credential':
            errorMessage = 'Invalid email or password. Please check your credentials.';
            break;
          default:
            errorMessage = e.message ?? 'Login failed. Please try again.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
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

  void _navigateToSignUp() {
    Navigator.pushNamed(context, Routes.signUp);
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
            AuthHeader(title: 'Log In', subtitle: 'Please sign in to your existing account'),

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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Sizes.s32),

                        // Email Field
                        Text(
                          'EMAIL',
                          style: AppTextStyles.label.copyWith(
                            color: isDark ? Theme.of(context).colorScheme.onSurface : CustomColors.textBoldColor,
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
                            color: isDark ? Theme.of(context).colorScheme.onSurface : CustomColors.textBoldColor,
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
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : CustomColors.secondaryTextColor,
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
                        const SizedBox(height: Sizes.s16),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFFFF6B35),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s4)),
                                ),
                                Text('Remember me', style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Theme.of(context).colorScheme.onSurface : CustomColors.textBoldColor)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, Routes.forgotPassword);
                              },
                              child: Text('Forgot Password', style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35))),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sizes.s32),

                        // Login Button
                        SizedBox(
                          height: Sizes.s56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: Sizes.s20,
                                    width: Sizes.s20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                : Text('LOG IN', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : CustomColors.secondaryTextColor),
                            ),
                            GestureDetector(
                              onTap: _navigateToSignUp,
                              child: Text(
                                'SIGN UP',
                                style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35), fontWeight: FontWeight.w600),
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
