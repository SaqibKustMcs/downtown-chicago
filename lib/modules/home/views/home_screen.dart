import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/modules/home/models/category_model.dart';
import 'package:food_flow_app/models/restaurant_model.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class Category {
  final String name;
  final String imageUrl;
  final bool isSelected;

  const Category({required this.name, required this.imageUrl, this.isSelected = false});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedCategoryName;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            RepaintBoundary(child: _buildHeader(context)),

            // Content
            Expanded(
              child: RepaintBoundary(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sizes.s16),

                      // Search Bar
                      RepaintBoundary(child: _buildSearchBar(context)),
                      const SizedBox(height: Sizes.s24),

                      // Categories Section
                      RepaintBoundary(child: _buildCategoriesSection(context)),
                      const SizedBox(height: Sizes.s24),

                      // Open Restaurants Section
                      RepaintBoundary(child: _buildRestaurantsSection(context)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
      child: Row(
        children: [
          // Delivery Location
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, Routes.locationPermission);
              },
              child: Row(
                children: [
                  Text(
                    'DELIVER TO',
                    style: AppTextStyles.label.copyWith(color: const Color(0xFFFF6B35), fontSize: Sizes.s10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: Sizes.s4),
                  Text(
                    'Halal Lab office',
                    style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                  ),
                  Icon(TablerIconsHelper.arrowDown, size: Sizes.s20, color: Theme.of(context).colorScheme.onSurface),
                ],
              ),
            ),
          ),

          // Notification Icon
          Stack(
            children: [
              IconButton(
                icon: Icon(TablerIconsHelper.bell, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s24),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.notifications);
                },
              ),
              Positioned(
                right: Sizes.s8,
                top: Sizes.s8,
                child: Container(
                  width: Sizes.s18,
                  height: Sizes.s18,
                  decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '3',
                      style: AppTextStyles.captionTiny.copyWith(color: Colors.white, fontSize: Sizes.s10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Cart Icon
          Stack(
            children: [
              IconButton(
                icon: Icon(TablerIconsHelper.shoppingBag, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s24),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.cart);
                },
              ),
              Positioned(
                right: Sizes.s8,
                top: Sizes.s8,
                child: Container(
                  width: Sizes.s18,
                  height: Sizes.s18,
                  decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '2',
                      style: AppTextStyles.captionTiny.copyWith(color: Colors.white, fontSize: Sizes.s10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.search);
      },
      child: Container(
        height: Sizes.s48,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: Sizes.s8,
              offset: const Offset(0, Sizes.s2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: Sizes.s16),
        child: Row(
          children: [
            Icon(TablerIconsHelper.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: Sizes.s20),
            const SizedBox(width: Sizes.s12),
            Text(
              'Search dishes, restaurants',
              style: AppTextStyles.bodyLargeSecondary.copyWith(fontSize: Sizes.s14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Categories',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.allCategories);
                },
                child: Row(
                  children: [
                    Text('See All', style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35))),
                    const SizedBox(width: Sizes.s4),
                    const Icon(TablerIconsHelper.arrowRight, size: Sizes.s12, color: Color(0xFFFF6B35)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sizes.s16),
        SizedBox(
          height: Sizes.s100,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection('categories')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No categories available',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }

              final categories = snapshot.data!.docs
                  .map((doc) => CategoryModel.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ))
                  .toList();

              // Sort by order if available, then by name
              categories.sort((a, b) {
                if (a.order != null && b.order != null) {
                  return a.order!.compareTo(b.order!);
                } else if (a.order != null) {
                  return -1;
                } else if (b.order != null) {
                  return 1;
                }
                return a.name.compareTo(b.name);
              });

              // Add "All" category at the beginning
              final allCategories = [
                const Category(name: 'All', imageUrl: '', isSelected: true),
                ...categories.map((cat) => Category(
                      name: cat.name,
                      imageUrl: cat.imageUrl,
                      isSelected: _selectedCategoryName == cat.name,
                    )),
              ];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s0),
                itemCount: allCategories.length,
                itemBuilder: (context, index) {
                  final category = allCategories[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index < allCategories.length - 1 ? Sizes.s16 : 0),
                    child: AnimatedListItem(
                      index: index,
                      delay: const Duration(milliseconds: 30),
                      child: _buildCategoryItem(category, context),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Category category, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (category.name == 'All') {
          setState(() {
            _selectedCategoryName = null;
          });
        } else {
          Navigator.pushNamed(context, Routes.categoryDetail, arguments: category.name);
        }
      },
      child: Container(
        width: Sizes.s80,
        decoration: BoxDecoration(
          color: category.isSelected ? const Color(0xFFFF6B35) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
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
                      color: category.isSelected ? Colors.white.withOpacity(0.2) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(Sizes.s8),
                    ),
                    child: Icon(TablerIconsHelper.apps, size: Sizes.s24, color: category.isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
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
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: Sizes.s40,
                        height: Sizes.s42,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Icon(Icons.error_outline, size: Sizes.s20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  ),
            const SizedBox(height: Sizes.s8),
            Text(
              category.name,
              style: AppTextStyles.bodySmall.copyWith(
                color: category.isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: category.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Open Restaurants',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.allRestaurants);
                },
                child: Row(
                  children: [
                    Text('See All', style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35))),
                    const SizedBox(width: Sizes.s4),
                    const Icon(TablerIconsHelper.arrowRight, size: Sizes.s12, color: Color(0xFFFF6B35)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sizes.s16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.firestore
              .collection('restaurants')
              .where('isActive', isEqualTo: true)
              .where('isOpen', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No restaurants available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            }

            final restaurants = snapshot.data!.docs
                .map((doc) => Restaurant.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList()
              ..sort((a, b) => b.rating.compareTo(a.rating)); // Sort by rating descending in memory

            // Limit to 10 after sorting
            final limitedRestaurants = restaurants.take(10).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Sizes.s0),
              itemCount: limitedRestaurants.length,
              itemBuilder: (context, index) => AnimatedListItem(
                index: index,
                child: _buildRestaurantCard(limitedRestaurants[index], context),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, Routes.restaurantView, arguments: restaurant);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: Sizes.s8,
              offset: const Offset(0, Sizes.s2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s16), topRight: Radius.circular(Sizes.s16)),
              child: Container(
                height: Sizes.s160,
                width: double.infinity,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey[300],
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  memCacheHeight: 400,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35), strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey[300],
                    child: Icon(TablerIconsHelper.restaurant, size: Sizes.s64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
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
                  Text(
                    restaurant.cuisines,
                    style: AppTextStyles.bodySmallSecondary.copyWith(fontSize: Sizes.s12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: Sizes.s12),
                  Row(
                    children: [
                      const Icon(TablerIconsHelper.star, color: Color(0xFFFF6B35), size: Sizes.s16),
                      const SizedBox(width: Sizes.s4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(width: Sizes.s16),
                      const Icon(TablerIconsHelper.delivery, color: Color(0xFFFF6B35), size: Sizes.s16),
                      const SizedBox(width: Sizes.s4),
                      Text(
                        restaurant.deliveryCost,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(width: Sizes.s16),
                      const Icon(TablerIconsHelper.time, color: Color(0xFFFF6B35), size: Sizes.s16),
                      const SizedBox(width: Sizes.s4),
                      Text(
                        restaurant.deliveryTime,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
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
}
