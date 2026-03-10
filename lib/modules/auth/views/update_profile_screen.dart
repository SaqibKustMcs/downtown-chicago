import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/colors/custom_colors.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  String _countryCode = '+92'; // Pakistan
  String _phoneNumber = '';

  @override
  void dispose() {
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
      final userId = authController.currentUser?.id;
      
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

  Future<void> _handleUpdateProfile() async {
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

      String? imageUrl;
      
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

        // Navigate to main container
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.mainContainer,
          (route) => false,
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFF2E2739),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Sizes.s32),
                    topRight: Radius.circular(Sizes.s32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sizes.s24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Sizes.s32),

                        // Title
                        Text(
                          'Complete Your Profile',
                          style: AppTextStyles.heading1.copyWith(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : CustomColors.textBoldColor,
                            fontSize: Sizes.s24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sizes.s8),
                        Text(
                          'Add your profile picture and information',
                          style: AppTextStyles.bodyLargeSecondary.copyWith(
                            fontSize: Sizes.s14,
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sizes.s40),

                        // Profile Picture Section
                        Center(
                          child: Stack(
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
                                    : Container(
                                        width: Sizes.s120,
                                        height: Sizes.s120,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
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
                          ),
                        ),
                        const SizedBox(height: Sizes.s8),
                        Text(
                          'Profile Picture (Optional)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : CustomColors.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Sizes.s40),

                        // Phone Number Field
                        Text(
                          'PHONE NUMBER',
                          style: AppTextStyles.label.copyWith(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : CustomColors.textBoldColor,
                            fontSize: Sizes.s12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Sizes.s8),
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'PK',
                          countries: countries.where((c) => c.code == 'PK').toList(),
                          decoration: InputDecoration(
                            hintText: 'Enter your Pakistan phone number',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor.withOpacity(0.6),
                              fontSize: Sizes.s14,
                              fontFamily: 'Poppins',
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFF5F5F5),
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
                          style: TextStyle(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : CustomColors.textBoldColor,
                            fontSize: Sizes.s14,
                            fontFamily: 'Poppins',
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
                        const SizedBox(height: Sizes.s24),

                        // Bio Field
                        Text(
                          'BIO',
                          style: AppTextStyles.label.copyWith(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : CustomColors.textBoldColor,
                            fontSize: Sizes.s12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Sizes.s8),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            color: isDark
                                ? Theme.of(context).colorScheme.onSurface
                                : CustomColors.textBoldColor,
                            fontSize: Sizes.s14,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tell us about yourself',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                  : CustomColors.secondaryTextColor.withOpacity(0.6),
                              fontSize: Sizes.s14,
                              fontFamily: 'Poppins',
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFF5F5F5),
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
                        ),
                        const SizedBox(height: Sizes.s32),

                        // Update Button
                        SizedBox(
                          height: Sizes.s56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isUploading) ? null : _handleUpdateProfile,
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
                                    'COMPLETE PROFILE',
                                    style: AppTextStyles.buttonLargeBold.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: Sizes.s24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
      child: Row(
        children: [
          Text(
            'Update Profile',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
