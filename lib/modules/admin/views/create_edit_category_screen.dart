import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/home/models/category_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class CreateEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const CreateEditCategoryScreen({
    super.key,
    this.category,
  });

  @override
  State<CreateEditCategoryScreen> createState() => _CreateEditCategoryScreenState();
}

class _CreateEditCategoryScreenState extends State<CreateEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();

  File? _categoryImage;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _orderController.text = widget.category!.order?.toString() ?? '';
      _isActive = widget.category!.isActive;
    }
  }

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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryImage == null && widget.category == null) {
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
      } else if (widget.category != null) {
        // Use existing image if editing
        imageUrl = widget.category!.imageUrl;
      }

      final categoryData = {
        'name': _nameController.text.trim(),
        'imageUrl': imageUrl!,
        if (_orderController.text.trim().isNotEmpty)
          'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'isActive': _isActive,
        if (widget.category == null) 'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      if (widget.category != null) {
        // Update existing category
        await FirebaseService.firestore
            .collection('categories')
            .doc(widget.category!.id)
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
            content: Text(widget.category == null
                ? 'Category created successfully!'
                : 'Category updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
              title: widget.category == null
                  ? 'Create Category'
                  : 'Edit Category',
              showBackButton: true,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Edit Indicator
                      if (widget.category != null)
                        Container(
                          padding: const EdgeInsets.all(Sizes.s16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Sizes.s12),
                            border: Border.all(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: const Color(0xFFFF6B35),
                                size: Sizes.s20,
                              ),
                              const SizedBox(width: Sizes.s12),
                              Expanded(
                                child: Text(
                                  'Editing: ${widget.category!.name}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFFFF6B35),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.category != null) const SizedBox(height: Sizes.s24),

                      // Category Image
                      Text(
                        'Category Image *',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(Sizes.s16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: _categoryImage == null &&
                                  widget.category == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(Sizes.s16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        size: Sizes.s48,
                                        color: const Color(0xFFFF6B35),
                                      ),
                                    ),
                                    const SizedBox(height: Sizes.s12),
                                    Text(
                                      'Tap to add image',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Sizes.s16),
                                      child: _categoryImage != null
                                          ? Image.file(
                                              _categoryImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 200,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: widget.category!.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 200,
                                              placeholder: (context, url) => Container(
                                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: const Color(0xFFFF6B35),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.error_outline,
                                                  size: Sizes.s48,
                                                  color: Theme.of(context).colorScheme.error,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      top: Sizes.s8,
                                      right: Sizes.s8,
                                      child: Container(
                                        padding: const EdgeInsets.all(Sizes.s8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: Sizes.s16,
                                        ),
                                      ),
                                    ),
                                  ],
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
                            'Display Order (Optional)',
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
                            hintText: 'Lower numbers appear first',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Is Active Toggle
                      Container(
                        padding: const EdgeInsets.all(Sizes.s16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(Sizes.s12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category Status',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: Sizes.s4),
                                Text(
                                  _isActive
                                      ? 'Visible to users'
                                      : 'Hidden from users',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: Sizes.s20,
                                          height: Sizes.s20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: Sizes.s12),
                                        Text(
                                          'Uploading image...',
                                          style: AppTextStyles.buttonLargeBold.copyWith(
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.category == null
                                          ? Icons.add_circle_outline
                                          : Icons.save,
                                      color: Colors.white,
                                      size: Sizes.s20,
                                    ),
                                    const SizedBox(width: Sizes.s8),
                                    Text(
                                      widget.category == null
                                          ? 'Create Category'
                                          : 'Update Category',
                                      style: AppTextStyles.buttonLargeBold.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
