import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/modules/home/models/category_model.dart';
import 'package:food_flow_app/modules/widgets/top_navigation_bar.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();

  File? _categoryImage;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isActive = true;
  CategoryModel? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _categoryImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile, String path) async {
    try {
      final ref = FirebaseService.storage.ref().child(path);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _clearForm() {
    _nameController.clear();
    _orderController.clear();
    setState(() {
      _categoryImage = null;
      _isActive = true;
      _editingCategory = null;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryImage == null && _editingCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      String? imageUrl;

      // Upload image if new image is selected
      if (_categoryImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        imageUrl = await _uploadImageToFirebase(
          _categoryImage!,
          'categories/category_$timestamp.jpg',
        );

        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      } else if (_editingCategory != null) {
        // Use existing image if editing
        imageUrl = _editingCategory!.imageUrl;
      }

      final categoryData = {
        'name': _nameController.text.trim(),
        'imageUrl': imageUrl!,
        if (_orderController.text.trim().isNotEmpty)
          'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'isActive': _isActive,
        if (_editingCategory == null) 'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      if (_editingCategory != null) {
        // Update existing category
        await FirebaseService.firestore
            .collection('categories')
            .doc(_editingCategory!.id)
            .update(categoryData);
      } else {
        // Create new category
        await FirebaseService.firestore
            .collection('categories')
            .add(categoryData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingCategory == null
                ? 'Category created successfully!'
                : 'Category updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      debugPrint('Error saving category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _editCategory(CategoryModel category) async {
    setState(() {
      _editingCategory = category;
      _nameController.text = category.name;
      _orderController.text = category.order?.toString() ?? '';
      _isActive = category.isActive;
      _categoryImage = null; // Don't load existing image, user can change it
    });
    // Scroll to form
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
              title: _editingCategory == null
                  ? 'Manage Categories'
                  : 'Edit Category',
              showBackButton: true,
            ),

            // Content
            Expanded(
              child: Row(
                children: [
                  // Categories List
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        border: Border(
                          right: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(Sizes.s16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Categories',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_editingCategory != null)
                                  TextButton(
                                    onPressed: _clearForm,
                                    child: const Text('New Category'),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseService.firestore
                                  .collection('categories')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No categories yet',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Sizes.s8,
                                  ),
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    return Card(
                                      margin: const EdgeInsets.only(
                                        bottom: Sizes.s8,
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: category.imageUrl
                                                  .startsWith('http')
                                              ? NetworkImage(category.imageUrl)
                                              : null,
                                          child: category.imageUrl
                                                  .startsWith('http')
                                              ? null
                                              : const Icon(Icons.category),
                                        ),
                                        title: Text(category.name),
                                        subtitle: Text(
                                          category.isActive
                                              ? 'Active'
                                              : 'Inactive',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () =>
                                                  _editCategory(category),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _deleteCategory(category),
                                            ),
                                          ],
                                        ),
                                        selected: _editingCategory?.id ==
                                            category.id,
                                        selectedTileColor: const Color(0xFFFF6B35)
                                            .withOpacity(0.1),
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
                  ),

                  // Form
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Sizes.s16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Category Image
                            Text(
                              'Category Image *',
                              style: AppTextStyles.heading3.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Sizes.s12),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(Sizes.s16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: _categoryImage == null &&
                                        _editingCategory == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: Sizes.s48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          ),
                                          const SizedBox(height: Sizes.s8),
                                          Text(
                                            'Tap to add image',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(Sizes.s16),
                                        child: _categoryImage != null
                                            ? Image.file(
                                                _categoryImage!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 150,
                                              )
                                            : Image.network(
                                                _editingCategory!.imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 150,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.error,
                                                    size: Sizes.s48,
                                                  );
                                                },
                                              ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: Sizes.s24),

                            // Category Name
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category Name *',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: Sizes.s8),
                                CustomTextField(
                                  controller: _nameController,
                                  hintText: 'e.g., Burger, Pizza, Sushi',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Category name is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: Sizes.s16),

                            // Order
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order (Optional)',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: Sizes.s8),
                                CustomTextField(
                                  controller: _orderController,
                                  hintText: 'Display order (number)',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),

                            const SizedBox(height: Sizes.s24),

                            // Is Active Toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Category is Active',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Switch(
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() {
                                      _isActive = value;
                                    });
                                  },
                                  activeColor: const Color(0xFFFF6B35),
                                ),
                              ],
                            ),

                            const SizedBox(height: Sizes.s32),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: Sizes.s56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Sizes.s12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? _isUploading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: Sizes.s20,
                                                height: Sizes.s20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: Sizes.s12),
                                              Text(
                                                'Uploading image...',
                                                style: AppTextStyles
                                                    .buttonLargeBold
                                                    .copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox(
                                            width: Sizes.s20,
                                            height: Sizes.s20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                    : Text(
                                        _editingCategory == null
                                            ? 'Create Category'
                                            : 'Update Category',
                                        style: AppTextStyles.buttonLargeBold
                                            .copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: Sizes.s32),
                          ],
                        ),
                      ),
                    ),
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
