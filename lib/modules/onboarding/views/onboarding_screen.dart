import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:downtown/core/providers/theme_provider.dart';
import 'package:downtown/core/services/app_preferences_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/onboarding/models/onboarding_page_model.dart';
import 'package:downtown/modules/onboarding/widgets/onboarding_page_widget.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'Discover Delicious Food',
      description: 'Explore a wide variety of mouth-watering dishes from your favorite restaurants',
      icon: Icons.restaurant_menu,
      backgroundColor: const Color(0xFFFFF5E6),
    ),
    OnboardingPageModel(
      title: 'All your favorites',
      description: 'Get all your loved foods in one place, you just place the order we do the rest',
      icon: Icons.fastfood,
      backgroundColor: const Color(0xFFFFF5E6),
    ),
    OnboardingPageModel(
      title: 'Fast Delivery',
      description: 'Get your food delivered quickly and safely to your doorstep',
      icon: Icons.delivery_dining,
      backgroundColor: const Color(0xFFFFF5E6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _markOnboardingComplete();
      _navigateToLogin();
    }
  }

  void _skipOnboarding() async {
    await _markOnboardingComplete();
    _navigateToLogin();
  }

  Future<void> _markOnboardingComplete() async {
    await AppPreferencesService.setOnboardingCompleted();
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark 
          ? Theme.of(context).scaffoldBackgroundColor
          : CustomColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with theme switch and skip button
            Padding(
              padding: const EdgeInsets.all(Sizes.s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Theme Switch Button
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return GestureDetector(
                        onTap: () {
                          themeProvider.toggleTheme();
                        },
                        child: Container(
                          width: Sizes.s56,
                          height: Sizes.s32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(Sizes.s16),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                left: themeProvider.isDarkMode ? Sizes.s28 : Sizes.s4,
                                top: Sizes.s4,
                                child: Container(
                                  width: Sizes.s24,
                                  height: Sizes.s24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: Sizes.s4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    themeProvider.isDarkMode
                                        ? TablerIconsHelper.moon
                                        : TablerIconsHelper.sun,
                                    color: Colors.white,
                                    size: Sizes.s14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Skip button
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : CustomColors.textBoldColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sizes.s24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.s24,
                Sizes.s0,
                Sizes.s24,
                Sizes.s32,
              ),
              child: SizedBox(
                width: double.infinity,
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35), // Orange color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.s12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                    style: AppTextStyles.buttonLargeBold.copyWith(
                      color: Colors.white,
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

  Widget _buildPageIndicator(bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: Sizes.s4),
      height: Sizes.s8,
      width: isActive ? Sizes.s24 : Sizes.s8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFF6B35) // Orange color
            : isDark
                ? Colors.grey.shade700
                : const Color(0xFFE0E0E0), // Light gray
        borderRadius: BorderRadius.circular(Sizes.s4),
      ),
    );
  }
}
