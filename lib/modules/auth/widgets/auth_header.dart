import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:food_flow_app/styles/colors/custom_colors.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;

  const AuthHeader({super.key, required this.title, required this.subtitle, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900
            : const Color(0xFF2E2739), // Dark blue-grey
      ),
      child: Stack(
        children: [
          // Decorative background patterns
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(isDark: isDark),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(Sizes.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBackButton) ...[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: Sizes.s40,
                      height: Sizes.s40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark
                            ? Colors.white
                            : CustomColors.textBoldColor,
                        size: Sizes.s20,
                      ),
                    ),
                  ),
                  const SizedBox(height: Sizes.s8),
                ],
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: Sizes.s28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Sizes.s6),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyLargeSecondary.copyWith(color: Colors.white70, fontSize: Sizes.s13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sizes.s20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  _BackgroundPatternPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Radial lines pattern on the left
    final center = Offset(size.width * 0.2, size.height * 0.3);
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final endX = center.dx + 60 * math.cos(angle);
      final endY = center.dy + 60 * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }

    // Dashed rectangle pattern on the right
    final rectPaint = Paint()
      ..color = isDark
          ? Colors.brown.withOpacity(0.1)
          : Colors.brown.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(size.width * 0.6, size.height * 0.2, size.width * 0.3, size.height * 0.3);

    // Draw dashed rectangle
    final dashWidth = 5.0;
    final dashSpace = 3.0;
    double startX = rect.left;

    // Top edge
    while (startX < rect.right) {
      canvas.drawLine(Offset(startX, rect.top), Offset(startX + dashWidth, rect.top), rectPaint);
      startX += dashWidth + dashSpace;
    }

    // Right edge
    double startY = rect.top;
    while (startY < rect.bottom) {
      canvas.drawLine(Offset(rect.right, startY), Offset(rect.right, startY + dashWidth), rectPaint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
