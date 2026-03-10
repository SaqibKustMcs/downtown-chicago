import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:downtown/modules/widgets/restaurant_card.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/modules/admin/views/create_restaurant_screen.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AllRestaurantsScreen extends StatefulWidget {
  const AllRestaurantsScreen({super.key});

  @override
  State<AllRestaurantsScreen> createState() => _AllRestaurantsScreenState();
}

class _AllRestaurantsScreenState extends State<AllRestaurantsScreen> {
  final _authController = DependencyInjection.instance.authController;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _checkAdminStatus() {
    final currentUser = _authController.currentUser;
    _isAdmin = currentUser?.userType == UserType.admin;
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {
        _checkAdminStatus();
      });
    }
  }

  Future<void> _deleteRestaurant(Restaurant restaurant) async {
    if (restaurant.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: Text('Are you sure you want to delete "${restaurant.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.firestore
            .collection('restaurants')
            .doc(restaurant.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting restaurant: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editRestaurant(Restaurant restaurant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRestaurantScreen(restaurant: restaurant),
      ),
    );
    if (result == true && mounted) {
      // Restaurant was updated, refresh is automatic with StreamBuilder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(title: 'All Restaurants'),

            // Restaurants List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection('restaurants')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: Sizes.s48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'Error loading restaurants',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: Sizes.s64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'No restaurants available',
                            style: AppTextStyles.heading3.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final restaurants = snapshot.data!.docs
                      .map((doc) => Restaurant.fromFirestore(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList()
                    ..sort((a, b) => b.rating.compareTo(a.rating));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sizes.s12,
                      vertical: Sizes.s16,
                    ),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return AnimatedListItem(
                        index: index,
                        child: _buildRestaurantCardWithActions(restaurant),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCardWithActions(Restaurant restaurant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = Theme.of(context).colorScheme.surface.withOpacity(isDark ? 0.72 : 0.92);
    final iconFg = Theme.of(context).colorScheme.onSurface.withOpacity(isDark ? 0.92 : 0.75);
    final iconBorder = Theme.of(context).colorScheme.onSurface.withOpacity(isDark ? 0.18 : 0.10);
    return Stack(
      children: [
        RestaurantCardHorizontal(restaurant: restaurant),
        if (_isAdmin)
          Positioned(
            top: Sizes.s8,
            right: Sizes.s8,
            child: PopupMenuButton<String>(
              tooltip: 'Restaurant options',
              color: Theme.of(context).cardColor,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.s12),
                side: BorderSide(color: iconBorder),
              ),
              icon: DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: iconBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                      blurRadius: Sizes.s10,
                      offset: const Offset(0, Sizes.s4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Sizes.s8),
                  child: Icon(
                    Icons.more_vert,
                    size: Sizes.s18,
                    color: iconFg,
                  ),
                ),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _editRestaurant(restaurant);
                } else if (value == 'delete') {
                  _deleteRestaurant(restaurant);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: Sizes.s18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: Sizes.s8),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete,
                        size: Sizes.s18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: Sizes.s8),
                      Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
