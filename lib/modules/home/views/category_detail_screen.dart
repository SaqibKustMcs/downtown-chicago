import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/models/food_item_model.dart';
import 'package:food_flow_app/models/restaurant_model.dart';
import 'package:food_flow_app/models/cart_item_model.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;

  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sizes.s24),

                      // Popular Items Section
                      Text(
                        'Popular ${widget.categoryName}s',
                        style: AppTextStyles.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.s24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Popular Items Grid - Fetch from Firestore
                      // Query products collection directly
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseService.firestore
                            .collection('products')
                            .snapshots(),
                        builder: (context, productsSnapshot) {
                          if (productsSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(Sizes.s32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (productsSnapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(Sizes.s32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: Sizes.s64,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(height: Sizes.s16),
                                    Text(
                                      'Error loading products',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (!productsSnapshot.hasData ||
                              productsSnapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(Sizes.s32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.fastfood_outlined,
                                      size: Sizes.s64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: Sizes.s16),
                                    Text(
                                      'No products available',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Get all active restaurant IDs first (for filtering)
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseService.firestore
                                .collection('restaurants')
                                .where('isActive', isEqualTo: true)
                                .where('isOpen', isEqualTo: true)
                                .snapshots(),
                            builder: (context, restaurantsSnapshot) {
                              final activeRestaurantIds = restaurantsSnapshot.hasData
                                  ? restaurantsSnapshot.data!.docs.map((doc) => doc.id).toSet()
                                  : <String>{};

                              // Filter products by category and restaurant
                              final categoryNameLower = widget.categoryName.toLowerCase().trim();
                              final allProducts = productsSnapshot.data!.docs
                                  .map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return FoodItem.fromFirestore(data, doc.id);
                                  })
                                  .where((product) {
                                    // Check if product belongs to an active restaurant
                                    final restaurantId = product.restaurantId;
                                    if (!activeRestaurantIds.contains(restaurantId)) {
                                      return false;
                                    }

                                    // Check category name match (case-insensitive)
                                    final productCategoryName =
                                        product.categoryName?.toLowerCase().trim() ?? '';
                                    final categoryMatch = productCategoryName == categoryNameLower;

                                    // Check if product is active and available
                                    final isActiveAndAvailable =
                                        product.isActive && product.isAvailable;

                                    return categoryMatch && isActiveAndAvailable;
                                  })
                                  .toList()
                                ..sort((a, b) => a.name.compareTo(b.name));

                              debugPrint(
                                  'Found ${allProducts.length} products for category "${widget.categoryName}" from ${activeRestaurantIds.length} active restaurants');

                              if (allProducts.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(Sizes.s32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.fastfood_outlined,
                                          size: Sizes.s64,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: Sizes.s16),
                                        Text(
                                          'No products available in this category',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: Sizes.s8),
                                        Text(
                                          'Category: "${widget.categoryName}"',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: Sizes.s12,
                                  mainAxisSpacing: Sizes.s16,
                                ),
                                itemCount: allProducts.length,
                                itemBuilder: (context, index) {
                                  return AnimatedListItem(
                                    index: index,
                                    child: _buildFoodItemCard(allProducts[index], context),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Open Restaurants Section
                      Text(
                        'Open Restaurants',
                        style: AppTextStyles.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.s24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Restaurants List - Show restaurants that have products in this category
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseService.firestore
                            .collection('products')
                            .snapshots(),
                        builder: (context, productsSnapshot) {
                          if (productsSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(Sizes.s16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          // Get unique restaurant IDs that have products in this category
                          final categoryNameLower = widget.categoryName.toLowerCase().trim();
                          final restaurantIdsWithProducts = <String>{};

                          if (productsSnapshot.hasData) {
                            for (final doc in productsSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final productCategoryName =
                                  (data['categoryName'] as String? ?? '').toLowerCase().trim();
                              final isActive = data['isActive'] ?? true;
                              final isAvailable = data['isAvailable'] ?? true;

                              if (productCategoryName == categoryNameLower &&
                                  isActive &&
                                  isAvailable) {
                                final restaurantId = data['restaurantId'] as String?;
                                if (restaurantId != null) {
                                  restaurantIdsWithProducts.add(restaurantId);
                                }
                              }
                            }
                          }

                          if (restaurantIdsWithProducts.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(Sizes.s16),
                                child: Text(
                                  'No restaurants available for this category',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Fetch restaurants that have products in this category
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseService.firestore
                                .collection('restaurants')
                                .where(FieldPath.documentId, whereIn: restaurantIdsWithProducts.toList())
                                .where('isActive', isEqualTo: true)
                                .where('isOpen', isEqualTo: true)
                                .snapshots(),
                            builder: (context, restaurantsSnapshot) {
                              if (restaurantsSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(Sizes.s16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (restaurantsSnapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(Sizes.s16),
                                    child: Text(
                                      'Error: ${restaurantsSnapshot.error}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (!restaurantsSnapshot.hasData ||
                                  restaurantsSnapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(Sizes.s16),
                                    child: Text(
                                      'No restaurants available for this category',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final restaurants = restaurantsSnapshot.data!.docs
                                  .map((doc) => Restaurant.fromFirestore(
                                        doc.data() as Map<String, dynamic>,
                                        doc.id,
                                      ))
                                  .toList()
                                ..sort((a, b) => b.rating.compareTo(a.rating));

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: restaurants.length,
                                itemBuilder: (context, index) {
                                  return AnimatedListItem(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: Sizes.s16),
                                      child: _buildRestaurantCard(
                                        restaurants[index],
                                        context,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: Sizes.s24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
      child: Row(
        children: [
          // Back Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                TablerIconsHelper.arrowLeft,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Category Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Sizes.s12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.categoryName.toUpperCase(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    TablerIconsHelper.chevronDown,
                    size: Sizes.s16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Search Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(TablerIconsHelper.search, color: Colors.white, size: Sizes.s20),
              onPressed: () {
                Navigator.pushNamed(context, Routes.search);
              },
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s8),

          // Filter Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                TablerIconsHelper.filter,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemCard(FoodItem item, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.itemDetail, arguments: item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Sizes.s16)),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: double.infinity,
                height: Sizes.s136,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: Sizes.s136,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: Sizes.s136,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(Sizes.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Sizes.s4),

                  // Restaurant Name
                  Text(
                    item.restaurantName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Sizes.s8),

                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.basePrice.toInt()}',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _addToCart(item),
                        child: Container(
                          width: Sizes.s32,
                          height: Sizes.s32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            TablerIconsHelper.plus,
                            color: Colors.white,
                            size: Sizes.s16,
                          ),
                        ),
                      ),
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

  Widget _buildRestaurantCard(Restaurant restaurant, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.restaurantView, arguments: restaurant);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Sizes.s16),
                bottomLeft: Radius.circular(Sizes.s16),
              ),
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
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
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s4),

                    // Cuisines
                    Text(
                      restaurant.cuisines,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s8),

                    // Rating, Delivery Cost, Delivery Time
                    Row(
                      children: [
                        const Icon(
                          TablerIconsHelper.star,
                          size: Sizes.s14,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: Sizes.s4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: Sizes.s12),
                        Icon(
                          TablerIconsHelper.delivery,
                          size: Sizes.s14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: Sizes.s4),
                        Text(
                          restaurant.deliveryCost,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: Sizes.s12),
                        Icon(
                          TablerIconsHelper.time,
                          size: Sizes.s14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: Sizes.s4),
                        Text(
                          restaurant.deliveryTime,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
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

  void _addToCart(FoodItem item) {
    final cartController = DependencyInjection.instance.cartController;

    // Get default variation and flavor if available
    String? defaultVariation;
    double finalPrice = item.basePrice;

    if (item.variations != null && item.variations!.isNotEmpty) {
      defaultVariation = item.variations!.first.name;
      finalPrice = item.variations!.first.price;
    }

    String? defaultFlavor;
    if (item.flavors != null && item.flavors!.isNotEmpty) {
      defaultFlavor = item.flavors!.first.name;
      finalPrice += item.flavors!.first.price;
    }

    // Create cart item
    final cartItem = CartItem(
      id: item.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: item.name,
      imageUrl: item.imageUrl,
      price: finalPrice,
      size: defaultVariation ?? 'Regular',
      quantity: 1,
      selectedVariation: defaultVariation,
      selectedFlavor: defaultFlavor,
      productId: item.id,
      restaurantId: item.restaurantId,
      restaurantName: item.restaurantName,
      basePrice: item.basePrice,
    );

    // Add to cart
    cartController.addToCart(cartItem);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.name} to cart'),
        backgroundColor: const Color(0xFFFF6B35),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, Routes.cart);
          },
        ),
      ),
    );
  }
}
