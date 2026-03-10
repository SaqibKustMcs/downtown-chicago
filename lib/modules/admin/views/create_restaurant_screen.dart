import 'dart:io';
import 'package:flutter/material.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/services/location_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/home/models/category_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class CreateRestaurantScreen extends StatefulWidget {
  final Restaurant? restaurant;

  const CreateRestaurantScreen({super.key, this.restaurant});

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
  final _deliveryFeeController = TextEditingController();
  final _deliveryPricePerKmController = TextEditingController();
  final _deliveryTimeController = TextEditingController();

  File? _mainImage;
  List<File> _bannerImages = [];
  List<String> _existingBannerImages = [];
  bool _isOpen = true;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    if (widget.restaurant != null) {
      _nameController.text = widget.restaurant!.name;
      _cuisinesController.text = widget.restaurant!.cuisines;
      _descriptionController.text = widget.restaurant!.description ?? '';
      _addressController.text = widget.restaurant!.address ?? '';
      _deliveryCostController.text = widget.restaurant!.deliveryCost;
      _deliveryFeeController.text = widget.restaurant!.deliveryFee.toStringAsFixed(2);
      _deliveryPricePerKmController.text = (widget.restaurant!.deliveryPricePerKm ?? 5.0).toStringAsFixed(0);
      _deliveryTimeController.text = widget.restaurant!.deliveryTime;
      _isOpen = widget.restaurant!.isOpen;
      
      // Parse opening and closing times
      if (widget.restaurant!.openingTime != null && widget.restaurant!.openingTime!.isNotEmpty) {
        final openingParts = widget.restaurant!.openingTime!.split(':');
        _openingTime = TimeOfDay(
          hour: int.parse(openingParts[0]),
          minute: int.parse(openingParts[1]),
        );
      }
      if (widget.restaurant!.closingTime != null && widget.restaurant!.closingTime!.isNotEmpty) {
        final closingParts = widget.restaurant!.closingTime!.split(':');
        _closingTime = TimeOfDay(
          hour: int.parse(closingParts[0]),
          minute: int.parse(closingParts[1]),
        );
      }
      
      if (widget.restaurant!.location != null) {
        _latitude = widget.restaurant!.location!['latitude'];
        _longitude = widget.restaurant!.location!['longitude'];
      }
      if (widget.restaurant!.categoryNames != null) {
        _selectedCategories = widget.restaurant!.categoryNames!.toSet();
      }
      if (widget.restaurant!.bannerImages != null) {
        _existingBannerImages = widget.restaurant!.bannerImages!;
      }
    } else {
      _deliveryPricePerKmController.text = '5';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisinesController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _deliveryCostController.dispose();
    _deliveryFeeController.dispose();
    _deliveryPricePerKmController.dispose();
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locationData = await LocationService.getCurrentLocationAndAddress();

      if (locationData != null && mounted) {
        setState(() {
          _latitude = locationData['latitude'] as double;
          _longitude = locationData['longitude'] as double;
          _addressController.text = locationData['address'] as String;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location retrieved successfully!'), backgroundColor: Colors.green));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get location. Please check location permissions.'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_mainImage == null && widget.restaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a main restaurant image'), backgroundColor: Colors.red));
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

      // Generate timestamp for file naming
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload main image if new image is selected
      String? mainImageUrl;
      if (_mainImage != null) {
        mainImageUrl = await _uploadImageToFirebase(_mainImage!, 'restaurants/${currentUser.id}/main_$timestamp.jpg');

        if (mainImageUrl == null) {
          throw Exception('Failed to upload main image');
        }
      } else if (widget.restaurant != null) {
        // Use existing image if editing
        mainImageUrl = widget.restaurant!.imageUrl;
      }

      // Upload banner images
      List<String> bannerImageUrls = [];
      if (widget.restaurant != null && widget.restaurant!.bannerImages != null) {
        // Keep existing banner images
        bannerImageUrls.addAll(widget.restaurant!.bannerImages!);
      }
      // Add new banner images
      for (int i = 0; i < _bannerImages.length; i++) {
        final bannerUrl = await _uploadImageToFirebase(_bannerImages[i], 'restaurants/${currentUser.id}/banner_${timestamp}_$i.jpg');
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
        if (_descriptionController.text.trim().isNotEmpty) 'description': _descriptionController.text.trim(),
        'rating': 0.0,
        'totalRatings': 0,
        'deliveryCost': _deliveryCostController.text.trim().isEmpty ? 'Free' : _deliveryCostController.text.trim(),
        'deliveryFee': double.tryParse(_deliveryFeeController.text.trim()) ?? 0.0,
        'deliveryPricePerKm': double.tryParse(_deliveryPricePerKmController.text.trim()) ?? 5.0,
        'deliveryTime': _deliveryTimeController.text.trim().isEmpty ? '20 - 50 mins' : _deliveryTimeController.text.trim(),
        if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
        if (_latitude != null && _longitude != null) 'location': {'latitude': _latitude!, 'longitude': _longitude!},
        'isOpen': _isOpen,
        if (_openingTime != null) 'openingTime': '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}',
        if (_closingTime != null) 'closingTime': '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}',
        'isActive': true,
        'adminId': currentUser.id,
        if (_selectedCategories.isNotEmpty) 'categoryNames': _selectedCategories.toList(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Save to Firestore
      if (widget.restaurant != null && widget.restaurant!.id != null) {
        // Update existing restaurant
        await FirebaseService.firestore.collection('restaurants').doc(widget.restaurant!.id).update(restaurantData);
      } else {
        // Create new restaurant
        final docRef = await FirebaseService.firestore.collection('restaurants').add(restaurantData);

        // Update user's restaurantId
        await FirebaseService.firestore.collection('users').doc(currentUser.id).update({'restaurantId': docRef.id});
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.restaurant == null ? 'Restaurant created successfully!' : 'Restaurant updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating restaurant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
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
            TopNavigationBar(title: widget.restaurant == null ? 'Create Restaurant' : 'Edit Restaurant', showBackButton: true),

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
                        style: AppTextStyles.heading3.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Sizes.s12),
                      GestureDetector(
                        onTap: _pickMainImage,
                        child: Container(
                          height: Sizes.s200,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(Sizes.s16),
                            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                          child: _mainImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: Sizes.s48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                    const SizedBox(height: Sizes.s8),
                                    Text('Tap to add main image', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(Sizes.s16),
                                  child: Image.file(_mainImage!, fit: BoxFit.cover, width: double.infinity, height: Sizes.s200),
                                ),
                        ),
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Banner Images Section
                      Text(
                        'Banner Images (Optional)',
                        style: AppTextStyles.heading3.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
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
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(Sizes.s12),
                                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, size: Sizes.s32, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                    const SizedBox(height: Sizes.s4),
                                    Text('Add', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                  ],
                                ),
                              ),
                            ),

                            // Existing Banner Images (from Firebase)
                            ..._existingBannerImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final imageUrl = entry.value;
                              return Container(
                                width: Sizes.s120,
                                margin: const EdgeInsets.only(right: Sizes.s12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Sizes.s12),
                                      child: Image.network(
                                        imageUrl,
                                        width: Sizes.s120,
                                        height: Sizes.s120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: Sizes.s120,
                                          height: Sizes.s120,
                                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                          child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: Sizes.s4,
                                      right: Sizes.s4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _existingBannerImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(Sizes.s4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: Sizes.s16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // New Banner Images (from device)
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
                                      child: Image.file(image, width: Sizes.s120, height: Sizes.s120, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: Sizes.s4,
                                      right: Sizes.s4,
                                      child: GestureDetector(
                                        onTap: () => _removeBannerImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(Sizes.s4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: Sizes.s16),
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
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
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
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
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
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(controller: _descriptionController, hintText: 'Enter restaurant description', maxLines: 4),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Address
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Address (Optional)',
                                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                              ),
                              TextButton.icon(
                                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                                icon: _isGettingLocation
                                    ? const SizedBox(width: Sizes.s16, height: Sizes.s16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(TablerIconsHelper.location, size: Sizes.s16),
                                label: Text(_isGettingLocation ? 'Getting...' : 'Use Current Location', style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFFF6B35))),
                              ),
                            ],
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(controller: _addressController, hintText: 'Enter restaurant address or use current location'),
                          if (_latitude != null && _longitude != null) ...[
                            const SizedBox(height: Sizes.s8),
                            Container(
                              padding: const EdgeInsets.all(Sizes.s12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Sizes.s8),
                                border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: const Color(0xFFFF6B35), size: Sizes.s16),
                                  const SizedBox(width: Sizes.s8),
                                  Expanded(
                                    child: Text(
                                      'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                      style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFFF6B35)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Delivery Cost
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Cost *',
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _deliveryCostController,
                            hintText: 'e.g., Free or Rs. 2.99',
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

                      // Delivery price per KM (for distance-based fee: distance × this rate)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery price per KM (Rs) *',
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _deliveryPricePerKmController,
                            hintText: 'e.g., 5 (fee = distance km × this rate)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required for distance-based delivery fee';
                              }
                              final n = double.tryParse(value.trim());
                              if (n == null || n < 0) return 'Enter a valid number (e.g. 5)';
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
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _deliveryTimeController,
                            hintText: 'e.g., 20 - 50 mins',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Delivery time is required';
                              }
                              // Validate format: should contain numbers and "mins" or "min"
                              final trimmed = value.trim();
                              if (!RegExp(r'\d+.*\d+.*mins?', caseSensitive: false).hasMatch(trimmed)) {
                                return 'Please enter a valid range (e.g., 20 - 50 mins)';
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
                        style: AppTextStyles.heading3.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Sizes.s12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseService.firestore.collection('categories').where('isActive', isEqualTo: true).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(padding: EdgeInsets.all(Sizes.s16), child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(Sizes.s16),
                              child: Text('Error loading categories: ${snapshot.error}', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error)),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(Sizes.s16),
                              child: Text('No categories available', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                            );
                          }

                          final categories = snapshot.data!.docs.map((doc) => CategoryModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList()
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

                          return Wrap(
                            spacing: Sizes.s8,
                            runSpacing: Sizes.s8,
                            children: categories.map((category) {
                              final isSelected = _selectedCategories.contains(category.name);
                              return FilterChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category.name);
                                    } else {
                                      _selectedCategories.remove(category.name);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFFFF6B35),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: Sizes.s24),

                      // Is Open Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Restaurant is Open',
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
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

                      const SizedBox(height: Sizes.s24),

                      // Opening Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opening Time',
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Sizes.s8),
                          GestureDetector(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _openingTime ?? const TimeOfDay(hour: 9, minute: 0),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  _openingTime = pickedTime;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Sizes.s12),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _openingTime != null
                                        ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Select opening time',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _openingTime != null
                                          ? Theme.of(context).colorScheme.onSurface
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Closing Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Closing Time',
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Sizes.s8),
                          GestureDetector(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _closingTime ?? const TimeOfDay(hour: 22, minute: 0),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  _closingTime = pickedTime;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Sizes.s12),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _closingTime != null
                                        ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Select closing time',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _closingTime != null
                                          ? Theme.of(context).colorScheme.onSurface
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_openingTime != null && _closingTime != null) ...[
                            const SizedBox(height: Sizes.s8),
                            Text(
                              'Restaurant will automatically open/close based on these times',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
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
                                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                          ),
                                          const SizedBox(width: Sizes.s12),
                                          Text('Uploading images...', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
                                        ],
                                      )
                                    : const SizedBox(
                                        width: Sizes.s20,
                                        height: Sizes.s20,
                                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                      )
                              : Text(widget.restaurant == null ? 'Create Restaurant' : 'Update Restaurant', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
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
