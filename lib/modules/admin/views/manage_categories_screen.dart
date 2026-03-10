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

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  Future<void> _deleteCategory(CategoryModel category) async {
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting category: $e');
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

  Future<void> _editCategory(CategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditCategoryScreen(category: category),
      ),
    );
    if (result == true && mounted) {
      // Category was updated, refresh is automatic with StreamBuilder
    }
  }

  Future<void> _createCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditCategoryScreen(),
      ),
    );
    if (result == true && mounted) {
      // Category was created, refresh is automatic with StreamBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Categories',
              showBackButton: true,
            ),

            // Categories List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection('categories')
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
                            'Error loading categories',
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
                          const SizedBox(height: Sizes.s8),
                          Text(
                            'Tap the + button to create your first category',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final categories = snapshot.data!.docs
                      .map((doc) => CategoryModel.fromFirestore(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList()
                    ..sort((a, b) {
                      if (a.order != null && b.order != null) {
                        return a.order!.compareTo(b.order!);
                      } else if (a.order != null) {
                        return -1;
                      } else if (b.order != null) {
                        return 1;
                      }
                      return a.name.compareTo(b.name);
                    });

                  return ListView.builder(
                    padding: const EdgeInsets.all(Sizes.s16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return AnimatedListItem(
                        index: index,
                        child: _buildCategoryCard(
                          category: category,
                          isDark: isDark,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Category',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required CategoryModel category,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: Sizes.s4,
            offset: const Offset(0, Sizes.s2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editCategory(category),
          borderRadius: BorderRadius.circular(Sizes.s16),
          child: Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Row(
              children: [
                // Category Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                  child: CachedNetworkImage(
                    imageUrl: category.imageUrl,
                    width: Sizes.s80,
                    height: Sizes.s80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: Sizes.s80,
                      height: Sizes.s80,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: Sizes.s80,
                      height: Sizes.s80,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: Icon(
                        Icons.category,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Sizes.s8),
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
                              borderRadius: BorderRadius.circular(Sizes.s8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: Sizes.s6,
                                  height: Sizes.s6,
                                  decoration: BoxDecoration(
                                    color: category.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: Sizes.s4),
                                Text(
                                  category.isActive ? 'Active' : 'Inactive',
                                  style: AppTextStyles.captionTiny.copyWith(
                                    color: category.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (category.order != null) ...[
                            const SizedBox(width: Sizes.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Sizes.s8,
                                vertical: Sizes.s4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(Sizes.s8),
                              ),
                              child: Text(
                                'Order: ${category.order}',
                                style: AppTextStyles.captionTiny.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCategory(category);
                    } else if (value == 'delete') {
                      _deleteCategory(category);
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
