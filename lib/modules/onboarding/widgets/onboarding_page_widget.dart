import 'package:flutter/material.dart';
import 'package:downtown/modules/onboarding/models/onboarding_page_model.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPageModel page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: Sizes.s32),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800
                    : page.backgroundColor,
                borderRadius: BorderRadius.circular(Sizes.s24),
              ),
              child: Stack(
                children: [
                  // Decorative background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WavePatternPainter(isDark: isDark),
                    ),
                  ),
                  // Main illustration
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Person with device (simplified as icon)
                        Positioned(
                          bottom: Sizes.s40,
                          child: Container(
                            padding: const EdgeInsets.all(Sizes.s20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                  blurRadius: Sizes.s20,
                                  offset: const Offset(0, Sizes.s8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              size: Sizes.s60,
                              color: const Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                        // Device/tablet
                        Positioned(
                          bottom: Sizes.s20,
                          child: Container(
                            width: Sizes.s80,
                            height: Sizes.s100,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.black87,
                              borderRadius: BorderRadius.circular(Sizes.s8),
                            ),
                            child: Icon(
                              Icons.tablet,
                              color: Colors.white70,
                              size: Sizes.s40,
                            ),
                          ),
                        ),
                        // Food items positioned around
                        Positioned(
                          left: Sizes.s20,
                          top: Sizes.s40,
                          child: _buildFoodItem(context, Icons.fastfood, Colors.red, 'Fries', isDark),
                        ),
                        Positioned(
                          left: Sizes.s30,
                          top: Sizes.s10,
                          child: _buildFoodItem(context, Icons.local_cafe, Colors.brown, 'Coffee', isDark),
                        ),
                        Positioned(
                          top: Sizes.s20,
                          child: _buildFoodItem(context, Icons.soup_kitchen, Colors.red, 'Bowl', isDark),
                        ),
                        Positioned(
                          right: Sizes.s30,
                          top: Sizes.s20,
                          child: _buildFoodItem(context, Icons.lunch_dining, Colors.orange, 'Burger', isDark),
                        ),
                        Positioned(
                          right: Sizes.s20,
                          bottom: Sizes.s60,
                          child: _buildFoodItem(context, Icons.local_pizza, Colors.orange, 'Pizza', isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text content
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: Sizes.s28,
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurface
                        : CustomColors.textBoldColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Sizes.s16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.s16),
                  child: Text(
                    page.description,
                    style: AppTextStyles.bodyLargeSecondary.copyWith(
                      fontSize: Sizes.s16,
                      height: 1.5,
                      color: isDark
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                          : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, IconData icon, Color color, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade700
            : Colors.white,
        borderRadius: BorderRadius.circular(Sizes.s12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: Sizes.s8,
            offset: const Offset(0, Sizes.s4),
          ),
        ],
      ),
      child: Icon(icon, size: Sizes.s32, color: color),
    );
  }
}

class _WavePatternPainter extends CustomPainter {
  final bool isDark;

  _WavePatternPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (double i = 0; i < size.width; i += 40) {
      path.moveTo(i, size.height * 0.3);
      path.quadraticBezierTo(
        i + 20,
        size.height * 0.3 + 10,
        i + 40,
        size.height * 0.3,
      );
    }
    canvas.drawPath(path, paint);

    final path2 = Path();
    for (double i = 0; i < size.width; i += 40) {
      path2.moveTo(i, size.height * 0.7);
      path2.quadraticBezierTo(
        i + 20,
        size.height * 0.7 - 10,
        i + 40,
        size.height * 0.7,
      );
    }
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
