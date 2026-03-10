import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/modules/home/models/category_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/modules/admin/views/create_edit_category_screen.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _deleteCategory(BuildContext context, CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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
            .collection('categories')
            .doc(category.id)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting category: $e');
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

  void _editCategory(BuildContext context, CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditCategoryScreen(category: category),
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
              title: 'Categories',
              showBackButton: false,
            ),

            // Categories List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection('categories')
                    .orderBy('order', descending: false)
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

                  final categories = snapshot.data?.docs
                          .map((doc) => CategoryModel.fromFirestore(
                                doc.data() as Map<String, dynamic>,
                                doc.id,
                              ))
                          .toList() ??
                      [];

                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category,
                            size: Sizes.s64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'No categories yet',
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
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return AnimatedListItem(
                        index: index,
                        child: _buildCategoryCard(context, category),
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
              builder: (context) => const CreateEditCategoryScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      child: InkWell(
        onTap: () => _editCategory(context, category),
        borderRadius: BorderRadius.circular(Sizes.s12),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.s12),
          child: Row(
            children: [
              // Category Image
              ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.s8),
                child: category.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        width: Sizes.s60,
                        height: Sizes.s60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: Sizes.s60,
                          height: Sizes.s60,
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: Sizes.s60,
                          height: Sizes.s60,
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: Icon(
                            TablerIconsHelper.category,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Container(
                        width: Sizes.s60,
                        height: Sizes.s60,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Icon(
                          TablerIconsHelper.category,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
              ),
              const SizedBox(width: Sizes.s16),

              // Category Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sizes.s8,
                            vertical: Sizes.s4,
                          ),
                          decoration: BoxDecoration(
                            color: category.isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Sizes.s4),
                          ),
                          child: Text(
                            category.isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.label.copyWith(
                              color: category.isActive ? Colors.green : Colors.red,
                              fontSize: Sizes.s10,
                            ),
                          ),
                        ),
                        const SizedBox(width: Sizes.s8),
                        Text(
                          'Order: ${category.order}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCategory(context, category);
                  } else if (value == 'delete') {
                    _deleteCategory(context, category);
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
            ],
          ),
        ),
      ),
    );
  }
}
