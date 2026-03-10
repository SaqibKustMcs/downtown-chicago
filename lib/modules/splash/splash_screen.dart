import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/services/app_preferences_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

import '../../Constants/colors.dart';
import '../../styles/colors/custom_colors.dart';

/// Timeouts to prevent splash from hanging on slow/unreliable devices or network.
const Duration _splashMinDelay = Duration(seconds: 2);
const Duration _prefsTimeout = Duration(seconds: 4);
const Duration _reloadTimeout = Duration(seconds: 5);
const Duration _refreshUserTimeout = Duration(seconds: 5);
const Duration _maxSplashDuration = Duration(seconds: 10);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _navigateToHome();
    _startMaxDurationGuard();
  }

  /// If navigation hasn't completed within [_maxSplashDuration], force a safe route.
  void _startMaxDurationGuard() {
    Future.delayed(_maxSplashDuration, () {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      debugPrint('SplashScreen: max duration reached, using fallback navigation');
      _navigateFallback();
    });
  }

  Future<void> _navigateFallback() async {
    if (!mounted) return;
    try {
      final isLoggedIn = await AppPreferencesService.isLoggedIn().timeout(
        _prefsTimeout,
        onTimeout: () => false,
      );
      if (!mounted) return;
      // After splash, non-logged-in users go to login first
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, Routes.mainContainer);
      } else {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    } catch (e, st) {
      debugPrint('SplashScreen fallback error: $e\n$st');
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    }
  }

  void _navigateTo(String route, [Object? arguments]) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    if (arguments != null) {
      Navigator.pushReplacementNamed(context, route, arguments: arguments);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _navigateToHome() async {
    try {
      await Future.delayed(_splashMinDelay);
      if (!mounted || _hasNavigated) return;

      // Prefs with timeout (some devices hang on SecureStorage)
      final isLoggedIn = await AppPreferencesService.isLoggedIn().timeout(
        _prefsTimeout,
        onTimeout: () {
          debugPrint('SplashScreen: isLoggedIn timeout');
          return false;
        },
      );

      if (!mounted || _hasNavigated) return;

      if (isLoggedIn) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          try {
            await firebaseUser.reload().timeout(_reloadTimeout);
          } on TimeoutException catch (_) {
            debugPrint('SplashScreen: firebaseUser.reload() timeout, using cached user');
          } catch (e) {
            debugPrint('SplashScreen: firebaseUser.reload() error: $e');
          }
          if (!mounted || _hasNavigated) return;

          final updatedUser = FirebaseAuth.instance.currentUser;
          if (updatedUser != null && !updatedUser.emailVerified) {
            final authController = DependencyInjection.instance.authController;
            await authController.signOut();
            _navigateTo(Routes.verification, updatedUser.email ?? '');
            return;
          }
        }

        final authController = DependencyInjection.instance.authController;
        try {
          await authController.refreshUser().timeout(_refreshUserTimeout);
        } on TimeoutException catch (_) {
          debugPrint('SplashScreen: refreshUser() timeout, using cached user');
        } catch (e) {
          debugPrint('SplashScreen: refreshUser() error: $e');
        }

        _initializeFcmToken();

        if (!mounted || _hasNavigated) return;

        final currentUser = authController.currentUser;
        String route;
        if (currentUser != null) {
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
        } else {
          route = Routes.mainContainer;
        }
        _navigateTo(route);
      } else {
        // Not logged in: go to login first screen after splash
        _navigateTo(Routes.login);
      }
    } catch (e, st) {
      debugPrint('SplashScreen _navigateToHome error: $e\n$st');
      if (!_hasNavigated && mounted) {
        _hasNavigated = true;
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    }
  }

  /// Initialize FCM token for logged-in user
  Future<void> _initializeFcmToken() async {
    try {
      final pushService = PushNotificationService.instance;
      pushService.setupForegroundMessageHandler();
      final token = await pushService.initializeAndGetToken();
      if (token != null) {
        await pushService.saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error initializing FCM token on app startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated GIF - centered, scales to fit width with max height
              ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: Image.asset(
                  'assets/images/splashgif.gif',
                  width: MediaQuery.of(context).size.width * 0.75,
                  fit: BoxFit.contain,
                  height: 220,
                  // errorBuilder: (_, __, ___) => Image.asset(
                  //   'assets/images/splash_logo.jpeg',
                  //   height: 180,
                  //   fit: BoxFit.contain,
                  // ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Down Town',
                style: AppTextStyles.heading1.copyWith(color: CustomColors.backgroundColor),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: CircularProgressIndicator(color: CustomColors.backgroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
