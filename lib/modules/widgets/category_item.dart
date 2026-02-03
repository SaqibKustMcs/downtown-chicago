import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class Category {
  final String name;
  final String imageUrl;
  final bool isSelected;

  const Category({required this.name, required this.imageUrl, this.isSelected = false});
}

/// Reusable category item widget
class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.pushNamed(context, Routes.categoryDetail, arguments: category.name);
          },
      child: Container(
        width: width ?? Sizes.s80,
        height: height ?? Sizes.s100,
        decoration: BoxDecoration(
          color: category.isSelected ? const Color(0xFFFF6B35) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: Sizes.s8,
              offset: const Offset(0, Sizes.s2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category Image or Icon
            category.name.toLowerCase() == 'all'
                ? Container(
                    width: Sizes.s40,
                    height: Sizes.s42,
                    decoration: BoxDecoration(
                      color: category.isSelected
                          ? Colors.white.withOpacity(0.2)
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(Sizes.s8),
                    ),
                    child: Icon(
                      TablerIconsHelper.apps,
                      size: Sizes.s24,
                      color: category.isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(Sizes.s8),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      width: Sizes.s40,
                      height: Sizes.s42,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: Sizes.s40,
                        height: Sizes.s42,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: Sizes.s40,
                        height: Sizes.s42,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Icon(
                          Icons.error_outline,
                          size: Sizes.s20,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: Sizes.s8),
            // Category Name
            Text(
              category.name,
              style: AppTextStyles.bodySmall.copyWith(
                color: category.isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: category.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
