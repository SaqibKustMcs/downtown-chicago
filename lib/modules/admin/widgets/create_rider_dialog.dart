import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class CreateRiderDialog extends StatefulWidget {
  const CreateRiderDialog({super.key});

  @override
  State<CreateRiderDialog> createState() => _CreateRiderDialogState();
}

class _CreateRiderDialogState extends State<CreateRiderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _countryCode = '+92';
  String _phoneNumber = '';
  String _secondaryCountryCode = '+92';
  String _secondaryPhoneNumber = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _cnicController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final phoneDigits = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final secondaryDigits = _secondaryPhoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final userId = await UserManagementService.instance.createRider(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phoneNumber: phoneDigits.isEmpty ? null : '$_countryCode$phoneDigits',
          secondaryContactNumber: secondaryDigits.isEmpty
              ? null
              : '$_secondaryCountryCode$secondaryDigits',
          cnic: _cnicController.text.trim().isEmpty
              ? null
              : _cnicController.text.trim(),
          vehicleType: _vehicleTypeController.text.trim().isEmpty
              ? null
              : _vehicleTypeController.text.trim(),
          vehicleNumber: _vehicleNumberController.text.trim().isEmpty
              ? null
              : _vehicleNumberController.text.trim(),
        );

        if (userId != null && mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating rider: ${e.toString()}'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Sizes.s16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Sizes.s16),
                  topRight: Radius.circular(Sizes.s16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Create New Rider',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Full Name *',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter rider name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s16),
                      // Email
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Email *',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s16),
                      // Password
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Password *',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s16),
                      // Phone Number (Pakistan only)
                      IntlPhoneField(
                        controller: _phoneController,
                        initialCountryCode: 'PK',
                        countries: countries.where((c) => c.code == 'PK').toList(),
                        decoration: InputDecoration(
                          hintText: 'Pakistan phone number',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (phone) {
                          setState(() {
                            _countryCode = phone.countryCode;
                            _phoneNumber = phone.number;
                          });
                        },
                      ),
                      const SizedBox(height: Sizes.s16),
                      // Secondary Phone Number (Pakistan only, optional)
                      IntlPhoneField(
                        controller: _secondaryPhoneController,
                        initialCountryCode: 'PK',
                        countries: countries.where((c) => c.code == 'PK').toList(),
                        decoration: InputDecoration(
                          hintText: 'Secondary Pakistan phone (optional)',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (phone) {
                          setState(() {
                            _secondaryCountryCode = phone.countryCode;
                            _secondaryPhoneNumber = phone.number;
                          });
                        },
                      ),
                      const SizedBox(height: Sizes.s16),
                      // CNIC
                      CustomTextField(
                        controller: _cnicController,
                        hintText: 'CNIC Number',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: Sizes.s16),
                      // Vehicle Type
                      CustomTextField(
                        controller: _vehicleTypeController,
                        hintText: 'Vehicle Type (e.g., Bike, Car)',
                      ),
                      const SizedBox(height: Sizes.s16),
                      // Vehicle Number
                      CustomTextField(
                        controller: _vehicleNumberController,
                        hintText: 'Vehicle Number',
                      ),
                      const SizedBox(height: Sizes.s24),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: Sizes.s12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleCreate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: Sizes.s20,
                                      height: Sizes.s20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Create Rider'),
                            ),
                          ),
                        ],
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
}
