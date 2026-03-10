import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final double totalAmount;
  final String deliveryAddress;
  final String? deliveryNote;
  final String? addressTitle;
  final double latitude;
  final double longitude;

  const PhoneVerificationScreen({
    super.key,
    required this.totalAmount,
    required this.deliveryAddress,
    this.deliveryNote,
    this.addressTitle,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  String? _errorMessage;
  String _countryCode = '+92';
  String _phoneNumber = '';

  final _authController = DependencyInjection.instance.authController;

  @override
  void initState() {
    super.initState();
    // Pre-fill phone number if user has one (Pakistan only)
    final currentUser = _authController.currentUser;
    if (currentUser?.phoneNumber != null && currentUser!.phoneNumber!.isNotEmpty) {
      final phone = currentUser.phoneNumber!;
      _countryCode = '+92';
      if (phone.startsWith('+92')) {
        _phoneNumber = phone.substring(3).replaceAll(RegExp(r'[^\d]'), '');
      } else {
        _phoneNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
      }
      _phoneController.text = _phoneNumber;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (_phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10) {
      return 'Please enter a valid Pakistan phone number (10 digits)';
    }
    return null;
  }

  Future<void> _verifyAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final digits = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final phoneNumber = '$_countryCode$digits';
      final currentUser = _authController.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not logged in.';
        });
        return;
      }

      // Update user's phone number in Firestore
      await _authController.updateUserPhoneNumber(phoneNumber);
      
      // Refresh user data
      await _authController.refreshUser();

      if (mounted) {
        // Navigate to payment screen
        Navigator.pushNamed(
          context,
          Routes.payment,
          arguments: {
            'total': widget.totalAmount,
            'deliveryAddress': widget.deliveryAddress,
            'deliveryNote': widget.deliveryNote,
            'addressTitle': widget.addressTitle,
            'latitude': widget.latitude,
            'longitude': widget.longitude,
            'phoneNumber': phoneNumber,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying phone number: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
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
            _buildTopNavigation(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sizes.s24),

                      // Icon
                      Center(
                        child: Container(
                          width: Sizes.s80,
                          height: Sizes.s80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            TablerIconsHelper.phone,
                            color: Color(0xFFFF6B35),
                            size: Sizes.s40,
                          ),
                        ),
                      ),
                      const SizedBox(height: Sizes.s24),

                      // Title
                      Text(
                        'Phone Number Verification',
                        style: AppTextStyles.heading1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s8),

                      // Description
                      Text(
                        'Please verify your phone number. This is important for order confirmation and rider contact.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Phone Number Field
                      Text(
                        'Phone Number *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          prefixIcon: const Icon(TablerIconsHelper.phone),
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
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                          ),
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        validator: (_) => _validatePhone(_phoneNumber),
                        onChanged: (phone) {
                          setState(() {
                            _countryCode = phone.countryCode;
                            _phoneNumber = phone.number;
                          });
                        },
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(Sizes.s12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Sizes.s8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: Sizes.s20),
                              const SizedBox(width: Sizes.s8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: Sizes.s24),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: Sizes.s56,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                            elevation: 0,
                            disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: Sizes.s20,
                                  height: Sizes.s20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'VERIFY & CONTINUE',
                                  style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white),
                                ),
                        ),
                      ),
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

  Widget _buildTopNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
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
          Expanded(
            child: Text(
              'Phone Verification',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
