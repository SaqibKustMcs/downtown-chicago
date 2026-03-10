import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/favorites/controllers/favorites_controller.dart';
import 'package:downtown/modules/checkout/controllers/cart_controller.dart';
import 'package:downtown/models/food_item_model.dart';
import 'package:downtown/models/cart_item_model.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class ItemDetailScreen extends StatefulWidget {
  final FoodItem foodItem;

  const ItemDetailScreen({super.key, required this.foodItem});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  String? _selectedVariation;
  String? _selectedFlavor;
  late final FavoritesController _favoritesController;
  bool _isFavorite = false;

  // Get images for slider (use imageUrls if available, otherwise use single imageUrl)
  List<String> get _images {
    if (widget.foodItem.imageUrls != null && widget.foodItem.imageUrls!.isNotEmpty) {
      return widget.foodItem.imageUrls!;
    }
    return [widget.foodItem.imageUrl];
  }

  // Calculate current price based on base price, variation, and flavor
  double get _currentPrice {
    double price = widget.foodItem.basePrice;

    // Add variation price if selected
    if (_selectedVariation != null && widget.foodItem.variations != null) {
      final variation = widget.foodItem.variations!.firstWhere((v) => v.name == _selectedVariation, orElse: () => widget.foodItem.variations!.first);
      price = variation.price;
    }

    // Add flavor price if selected
    if (_selectedFlavor != null && widget.foodItem.flavors != null) {
      final flavor = widget.foodItem.flavors!.firstWhere((f) => f.name == _selectedFlavor, orElse: () => widget.foodItem.flavors!.first);
      price += flavor.price;
    }

    return price;
  }

  @override
  void initState() {
    super.initState();
    _favoritesController = DependencyInjection.instance.favoritesController;
    _favoritesController.addListener(_onFavoritesChanged);

    // Check if item is favorite
    if (widget.foodItem.id != null) {
      _isFavorite = _favoritesController.isFavorite(widget.foodItem.id!);
    }

    // Set default variation if available
    if (widget.foodItem.variations != null && widget.foodItem.variations!.isNotEmpty) {
      _selectedVariation = widget.foodItem.variations!.first.name;
    }
    // Don't select flavor by default - let user choose
  }

  @override
  void dispose() {
    _favoritesController.removeListener(_onFavoritesChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted && widget.foodItem.id != null) {
      setState(() {
        _isFavorite = _favoritesController.isFavorite(widget.foodItem.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopNavigation(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Slider
                    AnimatedCard(delay: const Duration(milliseconds: 100), child: _buildImageSlider()),

                    // Item Details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Sizes.s16),

                          // Item Name
                          AnimatedListItem(
                            index: 0,
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              widget.foodItem.name,
                              style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold, fontSize: Sizes.s28, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),

                          // Restaurant Name
                          AnimatedListItem(
                            index: 1,
                            delay: const Duration(milliseconds: 250),
                            child: Text(widget.foodItem.restaurantName, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ),
                          const SizedBox(height: Sizes.s16),

                          // Price
                          AnimatedListItem(
                            index: 2,
                            delay: const Duration(milliseconds: 300),
                            child: Text(
                              CurrencyFormatter.formatInt(_currentPrice),
                              style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.bold, fontSize: Sizes.s32, color: const Color(0xFFFF6B35)),
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          // Product already in cart message
                          ListenableBuilder(
                            listenable: DependencyInjection.instance.cartController,
                            builder: (context, _) {
                              final cartController = DependencyInjection.instance.cartController;
                              final isInCart = cartController.isProductInCart(widget.foodItem.id);

                              if (isInCart) {
                                return AnimatedListItem(
                                  index: 2,
                                  delay: const Duration(milliseconds: 300),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shopping_cart, size: Sizes.s16, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: Sizes.s4),
                                      Text(
                                        'Product already in your cart',
                                        style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: Sizes.s12),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: Sizes.s24),

                          // Description
                          if (widget.foodItem.description != null) ...[
                            AnimatedListItem(
                              index: 3,
                              delay: const Duration(milliseconds: 350),
                              child: Text(
                                'Description',
                                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                            const SizedBox(height: Sizes.s8),
                            AnimatedListItem(
                              index: 4,
                              delay: const Duration(milliseconds: 400),
                              child: Text(
                                widget.foodItem.description!,
                                style: AppTextStyles.bodyLargeSecondary.copyWith(fontSize: Sizes.s14, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ),
                            const SizedBox(height: Sizes.s24),
                          ],

                          // Variations (Size)
                          if (widget.foodItem.variations != null && widget.foodItem.variations!.isNotEmpty)
                            AnimatedListItem(
                              index: 5,
                              delay: const Duration(milliseconds: 450),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Size',
                                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: Sizes.s12),
                                  _buildVariationSelector(),
                                ],
                              ),
                            ),
                          if (widget.foodItem.variations != null && widget.foodItem.variations!.isNotEmpty) const SizedBox(height: Sizes.s24),

                          // Flavors
                          if (widget.foodItem.flavors != null && widget.foodItem.flavors!.isNotEmpty)
                            AnimatedListItem(
                              index: 6,
                              delay: const Duration(milliseconds: 500),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Flavor',
                                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: Sizes.s12),
                                  _buildFlavorSelector(),
                                ],
                              ),
                            ),
                          if (widget.foodItem.flavors != null && widget.foodItem.flavors!.isNotEmpty) const SizedBox(height: Sizes.s24),
                          const SizedBox(height: Sizes.s32), // Extra space for bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Bar with Quantity Controls and Add to Cart
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1), blurRadius: Sizes.s10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quantity Controls
            Container(
              decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(Sizes.s12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decrease Button
                  IconButton(
                    icon: Icon(TablerIconsHelper.minus, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                    padding: const EdgeInsets.all(Sizes.s12),
                    constraints: const BoxConstraints(minWidth: Sizes.s48, minHeight: Sizes.s48),
                  ),

                  // Quantity Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Sizes.s16),
                    child: Text(
                      _quantity.toString(),
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: Sizes.s18),
                    ),
                  ),

                  // Increase Button
                  IconButton(
                    icon: Icon(TablerIconsHelper.plus, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                    padding: const EdgeInsets.all(Sizes.s12),
                    constraints: const BoxConstraints(minWidth: Sizes.s48, minHeight: Sizes.s48),
                  ),
                ],
              ),
            ),

            const SizedBox(width: Sizes.s12),

            // Add to Cart Button
            Expanded(
              child: SizedBox(
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: () {
                    _addToCart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(TablerIconsHelper.shoppingCart, color: Colors.white, size: Sizes.s20),
                      const SizedBox(width: Sizes.s8),
                      Flexible(
                        child: Text(
                          'Add to Cart',
                          // 'Add to Cart - ${CurrencyFormatter.formatInt(_quantity * _currentPrice)}',
                          style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  Widget _buildVariationSelector() {
    if (widget.foodItem.variations == null || widget.foodItem.variations!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: Sizes.s12,
      runSpacing: Sizes.s12,
      children: widget.foodItem.variations!.map((variation) {
        final isSelected = _selectedVariation == variation.name;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedVariation = variation.name;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Sizes.s20, vertical: Sizes.s12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6B35)
                  : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(Sizes.s12),
              border: isSelected ? null : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variation.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: Sizes.s4),
                Text(
                  CurrencyFormatter.formatInt(variation.price),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white.withOpacity(0.8) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: Sizes.s12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlavorSelector() {
    if (widget.foodItem.flavors == null || widget.foodItem.flavors!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: Sizes.s12,
      runSpacing: Sizes.s12,
      children: widget.foodItem.flavors!.map((flavor) {
        final isSelected = _selectedFlavor == flavor.name;
        return GestureDetector(
          onTap: () {
            setState(() {
              // Toggle: if already selected, deselect it; otherwise select it
              _selectedFlavor = isSelected ? null : flavor.name;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Sizes.s20, vertical: Sizes.s12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6B35)
                  : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(Sizes.s12),
              border: isSelected ? null : Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flavor.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (flavor.price > 0) ...[
                  const SizedBox(width: Sizes.s8),
                  Text(
                    '+${CurrencyFormatter.formatInt(flavor.price)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white.withOpacity(0.8) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: Sizes.s12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(Sizes.s12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease Button
          IconButton(
            icon: Icon(TablerIconsHelper.minus, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              if (_quantity > 1) {
                setState(() {
                  _quantity--;
                });
              }
            },
          ),

          // Quantity Display
          Text(
            _quantity.toString(),
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),

          // Increase Button
          IconButton(
            icon: Icon(TablerIconsHelper.plus, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              setState(() {
                _quantity++;
              });
            },
          ),
        ],
      ),
    );
  }

  void _addToCart() {
    // Validate: require size (variation) if product has size options
    final hasVariations = widget.foodItem.variations != null && widget.foodItem.variations!.isNotEmpty;
    if (hasVariations && (_selectedVariation == null || _selectedVariation!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a size'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate: require flavor if product has flavor options
    final hasFlavors = widget.foodItem.flavors != null && widget.foodItem.flavors!.isNotEmpty;
    if (hasFlavors && (_selectedFlavor == null || _selectedFlavor!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a flavor'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cartController = DependencyInjection.instance.cartController;

    // Create cart item with selected variation and flavor
    final cartItem = CartItem(
      id: widget.foodItem.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.foodItem.name,
      imageUrl: widget.foodItem.imageUrl,
      price: _currentPrice,
      size: _selectedVariation ?? 'Regular',
      quantity: _quantity,
      selectedVariation: _selectedVariation,
      selectedFlavor: _selectedFlavor,
      productId: widget.foodItem.id,
      restaurantId: widget.foodItem.restaurantId,
      restaurantName: widget.foodItem.restaurantName,
      basePrice: widget.foodItem.basePrice,
    );

    // Add to cart
    cartController.addToCart(cartItem);

    // Navigate to cart screen
    Navigator.pushNamed(context, Routes.cart);
  }

  Future<void> _toggleFavorite() async {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add favorites'), backgroundColor: Colors.red));
      return;
    }

    if (widget.foodItem.id == null) {
      return;
    }

    final success = await _favoritesController.toggleFavorite(currentUser!.id!, widget.foodItem);

    if (success && mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? '${widget.foodItem.name} removed from favorites' : '${widget.foodItem.name} added to favorites',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTopNavigation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Back Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(TablerIconsHelper.arrowLeft, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const Spacer(),

          // Favorite Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(TablerIconsHelper.favorite, color: _isFavorite ? const Color(0xFFFF6B35) : Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
              onPressed: () => _toggleFavorite(),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    return SizedBox(
      height: Sizes.s312,
      child: Stack(
        children: [
          // PageView for Images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _images[index],
                width: double.infinity,
                height: Sizes.s312,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: Sizes.s312,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: Sizes.s312,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: Sizes.s64),
                ),
              );
            },
          ),

          // Page Indicator
          if (_images.length > 1)
            Positioned(
              bottom: Sizes.s16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (index) => Container(
                    width: _currentImageIndex == index ? Sizes.s24 : Sizes.s8,
                    height: Sizes.s8,
                    margin: const EdgeInsets.symmetric(horizontal: Sizes.s4),
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(Sizes.s4),
                      boxShadow: Theme.of(context).brightness == Brightness.dark ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: Sizes.s4)] : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
