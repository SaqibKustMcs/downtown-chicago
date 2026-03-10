import 'package:flutter/material.dart';
import 'package:downtown/styles/layouts/sizes.dart';

/// Reusable rating stars widget for displaying and selecting ratings (1-5)
/// Uses [RepaintBoundary] and const widgets where possible for performance.
class RatingStarsWidget extends StatelessWidget {
  final double rating; // 0.0 - 5.0
  final int maxStars;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool isInteractive;
  final ValueChanged<double>? onRatingSelected;

  const RatingStarsWidget({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = Sizes.s16,
    this.activeColor,
    this.inactiveColor,
    this.isInteractive = false,
    this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor =
        activeColor ?? const Color(0xFFFFC107); // Amber-like
    final effectiveInactiveColor =
        inactiveColor ?? theme.colorScheme.onSurface.withOpacity(0.2);

    final clampedRating = rating.clamp(0.0, maxStars.toDouble());

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(maxStars, (index) {
          final starIndex = index + 1;
          IconData iconData;

          if (clampedRating >= starIndex) {
            iconData = Icons.star;
          } else if (clampedRating >= starIndex - 0.5) {
            iconData = Icons.star_half;
          } else {
            iconData = Icons.star_border;
          }

          final star = Icon(
            iconData,
            size: size,
            color: iconData == Icons.star_border
                ? effectiveInactiveColor
                : effectiveActiveColor,
          );

          if (!isInteractive || onRatingSelected == null) {
            return star;
          }

          // Make star tappable when interactive
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => onRatingSelected!(starIndex.toDouble()),
            child: star,
          );
        }),
      ),
    );
  }
}

