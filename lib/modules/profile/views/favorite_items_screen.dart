import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/modules/favorites/controllers/favorites_controller.dart';
import 'package:food_flow_app/models/food_item_model.dart';
import 'package:food_flow_app/modules/widgets/top_navigation_bar.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class FavoriteItemsScreen extends StatefulWidget {
  const FavoriteItemsScreen({super.key});

  @override
  State<FavoriteItemsScreen> createState() => _FavoriteItemsScreenState();
}

class _FavoriteItemsScreenState extends State<FavoriteItemsScreen> {
  late final FavoritesController _favoritesController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _favoritesController = DependencyInjection.instance.favoritesController;
    _favoritesController.addListener(_onFavoritesChanged);
    _initializeFavorites();
  }

  @override
  void dispose() {
    _favoritesController.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeFavorites() async {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser?.id != null) {
      await _favoritesController.initialize(currentUser!.id!);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _favoritesController.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              TopNavigationBar(title: 'Favorites'),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(title: 'Favorites'),

            // Favorite Items List
            Expanded(
              child: _favoritesController.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                      itemCount: _favoritesController.favoriteProducts.length,
                      itemBuilder: (context, index) {
                        final item = _favoritesController.favoriteProducts[index];
                        return AnimatedListItem(
                          index: index,
                          child: _buildFavoriteItemCard(item, context),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIconsHelper.favorite, size: Sizes.s80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: Sizes.s24),
          Text('No favorites yet', style: AppTextStyles.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: Sizes.s8),
          Text('Start adding items to your favorites', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildFavoriteItemCard(FoodItem item, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.itemDetail, arguments: item);
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
            // Food Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), bottomLeft: Radius.circular(Sizes.s16)),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: Sizes.s120,
                height: Sizes.s120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: Sizes.s120,
                  height: Sizes.s120,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: Sizes.s120,
                  height: Sizes.s120,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(
                    TablerIconsHelper.restaurant,
                    size: Sizes.s40,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),

            // Food Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Name
                    Text(
                      item.name,
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s4),

                    // Restaurant Name
                    Text(
                      item.restaurantName,
                      style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s8),

                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(),
                        Text(
                          '\$${item.basePrice.toInt()}',
                          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF6B35)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Remove from Favorites Button
            Padding(
              padding: const EdgeInsets.all(Sizes.s8),
              child: IconButton(
                icon: Icon(TablerIconsHelper.favorite, color: const Color(0xFFFF6B35), size: Sizes.s24),
                onPressed: () async {
                  final authController = DependencyInjection.instance.authController;
                  final currentUser = authController.currentUser;

                  if (currentUser?.id != null && item.id != null) {
                    final success = await _favoritesController.removeFromFavorites(
                      currentUser!.id!,
                      item.id!,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} removed from favorites'),
                          backgroundColor: Theme.of(context).cardColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
