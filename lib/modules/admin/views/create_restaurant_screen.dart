import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/modules/widgets/top_navigation_bar.dart';
import 'package:food_flow_app/modules/auth/widgets/custom_text_field.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class CreateRestaurantScreen extends StatefulWidget {
  const CreateRestaurantScreen({super.key});

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cuisinesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _deliveryCostController = TextEditingController();
  final _deliveryTimeController = TextEditingController();

  File? _mainImage;
  List<File> _bannerImages = [];
  bool _isOpen = true;
  bool _isLoading = false;
  bool _isUploading = false;

  // Available categories (can be fetched from Firestore later)
  final List<String> _availableCategories = [
    'All',
    'Hot Dog',
    'Burger',
    'Pizza',
    'Sushi',
    'Tacos',
    'Chicken',
    'Sandwich',
    'Fries',
    'Wings',
    'Pasta',
    'Salad',
    'Soup',
    'Dessert',
    'Beverages',
    'Breakfast',
    'Seafood',
    'BBQ',
    'Mexican',
    'Asian',
  ];
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _nameController.dispose();
    _cuisinesController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _deliveryCostController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _bannerImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeBannerImage(int index) {
    setState(() {
      _bannerImages.removeAt(index);
    });
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a main restaurant image'),
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
      final authController = DependencyInjection.instance.authController;
      final currentUser = authController.currentUser;

      if (currentUser == null || currentUser.userType.toString() != 'UserType.admin') {
        throw Exception('Only admins can create restaurants');
      }

      // Upload main image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mainImageUrl = await _uploadImageToFirebase(
        _mainImage!,
        'restaurants/${currentUser.id}/main_$timestamp.jpg',
      );

      if (mainImageUrl == null) {
        throw Exception('Failed to upload main image');
      }

      // Upload banner images
      List<String> bannerImageUrls = [];
      for (int i = 0; i < _bannerImages.length; i++) {
        final bannerUrl = await _uploadImageToFirebase(
          _bannerImages[i],
          'restaurants/${currentUser.id}/banner_${timestamp}_$i.jpg',
        );
        if (bannerUrl != null) {
          bannerImageUrls.add(bannerUrl);
        }
      }

      // Create restaurant data
      final restaurantData = {
        'name': _nameController.text.trim(),
        'cuisines': _cuisinesController.text.trim(),
        'imageUrl': mainImageUrl,
        if (bannerImageUrls.isNotEmpty) 'bannerImages': bannerImageUrls,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        'rating': 0.0,
        'totalRatings': 0,
        'deliveryCost': _deliveryCostController.text.trim().isEmpty
            ? 'Free'
            : _deliveryCostController.text.trim(),
        'deliveryTime': _deliveryTimeController.text.trim().isEmpty
            ? '20 min'
            : _deliveryTimeController.text.trim(),
        if (_addressController.text.trim().isNotEmpty)
          'address': _addressController.text.trim(),
        'isOpen': _isOpen,
        'isActive': true,
        'adminId': currentUser.id,
        if (_selectedCategories.isNotEmpty)
          'categoryNames': _selectedCategories.toList(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Save to Firestore
      await FirebaseService.firestore
          .collection('restaurants')
          .add(restaurantData);

      // Update user's restaurantId
      await FirebaseService.firestore
          .collection('users')
          .doc(currentUser.id)
          .update({'restaurantId': restaurantData['name']}); // TODO: Use actual restaurant ID

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating restaurant: $e');
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
              title: 'Create Restaurant',
              showBackButton: true,
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sizes.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Sizes.s16),

                      // Main Image Section
                      Text(
                        'Main Image *',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      GestureDetector(
                        onTap: _pickMainImage,
                        child: Container(
                          height: Sizes.s200,
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
                          child: _mainImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      'Tap to add main image',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(Sizes.s16),
                                  child: Image.file(
                                    _mainImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: Sizes.s200,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Banner Images Section
                      Text(
                        'Banner Images (Optional)',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      SizedBox(
                        height: Sizes.s120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Add Banner Button
                            GestureDetector(
                              onTap: _pickBannerImage,
                              child: Container(
                                width: Sizes.s120,
                                margin: const EdgeInsets.only(right: Sizes.s12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(Sizes.s12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: Sizes.s32,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                                    const SizedBox(height: Sizes.s4),
                                    Text(
                                      'Add',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Banner Images
                            ..._bannerImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final image = entry.value;
                              return Container(
                                width: Sizes.s120,
                                margin: const EdgeInsets.only(right: Sizes.s12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Sizes.s12),
                                      child: Image.file(
                                        image,
                                        width: Sizes.s120,
                                        height: Sizes.s120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: Sizes.s4,
                                      right: Sizes.s4,
                                      child: GestureDetector(
                                        onTap: () => _removeBannerImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(Sizes.s4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: Sizes.s16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Restaurant Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restaurant Name *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Enter restaurant name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Restaurant name is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Cuisines
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuisines *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _cuisinesController,
                            hintText: 'e.g., Burger - Chicken - Rice - Wings',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Cuisines are required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description (Optional)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _descriptionController,
                            hintText: 'Enter restaurant description',
                            maxLines: 4,
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Address
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address (Optional)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _addressController,
                            hintText: 'Enter restaurant address',
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Delivery Cost
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Cost *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _deliveryCostController,
                            hintText: 'e.g., Free or \$2.99',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Delivery cost is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Delivery Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Time *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _deliveryTimeController,
                            hintText: 'e.g., 20 min or 30-45 min',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Delivery time is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Categories Selection
                      Text(
                        'Categories (Optional)',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      Wrap(
                        spacing: Sizes.s8,
                        runSpacing: Sizes.s8,
                        children: _availableCategories.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                            selectedColor: const Color(0xFFFF6B35),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Is Open Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Restaurant is Open',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: _isOpen,
                            onChanged: (value) {
                              setState(() {
                                _isOpen = value;
                              });
                            },
                            activeColor: const Color(0xFFFF6B35),
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s32),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        height: Sizes.s56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleCreate,
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
                                          'Uploading images...',
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
                              : Text(
                                  'Create Restaurant',
                                  style: AppTextStyles.buttonLargeBold.copyWith(
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
    );
  }
}
