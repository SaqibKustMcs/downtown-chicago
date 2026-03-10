import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:downtown/modules/widgets/restaurant_card.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/modules/admin/views/create_restaurant_screen.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AdminRestaurantsScreen extends StatelessWidget {
  const AdminRestaurantsScreen({super.key});

  Future<void> _deleteRestaurant(BuildContext context, Restaurant restaurant) async {
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

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting restaurant: $e');
        if (context.mounted) {
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

  void _editRestaurant(BuildContext context, Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRestaurantScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Restaurants',
              showBackButton: false,
            ),

            // Restaurants List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection('restaurants')
                    .where('isActive', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
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

                  final restaurants = snapshot.data?.docs
                          .map((doc) => Restaurant.fromFirestore(
                                doc.data() as Map<String, dynamic>,
                                doc.id,
                              ))
                          .toList() ??
                      [];

                  if (restaurants.isEmpty) {
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
                            'No restaurants yet',
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

                  return ListView.builder(
                    padding: const EdgeInsets.all(Sizes.s16),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return AnimatedListItem(
                        index: index,
                        child: Stack(
                          children: [
                            RestaurantCardHorizontal(restaurant: restaurant),
                            Positioned(
                              top: Sizes.s8,
                              right: Sizes.s8,
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                color: Theme.of(context).cardColor,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editRestaurant(context, restaurant);
                                  } else if (value == 'delete') {
                                    _deleteRestaurant(context, restaurant);
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
                                        Icon(
                                          Icons.delete,
                                          size: Sizes.s18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: Sizes.s8),
                                        const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRestaurantScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
