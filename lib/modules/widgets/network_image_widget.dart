import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/styles/layouts/sizes.dart';

/// Reusable network image widget with placeholder and error handling
class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData? errorIcon;
  final double? errorIconSize;
  final BorderRadius? borderRadius;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorIcon,
    this.errorIconSize,
    this.borderRadius,
  });

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
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: errorColor,
        child: Icon(
          errorIcon ?? Icons.error_outline,
          size: errorIconSize ?? Sizes.s40,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
