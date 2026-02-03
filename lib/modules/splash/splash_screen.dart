import 'package:flutter/material.dart';
import 'package:food_flow_app/core/services/app_preferences_service.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

import '../../Constants/colors.dart';
import '../../styles/colors/custom_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check if onboarding has been completed
    final isOnboardingCompleted = await AppPreferencesService.isOnboardingCompleted();

    // Check if user is already logged in
    final isLoggedIn = await AppPreferencesService.isLoggedIn();

    if (isLoggedIn) {
      // User is logged in, go to main container
      Navigator.pushReplacementNamed(context, Routes.mainContainer);
    } else if (isOnboardingCompleted) {
      // Onboarding completed but not logged in, go to login
      Navigator.pushReplacementNamed(context, Routes.login);
    } else {
      // First launch, show onboarding
      Navigator.pushReplacementNamed(context, Routes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF6B35),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 100, color: CustomColors.backgroundColor),
            const SizedBox(height: 24),
            Text('Food Flow', style: AppTextStyles.heading1.copyWith(color: CustomColors.backgroundColor)),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: CustomColors.backgroundColor),
          ],
        ),
      ),
    );
  }
}
