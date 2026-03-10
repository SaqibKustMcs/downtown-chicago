import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/models/food_item_model.dart';
import 'package:downtown/modules/home/models/category_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AddProductScreen extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const AddProductScreen({
    super.key,
    this.restaurantId,
    this.restaurantName,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();

  File? _mainImage;
  List<File> _additionalImages = [];
  bool _isAvailable = true;
  bool _isPopular = false;
  int _displayOrder = 0;
  final TextEditingController _displayOrderController = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;
  String? _selectedRestaurantId;
  String? _selectedRestaurantName;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Variations
  final List<VariationItem> _variations = [];
  final TextEditingController _variationNameController = TextEditingController();
  final TextEditingController _variationPriceController = TextEditingController();
  final TextEditingController _variationDescriptionController = TextEditingController();

  // Flavors
  final List<FlavorItem> _flavors = [];
  final TextEditingController _flavorNameController = TextEditingController();
  final TextEditingController _flavorPriceController = TextEditingController();
  final TextEditingController _flavorDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize restaurant from widget arguments if provided
    if (widget.restaurantId != null && widget.restaurantName != null) {
      _selectedRestaurantId = widget.restaurantId;
      _selectedRestaurantName = widget.restaurantName;
    } else {
      // Try to get restaurant from user's profile
      _loadRestaurantFromUser();
    }
  }

  Future<void> _loadRestaurantFromUser() async {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;
    
    if (currentUser?.restaurantId != null) {
      try {
        final restaurantDoc = await FirebaseService.firestore
            .collection('restaurants')
            .doc(currentUser!.restaurantId)
            .get();
        
        if (restaurantDoc.exists && mounted) {
          setState(() {
            _selectedRestaurantId = restaurantDoc.id;
            _selectedRestaurantName = restaurantDoc.data()?['name'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading restaurant: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _displayOrderController.dispose();
    _variationNameController.dispose();
    _variationPriceController.dispose();
    _variationDescriptionController.dispose();
    _flavorNameController.dispose();
    _flavorPriceController.dispose();
    _flavorDescriptionController.dispose();
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

  Future<void> _pickAdditionalImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _additionalImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  void _addVariation() {
    final name = _variationNameController.text.trim();
    final price = double.tryParse(_variationPriceController.text.trim());
    final description = _variationDescriptionController.text.trim();

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter variation name and price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _variations.add(VariationItem(
        name: name,
        price: price,
        description: description.isNotEmpty ? description : null,
      ));
      _variationNameController.clear();
      _variationPriceController.clear();
      _variationDescriptionController.clear();
    });
  }

  void _removeVariation(int index) {
    setState(() {
      _variations.removeAt(index);
    });
  }

  void _addFlavor() {
    final name = _flavorNameController.text.trim();
    final price = double.tryParse(_flavorPriceController.text.trim()) ?? 0.0;
    final description = _flavorDescriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter flavor name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _flavors.add(FlavorItem(
        name: name,
        price: price,
        description: description.isNotEmpty ? description : null,
      ));
      _flavorNameController.clear();
      _flavorPriceController.clear();
      _flavorDescriptionController.clear();
    });
  }

  void _removeFlavor(int index) {
    setState(() {
      _flavors.removeAt(index);
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a main product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser == null || currentUser.userType.toString() != 'UserType.admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can add products'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get restaurant ID from selected restaurant
    if (_selectedRestaurantId == null || _selectedRestaurantName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a restaurant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final restaurantId = _selectedRestaurantId!;
    final restaurantName = _selectedRestaurantName!;

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      // Upload main image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mainImageUrl = await _uploadImageToFirebase(
        _mainImage!,
        'restaurants/$restaurantId/products/main_$timestamp.jpg',
      );

      if (mainImageUrl == null) {
        throw Exception('Failed to upload main image');
      }

      // Upload additional images
      List<String> additionalImageUrls = [];
      for (int i = 0; i < _additionalImages.length; i++) {
        final imageUrl = await _uploadImageToFirebase(
          _additionalImages[i],
          'restaurants/$restaurantId/products/additional_${timestamp}_$i.jpg',
        );
        if (imageUrl != null) {
          additionalImageUrls.add(imageUrl);
        }
      }

      // Prepare variations
      List<Map<String, dynamic>> variationsList = [];
      for (var variation in _variations) {
        final variationMap = <String, dynamic>{
          'name': variation.name,
          'price': variation.price,
        };
        if (variation.description != null && variation.description!.isNotEmpty) {
          variationMap['description'] = variation.description!;
        }
        variationsList.add(variationMap);
      }

      // Prepare flavors
      List<Map<String, dynamic>> flavorsList = [];
      for (var flavor in _flavors) {
        final flavorMap = <String, dynamic>{
          'name': flavor.name,
          'price': flavor.price,
        };
        if (flavor.description != null && flavor.description!.isNotEmpty) {
          flavorMap['description'] = flavor.description!;
        }
        flavorsList.add(flavorMap);
      }

      // Create product data
      final productData = {
        'name': _nameController.text.trim(),
        'restaurantName': restaurantName,
        'restaurantId': restaurantId,
        'imageUrl': mainImageUrl,
        if (additionalImageUrls.isNotEmpty) 'imageUrls': additionalImageUrls,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        'basePrice': double.parse(_basePriceController.text.trim()),
        if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
        if (_selectedCategoryName != null) 'categoryName': _selectedCategoryName,
        'variations': variationsList,
        'flavors': flavorsList,
        'isAvailable': _isAvailable,
        'isActive': true,
        'isPopular': _isPopular,
        'displayOrder': int.tryParse(_displayOrderController.text.trim()) ?? 0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Save to Firestore - products collection with restaurantId field
      await FirebaseService.firestore
          .collection('products')
          .add(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
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
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;
    
    // Role guard - only admins can access
    if (currentUser == null || currentUser.userType != UserType.admin) {
      return RoleGuard.guard(
        context: context,
        requiredRole: UserType.admin,
        child: const SizedBox.shrink(),
        accessDeniedMessage: 'Access denied. Admin only.',
      );
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Add Product',
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
                          height: 200,
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
                                    height: 200,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Additional Images Section
                      Text(
                        'Additional Images (Optional)',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Add Image Button
                            GestureDetector(
                              onTap: _pickAdditionalImage,
                              child: Container(
                                width: 120,
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

                            // Additional Images
                            ..._additionalImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final image = entry.value;
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: Sizes.s12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Sizes.s12),
                                      child: Image.file(
                                        image,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: Sizes.s4,
                                      right: Sizes.s4,
                                      child: GestureDetector(
                                        onTap: () => _removeAdditionalImage(index),
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

                      // Product Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Name *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'e.g., Burger Ferguson, Margherita Pizza',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Product name is required';
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
                            hintText: 'Enter product description',
                            maxLines: 4,
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Base Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base Price *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _basePriceController,
                            hintText: 'e.g., 40.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Base price is required';
                              }
                              final price = double.tryParse(value.trim());
                              if (price == null || price <= 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Restaurant Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restaurant *',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseService.firestore
                                .collection('restaurants')
                                .where('isActive', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final restaurants = snapshot.data!.docs
                                  .map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return {
                                      'id': doc.id,
                                      'name': data['name'] ?? '',
                                    };
                                  })
                                  .toList()
                                ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

                              return DropdownButtonFormField<String>(
                                value: _selectedRestaurantId,
                                decoration: InputDecoration(
                                  hintText: 'Select restaurant',
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Sizes.s12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: Sizes.s16,
                                    vertical: Sizes.s16,
                                  ),
                                ),
                                items: restaurants.map((restaurant) {
                                  return DropdownMenuItem<String>(
                                    value: restaurant['id'] as String,
                                    child: Text(restaurant['name'] as String),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRestaurantId = value;
                                    _selectedRestaurantName = restaurants
                                        .firstWhere((r) => r['id'] == value)['name'] as String;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a restaurant';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Category Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category (Optional)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseService.firestore
                                .collection('categories')
                                .where('isActive', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final categories = snapshot.data!.docs
                                  .map((doc) => CategoryModel.fromFirestore(
                                        doc.data() as Map<String, dynamic>,
                                        doc.id,
                                      ))
                                  .toList()
                                ..sort((a, b) => a.name.compareTo(b.name));

                              return DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                decoration: InputDecoration(
                                  hintText: 'Select category',
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Sizes.s12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: Sizes.s16,
                                    vertical: Sizes.s16,
                                  ),
                                ),
                                items: categories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                    _selectedCategoryName = categories
                                        .firstWhere((c) => c.id == value)
                                        .name;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Variations Section
                      Text(
                        'Variations (Optional)',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      // Variation Name
                      CustomTextField(
                        controller: _variationNameController,
                        hintText: 'Variation Name (e.g., Small, Medium, Large)',
                      ),
                      const SizedBox(height: Sizes.s12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _variationPriceController,
                              hintText: 'Price',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: Sizes.s8),
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _variationDescriptionController,
                              hintText: 'Description (Optional)',
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: Sizes.s8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFFFF6B35)),
                            onPressed: _addVariation,
                          ),
                        ],
                      ),
                      if (_variations.isNotEmpty) ...[
                        const SizedBox(height: Sizes.s12),
                        ..._variations.asMap().entries.map((entry) {
                          final index = entry.key;
                          final variation = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: Sizes.s8),
                            padding: const EdgeInsets.all(Sizes.s12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(Sizes.s8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${variation.name} - ${CurrencyFormatter.format(variation.price)}',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeVariation(index),
                                    ),
                                  ],
                                ),
                                if (variation.description != null && variation.description!.isNotEmpty) ...[
                                  const SizedBox(height: Sizes.s4),
                                  Text(
                                    variation.description!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: Sizes.s24),

                      // Flavors Section
                      Text(
                        'Flavors (Optional)',
                        style: AppTextStyles.heading3.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      // Flavor Name
                      CustomTextField(
                        controller: _flavorNameController,
                        hintText: 'Flavor Name (e.g., Mild, Spicy, Extra Spicy)',
                      ),
                      const SizedBox(height: Sizes.s12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _flavorPriceController,
                              hintText: 'Additional Price (0 if free)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: Sizes.s8),
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _flavorDescriptionController,
                              hintText: 'Description (Optional)',
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: Sizes.s8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFFFF6B35)),
                            onPressed: _addFlavor,
                          ),
                        ],
                      ),
                      if (_flavors.isNotEmpty) ...[
                        const SizedBox(height: Sizes.s12),
                        ..._flavors.asMap().entries.map((entry) {
                          final index = entry.key;
                          final flavor = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: Sizes.s8),
                            padding: const EdgeInsets.all(Sizes.s12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(Sizes.s8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${flavor.name}${flavor.price > 0 ? ' - +${CurrencyFormatter.format(flavor.price)}' : ' (Free)'}',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeFlavor(index),
                                    ),
                                  ],
                                ),
                                if (flavor.description != null && flavor.description!.isNotEmpty) ...[
                                  const SizedBox(height: Sizes.s4),
                                  Text(
                                    flavor.description!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: Sizes.s24),

                      // Is Available Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Product is Available',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                            activeColor: const Color(0xFFFF6B35),
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Is Popular Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark as Popular',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: Sizes.s4),
                              Text(
                                'Show in "Popular Products" section',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isPopular,
                            onChanged: (value) {
                              setState(() {
                                _isPopular = value;
                              });
                            },
                            activeColor: const Color(0xFFFF6B35),
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Display Order
                      Text(
                        'Display Order',
                        style: AppTextStyles.label.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      CustomTextField(
                        controller: _displayOrderController,
                        hintText: '0 (lower numbers appear first)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final order = int.tryParse(value.trim());
                            if (order == null || order < 0) {
                              return 'Please enter a valid number (0 or greater)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s8),
                      Text(
                        'Lower numbers appear first. Products with same order are sorted by name.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                  'Add Product',
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

// Helper classes for managing variations and flavors in the form
class VariationItem {
  final String name;
  final double price;
  final String? description;

  VariationItem({
    required this.name,
    required this.price,
    this.description,
  });
}

class FlavorItem {
  final String name;
  final double price;
  final String? description;

  FlavorItem({
    required this.name,
    required this.price,
    this.description,
  });
}
