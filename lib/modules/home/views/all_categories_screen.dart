import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/home/models/category_model.dart';
import 'package:downtown/modules/widgets/category_item.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(title: 'All Categories'),
            
            // Categories Grid
            Expanded(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: Sizes.s64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'Error loading categories',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          Text(
                            '${snapshot.error}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
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
                            Icons.category_outlined,
                            size: Sizes.s64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'No categories available',
                            style: AppTextStyles.bodyMedium.copyWith(
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

                  final categories = snapshot.data!.docs
                      .map((doc) => CategoryModel.fromFirestore(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList()
                    ..sort((a, b) {
                      // Sort by order if available, then by name
                      if (a.order != null && b.order != null) {
                        return a.order!.compareTo(b.order!);
                      } else if (a.order != null) {
                        return -1;
                      } else if (b.order != null) {
                        return 1;
                      }
                      return a.name.compareTo(b.name);
                    });

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: Sizes.s16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: Sizes.s16,
                        mainAxisSpacing: Sizes.s16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final categoryModel = categories[index];
                        final category = Category(
                          name: categoryModel.name,
                          imageUrl: categoryModel.imageUrl,
                          isSelected: false,
                        );
                        return AnimatedListItem(
                          index: index,
                          child: CategoryItem(
                            category: category,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.categoryDetail,
                                arguments: category.name,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
