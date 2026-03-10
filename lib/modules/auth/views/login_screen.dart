import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/services/app_preferences_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/auth/widgets/auth_header.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

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
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load remembered credentials if remember me was enabled
  Future<void> _loadRememberedCredentials() async {
    final isRememberMeEnabled = await AppPreferencesService.isRememberMeEnabled();
    if (isRememberMeEnabled) {
      final email = await AppPreferencesService.getRememberedEmail();
      final password = await AppPreferencesService.getRememberedPassword();
      
      if (mounted && email != null && password != null) {
        setState(() {
          _rememberMe = true;
          _emailController.text = email;
          _passwordController.text = password;
        });
      }
    }
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
          // Save or clear remember me credentials
          if (_rememberMe) {
            await AppPreferencesService.saveRememberMeCredentials(
              _emailController.text.trim(),
              _passwordController.text,
            );
          } else {
            await AppPreferencesService.clearRememberMeCredentials();
          }

          // Get current user model (to know userType)
          final currentUserModel = authController.currentUser;

          // Check if email is verified using Firebase Auth (source of truth)
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            // Reload user to get latest verification status
            await firebaseUser.reload();
            final updatedUser = FirebaseAuth.instance.currentUser;
            
            if (updatedUser != null && !updatedUser.emailVerified) {
              // Special case: riders created by admin.
              // For riders, allow login but send a verification email if not verified.
              if (currentUserModel != null && currentUserModel.userType == UserType.rider) {
                try {
                  await authController.sendEmailVerification();
                } catch (_) {
                  // Ignore errors sending verification email for riders
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Verification link sent to your email. You can verify later.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
                // Do NOT sign out or block login for riders.
              } else {
                // For customers/admins: block login until email is verified
                await authController.signOut();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please verify your email before signing in.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  
                  // Navigate to verification screen
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.verification,
                    arguments: updatedUser.email ?? _emailController.text.trim(),
                  );
                }
                return;
              }
            }
          }

          // Email is verified - proceed with login
          // Login successful - redirect based on user type
          final currentUser = currentUserModel ?? authController.currentUser;
          if (currentUser != null) {
            String route;
            switch (currentUser.userType) {
              case UserType.admin:
                route = Routes.adminMain;
                break;
              case UserType.rider:
                route = Routes.riderMain;
                break;
              case UserType.customer:
              default:
                route = Routes.mainContainer;
                break;
            }
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pushReplacementNamed(context, Routes.mainContainer);
          }
        } else if (mounted) {
          // Sign-in failed - parse error from controller
          final errorString = authController.error ?? '';
          String errorMessage = _parseErrorMessage(errorString);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = _getFirebaseAuthErrorMessage(e.code, e.message);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorString = e.toString();
          String errorMessage = _parseErrorMessage(errorString);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
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

  void _navigateToSignUp() {
    Navigator.pushNamed(context, Routes.signUp);
  }

  /// Parse error message from exception string (handles errors caught by BaseController)
  String _parseErrorMessage(String errorString) {
    if (errorString.isEmpty) {
      return 'Login failed. Please try again.';
    }
    
    final lowerError = errorString.toLowerCase();
    
    // Check for Recaptcha errors first (these can mask password errors)
    if (lowerError.contains('recaptcha') || lowerError.contains('recaptchacallwrapper')) {
      // Recaptcha errors often indicate network issues or Firebase App Check problems
      // But they can also mask wrong password errors, so show a helpful message
      if (lowerError.contains('network') || 
          lowerError.contains('timeout') || 
          lowerError.contains('unreachable') ||
          lowerError.contains('interrupted')) {
        return 'Network error during verification. Please check your internet connection and try again.';
      }
      return 'Verification error. Please check your internet connection and try again.';
    }
    
    // Check for Firebase Auth error codes in the string
    if (lowerError.contains('wrong-password') || 
        lowerError.contains('invalid-credential') ||
        lowerError.contains('user-not-found') ||
        lowerError.contains('invalid-email') ||
        (lowerError.contains('credential') && !lowerError.contains('recaptcha'))) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    
    // Network errors (excluding Recaptcha which is handled above)
    if (lowerError.contains('network') || 
        lowerError.contains('connection') ||
        lowerError.contains('unreachable') ||
        lowerError.contains('interrupted') ||
        lowerError.contains('timeout')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    // Too many requests
    if (lowerError.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please wait a few minutes and try again.';
    }
    
    // User disabled
    if (lowerError.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support for assistance.';
    }
    
    // Email not verified (shouldn't happen here, but handle it)
    if (lowerError.contains('email-not-verified') || lowerError.contains('email not verified')) {
      return 'Please verify your email before signing in.';
    }
    
    // Operation not allowed
    if (lowerError.contains('operation-not-allowed')) {
      return 'Email/password sign-in is not enabled. Please contact support.';
    }
    
    // Generic Firebase errors
    if (lowerError.contains('firebase') || lowerError.contains('firebaseauth')) {
      // Try to extract error code if present
      final codeMatch = RegExp(r'\[([a-z-]+)\]').firstMatch(lowerError);
      if (codeMatch != null) {
        return _getFirebaseAuthErrorMessage(codeMatch.group(1)!, null);
      }
      return 'Authentication failed. Please check your email and password, then try again.';
    }
    
    // Default fallback
    return 'Login failed. Please check your email and password, then try again.';
  }

  /// Get user-friendly error message from Firebase Auth error code
  String _getFirebaseAuthErrorMessage(String code, String? message) {
    switch (code) {
      case 'network-request-failed':
      case 'network_error':
      case 'networkerror':
        return 'Network error. Please check your internet connection and try again.';
      
      case 'user-not-found':
        return 'Invalid email or password. Please check your credentials and try again.';
      
      case 'wrong-password':
        return 'Invalid email or password. Please check your credentials and try again.';
      
      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email format (e.g., example@email.com).';
      
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      
      case 'too-many-requests':
        return 'Too many failed login attempts. Please wait a few minutes and try again.';
      
      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'Invalid email or password. Please check your credentials and try again.';
      
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      
      case 'requires-recent-login':
        return 'Please sign out and sign in again to complete this action.';
      
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      
      case 'invalid-action-code':
        return 'The action code is invalid or has expired. Please request a new one.';
      
      case 'expired-action-code':
        return 'The action code has expired. Please request a new one.';
      
      case 'session-expired':
        return 'Your session has expired. Please sign in again.';
      
      default:
        // Try to extract a user-friendly message from the error message
        if (message != null && message.isNotEmpty) {
          final lowerMessage = message.toLowerCase();
          
          if (lowerMessage.contains('credential') || lowerMessage.contains('incorrect') || lowerMessage.contains('malformed') || lowerMessage.contains('expired')) {
            return 'Invalid email or password. Please check your credentials and try again.';
          }
          
          if (lowerMessage.contains('network') || lowerMessage.contains('connection') || lowerMessage.contains('unreachable') || lowerMessage.contains('interrupted')) {
            return 'Network error. Please check your internet connection and try again.';
          }
          
          if (lowerMessage.contains('timeout')) {
            return 'Request timed out. Please check your internet connection and try again.';
          }
          
          // Handle Recaptcha errors
          if (lowerMessage.contains('recaptcha') || lowerMessage.contains('recaptchacallwrapper')) {
            if (lowerMessage.contains('network') || lowerMessage.contains('timeout') || lowerMessage.contains('unreachable')) {
              return 'Network error during verification. Please check your internet connection and try again.';
            }
            return 'Verification error. Please check your internet connection and try again.';
          }
          
          // Return a sanitized version of the message if it's user-friendly
          if (!lowerMessage.contains('exception') && !lowerMessage.contains('error') && !lowerMessage.contains('failed') && !lowerMessage.contains('firebaseexception')) {
            return message;
          }
        }
        
        return 'Login failed. Please check your email and password, then try again.';
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
