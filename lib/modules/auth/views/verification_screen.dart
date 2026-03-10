import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/services/app_preferences_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/auth/widgets/auth_header.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isChecking = false;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  bool _isEmailVerified = false;
  int _remainingSeconds = 120; // 2 minutes = 120 seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // Start countdown timer
    _startCountdownTimer();
    // Start polling to check if email is verified
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Start 2-minute countdown timer
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  /// Format seconds to MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Start polling to check email verification status
  void _startPolling() {
    // Check immediately
    _checkVerificationStatus();

    // Then check every 2 seconds for faster detection
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isEmailVerified && mounted) {
        _checkVerificationStatus();
      } else {
        timer.cancel();
      }
    });
  }

  /// Check if email is verified
  Future<void> _checkVerificationStatus() async {
    if (_isChecking || _isEmailVerified) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user != null) {
        // Reload user to get latest verification status
        await user.reload();
        final updatedUser = auth.currentUser;

        if (updatedUser?.emailVerified == true && !_isEmailVerified) {
          _isEmailVerified = true;
          _pollingTimer?.cancel();

          // Save token and navigate to update profile
          final token = await updatedUser!.getIdToken();
          await AppPreferencesService.saveAuthToken(token!);

          // Ensure FCM token is initialized after email verification
          try {
            final pushService = PushNotificationService.instance;
            pushService.setupForegroundMessageHandler();
            final fcmToken = await pushService.initializeAndGetToken();
            if (fcmToken != null) {
              await pushService.saveTokenToFirestore(fcmToken);
            }
          } catch (e) {
            debugPrint('Error initializing FCM token after verification: $e');
          }

          if (mounted) {
            Navigator.pushReplacementNamed(context, Routes.updateProfile);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    } finally {
      if (mounted && !_isEmailVerified) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Manual check button handler
  Future<void> _handleManualCheck() async {
    await _checkVerificationStatus();

    if (!_isEmailVerified && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email not verified yet. Please click the link in your email.'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)));
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    try {
      final authController = DependencyInjection.instance.authController;
      await authController.sendEmailVerification();

      // Reset timer
      setState(() {
        _remainingSeconds = 120;
        _canResend = false;
      });
      _startCountdownTimer();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Verification email resent. Please check your inbox.'), backgroundColor: Colors.green, duration: Duration(seconds: 3)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to resend email: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
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
            AuthHeader(title: 'Verification', subtitle: 'Click the link sent to ${widget.email}', showBackButton: true),

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

                      const SizedBox(height: Sizes.s16),
                      Text(
                        'We\'ve sent a verification link to',
                        style: AppTextStyles.bodyLargeSecondary.copyWith(fontSize: Sizes.s14, color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : null),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s8),
                      Text(
                        widget.email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: Sizes.s16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Theme.of(context).colorScheme.primary : const Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Timer Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sizes.s24, vertical: Sizes.s16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(Sizes.s16),
                          border: Border.all(color: isDark ? Colors.orange.shade700 : Colors.orange.shade200, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer_outlined, color: isDark ? Colors.orange.shade300 : Colors.orange.shade700, size: Sizes.s24),
                                const SizedBox(width: Sizes.s8),
                                Text(
                                  'Auto-checking in:',
                                  style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.orange.shade200 : Colors.orange.shade900, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: AppTextStyles.heading1.copyWith(
                                color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                                fontSize: Sizes.s32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sizes.s24),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(Sizes.s16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(Sizes.s12),
                          border: Border.all(color: isDark ? Colors.blue.shade700 : Colors.blue.shade200, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: Sizes.s20, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                const SizedBox(width: Sizes.s8),
                                Text(
                                  'How to verify:',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.blue.shade300 : Colors.blue.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              '1. Check your email inbox\n'
                              '2. Click the verification link in the email\n'
                              '3. Your email will be verified automatically\n'
                              '4. This screen will update automatically when verified',
                              style: AppTextStyles.bodySmall.copyWith(color: isDark ? Colors.blue.shade200 : Colors.blue.shade800, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Check Status Button
                      SizedBox(
                        height: Sizes.s56,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _handleManualCheck,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                            elevation: 0,
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  height: Sizes.s24,
                                  width: Sizes.s24,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.refresh, color: Colors.white, size: Sizes.s20),
                                    const SizedBox(width: Sizes.s8),
                                    Text('CHECK VERIFICATION STATUS', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Resend Email
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the email? ",
                            style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : CustomColors.secondaryTextColor),
                          ),
                          GestureDetector(
                            onTap: _canResend ? _resendVerificationEmail : null,
                            child: Text(
                              _canResend ? 'Resend' : 'Resend (${_formatTime(_remainingSeconds)})',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _canResend
                                    ? const Color(0xFFFF6B35)
                                    : isDark
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                    : CustomColors.secondaryTextColor.withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                                decoration: _canResend ? null : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Auto-checking indicator
                      // if (_isChecking)
                      //   Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       SizedBox(
                      //         width: Sizes.s16,
                      //         height: Sizes.s16,
                      //         child: CircularProgressIndicator(
                      //           strokeWidth: 2,
                      //           valueColor: AlwaysStoppedAnimation<Color>(
                      //             isDark
                      //                 ? Theme.of(context).colorScheme.primary
                      //                 : const Color(0xFFFF6B35),
                      //           ),
                      //         ),
                      //       ),
                      //       const SizedBox(width: Sizes.s8),
                      //       Text(
                      //         'Checking verification status...',
                      //         style: AppTextStyles.bodySmall.copyWith(
                      //           color: isDark
                      //               ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      //               : CustomColors.secondaryTextColor,
                      //           fontStyle: FontStyle.italic,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
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
