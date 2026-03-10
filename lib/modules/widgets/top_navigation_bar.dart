import 'package:flutter/material.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Reusable top navigation bar with back button and title
class TopNavigationBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const TopNavigationBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Back Button (optional)
          if (showBackButton) ...[
            BackButtonWidget(
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            ),
            const SizedBox(width: Sizes.s12),
          ],
          
          // Title
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          
          // Trailing widget (optional)
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Reusable circular back button
class BackButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool showShadow;

  const BackButtonWidget({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: Sizes.s40,
      height: Sizes.s40,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: Sizes.s4,
                  offset: const Offset(0, Sizes.s2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(
          TablerIconsHelper.arrowLeft,
          color: Theme.of(context).colorScheme.onSurface,
          size: Sizes.s20,
        ),
        onPressed: onPressed ?? () => Navigator.pop(context),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
