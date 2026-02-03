import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import 'package:food_flow_app/core/firebase/firebase_service.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isInitialized = false;
  String _countryCode = '+1';
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authController = DependencyInjection.instance.authController;
      final currentUser = authController.currentUser;
      
      // Helper function to parse phone number
      void parsePhoneNumber(String? phone) {
        if (phone != null && phone.isNotEmpty) {
          // Try to extract country code (assuming format like +1234567890)
          if (phone.startsWith('+')) {
            // Find where country code ends (usually 1-3 digits)
            int codeEnd = 1;
            while (codeEnd < phone.length && codeEnd < 4 && 
                   phone[codeEnd].codeUnitAt(0) >= 48 && 
                   phone[codeEnd].codeUnitAt(0) <= 57) {
              codeEnd++;
            }
            _countryCode = phone.substring(0, codeEnd);
            _phoneNumber = phone.substring(codeEnd);
            _phoneController.text = _phoneNumber;
          } else {
            _phoneNumber = phone;
            _phoneController.text = _phoneNumber;
          }
        } else {
          _phoneNumber = '';
          _phoneController.text = '';
        }
      }

      if (currentUser != null) {
        setState(() {
          _fullNameController.text = currentUser.name ?? '';
          _emailController.text = currentUser.email;
          parsePhoneNumber(currentUser.phoneNumber);
          _bioController.text = currentUser.bio ?? '';
          _currentImageUrl = currentUser.userImage ?? currentUser.photoUrl;
          _isInitialized = true;
        });
      } else {
        // Fetch user from Firestore if not in controller
        final authRepository = DependencyInjection.instance.authRepository;
        final userId = FirebaseService.currentUser?.uid;
        if (userId != null) {
          final user = await authRepository.getById(userId);
          if (user != null && mounted) {
            setState(() {
              _fullNameController.text = user.name ?? '';
              _emailController.text = user.email;
              parsePhoneNumber(user.phoneNumber);
              _bioController.text = user.bio ?? '';
              _currentImageUrl = user.userImage ?? user.photoUrl;
              _isInitialized = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final authController = DependencyInjection.instance.authController;
      final userId = authController.currentUser?.id ?? FirebaseService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final storage = FirebaseService.storage;
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child('user_images').child(fileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = DependencyInjection.instance.authController;
      final currentUser = authController.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      String? imageUrl = _currentImageUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToFirebase(_selectedImage!);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Combine country code and phone number
      final completePhoneNumber = _phoneNumber.isNotEmpty 
          ? '$_countryCode$_phoneNumber' 
          : null;

      // Update user profile
      final updatedUser = currentUser.copyWith(
        name: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
        phoneNumber: completePhoneNumber,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        userImage: imageUrl,
        photoUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final authRepository = DependencyInjection.instance.authRepository;
      await authRepository.update(currentUser.id, updatedUser);

      // Refresh user data in controller
      await authController.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Top Navigation
              _buildTopNavigation(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                  child: Column(
                    children: [
                      const SizedBox(height: Sizes.s24),

                      // Profile Picture Section
                      AnimatedCard(
                        delay: const Duration(milliseconds: 100),
                        child: _buildProfilePictureSection(),
                      ),

                      const SizedBox(height: Sizes.s32),

                      // Form Fields
                      AnimatedListItem(
                        index: 0,
                        delay: const Duration(milliseconds: 200),
                        child: _buildFormField(
                          label: 'FULL NAME',
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                        ),
                      ),
                      const SizedBox(height: Sizes.s16),

                      AnimatedListItem(
                        index: 1,
                        delay: const Duration(milliseconds: 250),
                        child: _buildFormField(
                          label: 'EMAIL',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: false, // Email cannot be changed
                        ),
                      ),
                      const SizedBox(height: Sizes.s16),

                      AnimatedListItem(
                        index: 2,
                        delay: const Duration(milliseconds: 300),
                        child: _buildPhoneField(),
                      ),
                      const SizedBox(height: Sizes.s16),

                      AnimatedListItem(
                        index: 3,
                        delay: const Duration(milliseconds: 350),
                        child: _buildBioField(),
                      ),

                      const SizedBox(height: Sizes.s32),
                    ],
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(Sizes.s12),
                child: SizedBox(
                  width: double.infinity,
                  height: Sizes.s56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploading) ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Sizes.s12),
                      ),
                      elevation: 0,
                    ),
                    child: (_isLoading || _isUploading)
                        ? const SizedBox(
                            height: Sizes.s20,
                            width: Sizes.s20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'SAVE',
                            style: AppTextStyles.buttonLargeBold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Back Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                TablerIconsHelper.arrowLeft,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Title
          Text(
            'Edit Profile',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Profile Picture
        ClipOval(
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  width: Sizes.s120,
                  height: Sizes.s120,
                  fit: BoxFit.cover,
                )
              : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _currentImageUrl!,
                      width: Sizes.s120,
                      height: Sizes.s120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: Sizes.s120,
                        height: Sizes.s120,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.orange.shade50,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: Sizes.s120,
                        height: Sizes.s120,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.orange.shade50,
                        child: Icon(
                          TablerIconsHelper.person,
                          size: Sizes.s60,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : Container(
                      width: Sizes.s120,
                      height: Sizes.s120,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.orange.shade50,
                      child: Icon(
                        TablerIconsHelper.person,
                        size: Sizes.s60,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
        ),

        // Edit Button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: Sizes.s40,
              height: Sizes.s40,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TablerIconsHelper.edit,
                color: Colors.white,
                size: Sizes.s20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: Sizes.s12,
          ),
        ),
        const SizedBox(height: Sizes.s8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: AppTextStyles.bodyMedium.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
                : (isDark ? Colors.grey.shade900 : Colors.grey.shade200),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Sizes.s16,
              vertical: Sizes.s16,
            ),
          ),
          validator: (value) {
            if (enabled && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getCountryCodeFromDialCode(String dialCode) {
    // Map common dial codes to country codes
    final dialCodeMap = {
      '+1': 'US',
      '+44': 'GB',
      '+91': 'IN',
      '+86': 'CN',
      '+81': 'JP',
      '+49': 'DE',
      '+33': 'FR',
      '+39': 'IT',
      '+34': 'ES',
      '+61': 'AU',
      '+55': 'BR',
      '+7': 'RU',
      '+82': 'KR',
      '+65': 'SG',
      '+971': 'AE',
    };
    return dialCodeMap[dialCode] ?? 'US';
  }

  Widget _buildPhoneField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHONE NUMBER',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: Sizes.s12,
          ),
        ),
        const SizedBox(height: Sizes.s8),
        IntlPhoneField(
          controller: _phoneController,
          initialCountryCode: _getCountryCodeFromDialCode(_countryCode),
          decoration: InputDecoration(
            hintText: 'Enter your phone number',
            hintStyle: TextStyle(
              color: isDark
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                  : Colors.grey.shade600,
              fontSize: Sizes.s14,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Sizes.s16,
              vertical: Sizes.s16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B35),
                width: 2,
              ),
            ),
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: (phone) {
            setState(() {
              _countryCode = phone.countryCode;
              _phoneNumber = phone.number;
            });
          },
          onCountryChanged: (country) {
            setState(() {
              _countryCode = '+${country.dialCode}';
            });
          },
        ),
      ],
    );
  }

  Widget _buildBioField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIO',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: Sizes.s12,
          ),
        ),
        const SizedBox(height: Sizes.s8),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Sizes.s16,
              vertical: Sizes.s16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter BIO';
            }
            return null;
          },
        ),
      ],
    );
  }
}
