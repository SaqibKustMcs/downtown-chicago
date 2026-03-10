import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';

/// Reusable vertical restaurant card (image on top, info below)
class RestaurantCardVertical extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCardVertical({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.pushNamed(context, Routes.restaurantView, arguments: restaurant);
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), topRight: Radius.circular(Sizes.s16)),
              child: NetworkImageWidget(
                imageUrl: restaurant.imageUrl,
                width: double.infinity,
                height: Sizes.s160,
                fit: BoxFit.cover,
                errorIcon: TablerIconsHelper.restaurant,
                errorIconSize: Sizes.s64,
              ),
            ),

            // Restaurant Info
            Padding(
              padding: const EdgeInsets.all(Sizes.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: Sizes.s4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.cuisines,
                          style: AppTextStyles.bodySmallSecondary.copyWith(fontSize: Sizes.s12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                      // Open/Closed Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
                        decoration: BoxDecoration(
                          color: restaurant.isCurrentlyOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Sizes.s8),
                          border: Border.all(color: restaurant.isCurrentlyOpen ? Colors.green : Colors.red, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: Sizes.s6,
                              height: Sizes.s6,
                              decoration: BoxDecoration(color: restaurant.isCurrentlyOpen ? Colors.green : Colors.red, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              restaurant.isCurrentlyOpen ? 'Open' : 'Closed',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: Sizes.s10,
                                fontWeight: FontWeight.w600,
                                color: restaurant.isCurrentlyOpen ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.s12),
                  Row(
                    children: [
                      const Icon(TablerIconsHelper.star, color: Color(0xFFFF6B35), size: Sizes.s16),
                      const SizedBox(width: Sizes.s4),
                      Text(
                        restaurant.rating.toString(),
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(width: Sizes.s16),
                      const Icon(TablerIconsHelper.delivery, color: Color(0xFFFF6B35), size: Sizes.s16),
                      const SizedBox(width: Sizes.s4),
                      Text(restaurant.deliveryCost, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(width: Sizes.s16),
                      const Icon(TablerIconsHelper.time, color: Color(0xFFFF6B35), size: Sizes.s16),
                      const SizedBox(width: Sizes.s4),
                      Text(restaurant.deliveryTime, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable horizontal restaurant card (image on left, info on right)
class RestaurantCardHorizontal extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCardHorizontal({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.pushNamed(context, Routes.restaurantView, arguments: restaurant);
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), bottomLeft: Radius.circular(Sizes.s16)),
              child: NetworkImageWidget(
                imageUrl: restaurant.imageUrl,
                width: Sizes.s120,
                height: Sizes.s120,
                fit: BoxFit.cover,
                errorIcon: TablerIconsHelper.restaurant,
                errorIconSize: Sizes.s40,
              ),
            ),

            // Restaurant Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurant.name,
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s4),

                    // Cuisines
                    Text(
                      restaurant.cuisines,
                      style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s8),

                    // Rating and Delivery Info
                    Row(
                      children: [
                        // Rating
                        Row(
                          children: [
                            RatingStarsWidget(rating: restaurant.rating, size: Sizes.s14),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(width: Sizes.s4),
                            Text('(${restaurant.totalRatings})', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ],
                    ),

                    // Delivery Cost
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(TablerIconsHelper.delivery, size: Sizes.s16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            const SizedBox(width: Sizes.s4),
                            Text(restaurant.deliveryCost, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                        const SizedBox(width: Sizes.s16),

                        // Delivery Time
                        Row(
                          children: [
                            Icon(TablerIconsHelper.time, size: Sizes.s16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            const SizedBox(width: Sizes.s4),
                            Text(restaurant.deliveryTime, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable network image widget with placeholder and error handling
class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData? errorIcon;
  final double? errorIconSize;
  final BorderRadius? borderRadius;

  const NetworkImageWidget({super.key, required this.imageUrl, this.width, this.height, this.fit = BoxFit.cover, this.errorIcon, this.errorIconSize, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final errorColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: placeholderColor,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: errorColor,
        child: Icon(errorIcon ?? Icons.error_outline, size: errorIconSize ?? Sizes.s40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}
