import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/models/food_item_model.dart';
import 'package:food_flow_app/models/restaurant_model.dart';
import 'package:food_flow_app/models/cart_item_model.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _recentKeywords = ['Burger', 'Sandwich', 'Pizza', 'Sanwic'];
  Timer? _debounceTimer;

  List<FoodItem> _searchProducts = [];
  List<Restaurant> _searchRestaurants = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Listen to cart changes to update badge
    DependencyInjection.instance.cartController.addListener(_onCartChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    DependencyInjection.instance.cartController.removeListener(_onCartChanged);
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleClear() {
    _searchController.clear();
    setState(() {
      _searchProducts.clear();
      _searchRestaurants.clear();
      _hasSearched = false;
      _isSearching = false;
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchProducts.clear();
        _searchRestaurants.clear();
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchProducts.clear();
        _searchRestaurants.clear();
        _isSearching = false;
      });
      return;
    }

    try {
      final queryLower = query.toLowerCase();

      // Search products
      final productsSnapshot = await FirebaseService.firestore.collection('products').where('isActive', isEqualTo: true).where('isAvailable', isEqualTo: true).get();

      final products = productsSnapshot.docs.map((doc) => FoodItem.fromFirestore(doc.data(), doc.id)).where((product) {
        final nameMatch = product.name.toLowerCase().contains(queryLower);
        final categoryMatch = product.categoryName?.toLowerCase().contains(queryLower) ?? false;
        final restaurantMatch = product.restaurantName.toLowerCase().contains(queryLower);
        return nameMatch || categoryMatch || restaurantMatch;
      }).toList();

      // Search restaurants
      final restaurantsSnapshot = await FirebaseService.firestore.collection('restaurants').where('isActive', isEqualTo: true).get();

      final restaurants = restaurantsSnapshot.docs.map((doc) => Restaurant.fromFirestore(doc.data(), doc.id)).where((restaurant) {
        final nameMatch = restaurant.name.toLowerCase().contains(queryLower);
        final cuisinesMatch = restaurant.cuisines.toLowerCase().contains(queryLower);
        return nameMatch || cuisinesMatch;
      }).toList();

      if (mounted) {
        setState(() {
          _searchProducts = products;
          _searchRestaurants = restaurants;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: Sizes.s16),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: Sizes.s24),

              // Content
              Expanded(
                child: _hasSearched
                    ? _buildSearchResults()
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Keywords Section
                            _buildRecentKeywordsSection(),
                            const SizedBox(height: Sizes.s32),

                            // Suggested Restaurants Section
                            _buildSuggestedRestaurantsSection(),
                            const SizedBox(height: Sizes.s32),

                            // Popular Fast Food Section
                            _buildPopularFastFoodSection(),
                            const SizedBox(height: Sizes.s32),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Back Button
        IconButton(
          icon: Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s4, offset: const Offset(0, Sizes.s2))],
            ),
            child: Icon(TablerIconsHelper.arrowLeft, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: Sizes.s8),

        // Search Title
        Expanded(
          child: Text(
            'Search',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),

        // Cart Icon
        Builder(
          builder: (context) {
            final itemCount = DependencyInjection.instance.cartController.itemCount;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(TablerIconsHelper.shoppingBag, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s24),
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.cart);
                  },
                ),
                if (itemCount > 0)
                  Positioned(
                    right: Sizes.s8,
                    top: Sizes.s8,
                    child: Container(
                      width: Sizes.s18,
                      height: Sizes.s18,
                      decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: AppTextStyles.captionTiny.copyWith(color: Colors.white, fontSize: Sizes.s10),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: Sizes.s48,
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(Sizes.s12)),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Pizza',
          hintStyle: AppTextStyles.bodyLargeSecondary.copyWith(fontSize: Sizes.s14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          prefixIcon: Icon(TablerIconsHelper.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: Sizes.s20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Container(
                    width: Sizes.s20,
                    height: Sizes.s20,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(TablerIconsHelper.close, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: Sizes.s14),
                  ),
                  onPressed: _handleClear,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Sizes.s12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Sizes.s12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Sizes.s12), borderSide: BorderSide.none),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s12),
        ),
      ),
    );
  }

  Widget _buildRecentKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Keywords',
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: Sizes.s16),
        Wrap(
          spacing: Sizes.s12,
          runSpacing: Sizes.s12,
          children: _recentKeywords.asMap().entries.map((entry) {
            return AnimatedListItem(index: entry.key, delay: const Duration(milliseconds: 30), child: _buildKeywordChip(entry.value));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildKeywordChip(String keyword) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s20),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
      ),
      child: Text(keyword, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildSuggestedRestaurantsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore.collection('restaurants').where('isActive', isEqualTo: true).where('isOpen', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final restaurants = snapshot.data!.docs.map((doc) => Restaurant.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));

        final suggestedRestaurants = restaurants.take(3).toList();

        if (suggestedRestaurants.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested Restaurants',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: Sizes.s16),
            ...suggestedRestaurants.asMap().entries.map((entry) {
              final index = entry.key;
              final restaurant = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < suggestedRestaurants.length - 1 ? Sizes.s16 : 0),
                child: AnimatedListItem(
                  index: index,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.restaurantView, arguments: restaurant);
                    },
                    child: _buildRestaurantItem(name: restaurant.name, rating: restaurant.rating, imageUrl: restaurant.imageUrl),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildRestaurantItem({required String name, required double rating, required String imageUrl}) {
    return Row(
      children: [
        // Restaurant Image
        ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.s12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: Sizes.s80,
            height: Sizes.s80,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: Sizes.s80,
              height: Sizes.s80,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
            ),
            errorWidget: (context, url, error) => Container(
              width: Sizes.s80,
              height: Sizes.s80,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
              child: Icon(TablerIconsHelper.restaurant, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(width: Sizes.s16),

        // Restaurant Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: Sizes.s4),
              Row(
                children: [
                  const Icon(TablerIconsHelper.star, color: Color(0xFFFF6B35), size: Sizes.s16),
                  const SizedBox(width: Sizes.s4),
                  Text(
                    rating.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopularFastFoodSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore.collection('products').where('isActive', isEqualTo: true).where('isAvailable', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = snapshot.data!.docs.map((doc) => FoodItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

        final popularProducts = products.take(2).toList();

        if (popularProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Fast Food',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: Sizes.s16),
            ...popularProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < popularProducts.length - 1 ? Sizes.s16 : 0),
                child: AnimatedListItem(
                  index: index,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.itemDetail, arguments: product);
                    },
                    child: _buildFastFoodCard(foodName: product.name, restaurantName: product.restaurantName, imageUrl: product.imageUrl),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFastFoodCard({required String foodName, required String restaurantName, required String imageUrl}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), topRight: Radius.circular(Sizes.s16)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: Sizes.s160,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: Sizes.s160,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: Sizes.s160,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
                child: Icon(TablerIconsHelper.restaurant, size: Sizes.s64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          ),

          // Food Info
          Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodName,
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: Sizes.s4),
                Text(
                  restaurantName,
                  style: AppTextStyles.bodySmallSecondary.copyWith(fontSize: Sizes.s12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchProducts.isEmpty && _searchRestaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TablerIconsHelper.search, size: Sizes.s80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: Sizes.s24),
            Text('No results found', style: AppTextStyles.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: Sizes.s8),
            Text('Try searching for something else', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Products Section
          if (_searchProducts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.s0),
              child: Text(
                'Products (${_searchProducts.length})',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: Sizes.s16),
            ..._searchProducts.map((product) {
              return AnimatedListItem(
                index: _searchProducts.indexOf(product),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Sizes.s16),
                  child: _buildProductCard(product),
                ),
              );
            }),
            const SizedBox(height: Sizes.s24),
          ],

          // Restaurants Section
          if (_searchRestaurants.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.s0),
              child: Text(
                'Restaurants (${_searchRestaurants.length})',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: Sizes.s16),
            ..._searchRestaurants.map((restaurant) {
              return AnimatedListItem(
                index: _searchRestaurants.indexOf(restaurant),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Sizes.s16),
                  child: _buildRestaurantSearchCard(restaurant),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(FoodItem product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartController = DependencyInjection.instance.cartController;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.itemDetail, arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), bottomLeft: Radius.circular(Sizes.s16)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: Sizes.s120,
                height: Sizes.s120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: Sizes.s120,
                  height: Sizes.s120,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: Sizes.s120,
                  height: Sizes.s120,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(TablerIconsHelper.restaurant, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s4),
                    Text(
                      product.restaurantName,
                      style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.basePrice.toInt()}',
                          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF6B35)),
                        ),
                        GestureDetector(
                          onTap: () => _addToCart(product),
                          child: Container(
                            width: Sizes.s32,
                            height: Sizes.s32,
                            decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                            child: const Icon(TablerIconsHelper.plus, color: Colors.white, size: Sizes.s16),
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

  Widget _buildRestaurantSearchCard(Restaurant restaurant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.restaurantView, arguments: restaurant);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
        ),
        child: Row(
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), bottomLeft: Radius.circular(Sizes.s16)),
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl,
                width: Sizes.s120,
                height: Sizes.s120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: Sizes.s120,
                  height: Sizes.s120,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: Sizes.s120,
                  height: Sizes.s120,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(TablerIconsHelper.restaurant, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(width: Sizes.s16),

            // Restaurant Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s4),
                    Text(
                      restaurant.cuisines,
                      style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Sizes.s8),
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
                        Text(
                          restaurant.deliveryCost,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
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

    // Create cart item
    final cartItem = CartItem(
      id: item.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: item.name,
      imageUrl: item.imageUrl,
      price: finalPrice,
      size: defaultVariation ?? 'Regular',
      quantity: 1,
      selectedVariation: defaultVariation,
      selectedFlavor: null,
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
