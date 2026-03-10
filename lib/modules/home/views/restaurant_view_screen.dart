import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/models/food_item_model.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:downtown/models/cart_item_model.dart';
import 'package:downtown/modules/reviews/views/restaurant_reviews_screen.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/modules/checkout/controllers/cart_controller.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class RestaurantViewScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantViewScreen({super.key, required this.restaurant});

  @override
  State<RestaurantViewScreen> createState() => _RestaurantViewScreenState();
}

class _RestaurantViewScreenState extends State<RestaurantViewScreen> {
  String? _selectedCategory;
  bool _hasUserSelectedCategory = false; // Track if user has explicitly selected a category
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // Get banner images from restaurant or use main image
  List<String> get _bannerImages {
    if (widget.restaurant.bannerImages != null && widget.restaurant.bannerImages!.isNotEmpty) {
      return widget.restaurant.bannerImages!;
    }
    return [widget.restaurant.imageUrl];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Image Banner with Overlay Buttons
          _buildImageBannerWithOverlay(context),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Information
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Sizes.s8),

                        // See all reviews button
                        TextButton.icon(
                          onPressed: () {
                            if (widget.restaurant.id == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantReviewsScreen(
                                  restaurantId: widget.restaurant.id!,
                                  restaurantName: widget.restaurant.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review_outlined, size: Sizes.s18),
                          label: const Text('See all reviews'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: Sizes.s16),

                        // Open/Closed Status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Sizes.s12,
                                vertical: Sizes.s6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.restaurant.isCurrentlyOpen
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Sizes.s8),
                                border: Border.all(
                                  color: widget.restaurant.isCurrentlyOpen
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: Sizes.s8,
                                    height: Sizes.s8,
                                    decoration: BoxDecoration(
                                      color: widget.restaurant.isCurrentlyOpen
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: Sizes.s6),
                                  Text(
                                    widget.restaurant.isCurrentlyOpen ? 'Open Now' : 'Closed',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: widget.restaurant.isCurrentlyOpen
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.restaurant.formattedOpeningHours != null) ...[
                              const SizedBox(height: Sizes.s8),
                              Row(
                                children: [
                                  Icon(
                                    TablerIconsHelper.clock,
                                    size: Sizes.s14,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: Sizes.s6),
                                  Text(
                                    widget.restaurant.formattedOpeningHours!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: Sizes.s16),

                        // Rating, Delivery Cost, Delivery Time
                        Row(
                          children: [
                            RatingStarsWidget(rating: widget.restaurant.rating, size: Sizes.s18),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              widget.restaurant.rating.toStringAsFixed(1),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              '(${widget.restaurant.totalRatings})',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: Sizes.s16),
                            const Icon(
                              TablerIconsHelper.delivery,
                              color: Color(0xFFFF6B35),
                              size: Sizes.s20,
                            ),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              widget.restaurant.deliveryCost,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: Sizes.s16),
                            const Icon(
                              TablerIconsHelper.time,
                              color: Color(0xFFFF6B35),
                              size: Sizes.s20,
                            ),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              widget.restaurant.deliveryTime,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sizes.s16),

                        // Restaurant Name
                        Text(
                          widget.restaurant.name,
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: Sizes.s20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: Sizes.s12),

                        // Description
                        if (widget.restaurant.description != null &&
                            widget.restaurant.description!.isNotEmpty)
                          Text(
                            widget.restaurant.description!,
                            style: AppTextStyles.bodyLargeSecondary.copyWith(
                              fontSize: Sizes.s14,
                              height: 1.5,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        const SizedBox(height: Sizes.s24),

                        // Fetch products from Firestore - products collection
                        StreamBuilder<QuerySnapshot>(
                          stream: widget.restaurant.id != null
                              ? FirebaseService.firestore
                                    .collection('products')
                                    .where('restaurantId', isEqualTo: widget.restaurant.id!)
                                    .where('isActive', isEqualTo: true)
                                    .where('isAvailable', isEqualTo: true)
                                    .snapshots()
                              : Stream<QuerySnapshot>.empty(),
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
                                  padding: const EdgeInsets.all(Sizes.s16),
                                  child: Text(
                                    'Error loading products: ${productsSnapshot.error}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (!productsSnapshot.hasData || productsSnapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(Sizes.s32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.fastfood_outlined,
                                        size: Sizes.s64,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: Sizes.s16),
                                      Text(
                                        'No products available',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Get all products and sort by displayOrder
                            final allProducts =
                                productsSnapshot.data!.docs
                                    .map(
                                      (doc) => FoodItem.fromFirestore(
                                        doc.data() as Map<String, dynamic>,
                                        doc.id,
                                      ),
                                    )
                                    .toList()
                                  ..sort((a, b) {
                                    // First sort by displayOrder, then by name
                                    final orderCompare = a.displayOrder.compareTo(b.displayOrder);
                                    if (orderCompare != 0) return orderCompare;
                                    return a.name.compareTo(b.name);
                                  });

                            // Separate popular products
                            final popularProducts = allProducts
                                .where((product) => product.isPopular)
                                .toList();

                            // Get unique categories from products
                            final categories =
                                allProducts
                                    .map((product) => product.categoryName)
                                    .whereType<String>()
                                    .where((name) => name.isNotEmpty)
                                    .toSet()
                                    .toList()
                                  ..sort();

                            // Default is "All" (_selectedCategory == null); no auto-select of first category

                            // Filter products by selected category
                            final filteredProducts = _selectedCategory == null
                                ? allProducts
                                : allProducts
                                      .where((product) => product.categoryName == _selectedCategory)
                                      .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Categories - Add "All" option
                                if (categories.isNotEmpty) ...[
                                  SizedBox(
                                    height: Sizes.s40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.length + 1, // +1 for "All" option
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          // "All" option
                                          final isSelected = _selectedCategory == null;
                                          return AnimatedListItem(
                                            index: index,
                                            delay: const Duration(milliseconds: 30),
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: Sizes.s12),
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedCategory = null;
                                                    _hasUserSelectedCategory =
                                                        true; // Mark that user has made a selection
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: Sizes.s20,
                                                    vertical: Sizes.s8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(0xFFFF6B35)
                                                        : Theme.of(context).brightness ==
                                                              Brightness.dark
                                                        ? Colors.grey.shade800
                                                        : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(Sizes.s20),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'All',
                                                      style: AppTextStyles.bodySmall.copyWith(
                                                        fontSize: Sizes.s12,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Theme.of(
                                                                context,
                                                              ).colorScheme.onSurface,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final category = categories[index - 1];
                                        final isSelected = category == _selectedCategory;
                                        return AnimatedListItem(
                                          index: index,
                                          delay: const Duration(milliseconds: 30),
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: index < categories.length ? Sizes.s12 : 0,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedCategory = category;
                                                  _hasUserSelectedCategory =
                                                      true; // Mark that user has made a selection
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: Sizes.s20,
                                                  vertical: Sizes.s8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFFFF6B35)
                                                      : Theme.of(context).brightness ==
                                                            Brightness.dark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(Sizes.s20),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    category,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      fontSize: Sizes.s12,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Theme.of(context).colorScheme.onSurface,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: Sizes.s24),
                                ],

                                // Popular Products Section (only show if there are popular products and "All" is selected)
                                if (popularProducts.isNotEmpty && _selectedCategory == null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Popular Products',
                                        style: AppTextStyles.heading3.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: Sizes.s18,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (popularProducts.length > 4)
                                        TextButton(
                                          onPressed: () {
                                            // Scroll to all products section or show all popular
                                          },
                                          child: Text(
                                            'See All',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: const Color(0xFFFF6B35),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: Sizes.s16),
                                  GridView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: Sizes.s12,
                                      mainAxisSpacing: Sizes.s16,
                                    ),
                                    itemCount: popularProducts.length > 4
                                        ? 4
                                        : popularProducts.length, // Show max 4 popular products
                                    itemBuilder: (context, index) {
                                      return AnimatedListItem(
                                        index: index,
                                        child: _buildFoodItemCard(popularProducts[index], context),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: Sizes.s32),
                                ],

                                // Category/All Products Heading
                                Text(
                                  _selectedCategory != null
                                      ? '$_selectedCategory (${filteredProducts.length})'
                                      : 'All Products (${allProducts.length})',
                                  style: AppTextStyles.heading3.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: Sizes.s16,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: Sizes.s16),

                                // Food Items Grid
                                if (filteredProducts.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(Sizes.s32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.fastfood_outlined,
                                            size: Sizes.s64,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: Sizes.s16),
                                          Text(
                                            'No products in this category',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,

                                      mainAxisExtent: 240,
                                      crossAxisSpacing: Sizes.s12,
                                      mainAxisSpacing: Sizes.s16,
                                    ),
                                    itemCount: filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      return AnimatedListItem(
                                        index: index,
                                        child: _buildFoodItemCard(filteredProducts[index], context),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: Sizes.s24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBannerWithOverlay(BuildContext context) {
    return Stack(
      children: [
        // Image Carousel
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(Sizes.s24),
            bottomRight: Radius.circular(Sizes.s24),
          ),
          child: SizedBox(
            height: Sizes.s240,
            child: PageView.builder(
              controller: _imagePageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _bannerImages[index],
                  width: double.infinity,
                  height: Sizes.s240,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: double.infinity,
                    height: Sizes.s240,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: Sizes.s240,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      size: Sizes.s64,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Overlay Buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Sizes.s12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                Container(
                  width: Sizes.s40,
                  height: Sizes.s40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: Sizes.s4,
                        offset: const Offset(0, Sizes.s2),
                      ),
                    ],
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

                // Menu Button
                // Container(
                //   width: Sizes.s40,
                //   height: Sizes.s40,
                //   decoration: BoxDecoration(
                //     color: Theme.of(context).cardColor,
                //     shape: BoxShape.circle,
                //     boxShadow: [
                //       BoxShadow(
                //         color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                //         blurRadius: Sizes.s4,
                //         offset: const Offset(0, Sizes.s2),
                //       ),
                //     ],
                //   ),
                //   child: IconButton(
                //     icon: Icon(TablerIconsHelper.menu, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
                //     onPressed: () {},
                //     padding: EdgeInsets.zero,
                //   ),
                // ),
              ],
            ),
          ),
        ),

        // Carousel Indicators
        Positioned(
          bottom: Sizes.s16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerImages.length,
              (index) => Container(
                width: _currentImageIndex == index ? Sizes.s24 : Sizes.s8,
                height: Sizes.s8,
                margin: const EdgeInsets.symmetric(horizontal: Sizes.s4),
                decoration: BoxDecoration(
                  color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(Sizes.s4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItemCard(FoodItem item, BuildContext context) {
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
              color: Theme.of(context).brightness == Brightness.dark
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
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
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: Sizes.s13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
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

                  // Price and Add Button/Quantity Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Show quantity badge if product is in cart, otherwise show add button
                      ListenableBuilder(
                        listenable: DependencyInjection.instance.cartController,
                        builder: (context, _) {
                          final cartController = DependencyInjection.instance.cartController;
                          final quantity = cartController.getProductQuantity(item.id);

                          if (quantity > 0) {
                            // Show quantity badge
                            return Container(
                              width: Sizes.s32,
                              height: Sizes.s32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  quantity.toString(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Sizes.s14,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Show add button
                            return GestureDetector(
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
                            );
                          }
                        },
                      ),

                      Text(
                        CurrencyFormatter.formatInt(item.basePrice),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.s14,
                          color: Theme.of(context).colorScheme.onSurface,
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

  void _addToCart(FoodItem item) {
    // Check if restaurant is currently open
    if (!widget.restaurant.isCurrentlyOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This restaurant is currently closed. Opening hours: ${widget.restaurant.formattedOpeningHours ?? "N/A"}',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
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

    // Show success message - compact and eye-catching like Foodpanda
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Row(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         const Icon(Icons.check_circle, color: Colors.white, size: Sizes.s20),
    //         const SizedBox(width: Sizes.s8),
    //         Flexible(
    //           child: Text(
    //             'Added to cart',
    //             style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
    //           ),
    //         ),
    //       ],
    //     ),
    //     backgroundColor: const Color(0xFFFF6B35),
    //     behavior: SnackBarBehavior.floating,
    //     margin: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
    //     duration: const Duration(seconds: 2),
    //     action: SnackBarAction(
    //       label: 'View',
    //       textColor: Colors.white,
    //       onPressed: () {
    //         Navigator.pushNamed(context, Routes.cart);
    //       },
    //     ),
    //   ),
    // );
  }
}
