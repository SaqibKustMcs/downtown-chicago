import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class EditRiderDialog extends StatefulWidget {
  final UserModel rider;

  const EditRiderDialog({super.key, required this.rider});

  @override
  State<EditRiderDialog> createState() => _EditRiderDialogState();
}

class _EditRiderDialogState extends State<EditRiderDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _cnicController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;
  bool _isLoading = false;
  String _countryCode = '+92';
  String _phoneNumber = '';
  String _secondaryCountryCode = '+92';
  String _secondaryPhoneNumber = '';

  void _parsePhone(String? phone, bool isPrimary) {
    if (phone == null || phone.isEmpty) {
      if (isPrimary) {
        _phoneNumber = '';
        _phoneController.text = '';
      } else {
        _secondaryPhoneNumber = '';
        _secondaryPhoneController.text = '';
      }
      return;
    }
    final code = '+92';
    String digits;
    if (phone.startsWith('+92')) {
      digits = phone.substring(3).replaceAll(RegExp(r'[^\d]'), '');
    } else {
      digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    }
    if (isPrimary) {
      _countryCode = code;
      _phoneNumber = digits;
      _phoneController.text = digits;
    } else {
      _secondaryCountryCode = code;
      _secondaryPhoneNumber = digits;
      _secondaryPhoneController.text = digits;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rider.name ?? '');
    _emailController = TextEditingController(text: widget.rider.email);
    _phoneController = TextEditingController();
    _secondaryPhoneController = TextEditingController();
    _parsePhone(widget.rider.phoneNumber, true);
    _parsePhone(widget.rider.secondaryContactNumber, false);
    _cnicController = TextEditingController(text: widget.rider.cnic ?? '');
    _vehicleTypeController = TextEditingController(text: widget.rider.vehicleType ?? '');
    _vehicleNumberController = TextEditingController(text: widget.rider.vehicleNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _cnicController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final phoneDigits = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final secondaryDigits = _secondaryPhoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        final updateData = <String, dynamic>{
          'name': _nameController.text.trim(),
          if (phoneDigits.isNotEmpty) 'phoneNumber': '$_countryCode$phoneDigits',
          if (secondaryDigits.isNotEmpty)
            'secondaryContactNumber': '$_secondaryCountryCode$secondaryDigits',
          if (_cnicController.text.trim().isNotEmpty) 'cnic': _cnicController.text.trim(),
          if (_vehicleTypeController.text.trim().isNotEmpty)
            'vehicleType': _vehicleTypeController.text.trim(),
          if (_vehicleNumberController.text.trim().isNotEmpty)
            'vehicleNumber': _vehicleNumberController.text.trim(),
        };

        final success = await UserManagementService.instance.updateUserField(
          widget.rider.id,
          updateData,
        );

        if (success && mounted) {
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update rider'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating rider: ${e.toString()}'),
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
                    'Edit Rider',
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
                      // Email (read-only)
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
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
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                            borderSide: BorderSide.none,
                          ),
                        ),
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
                              onPressed: _isLoading ? null : _handleUpdate,
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
                                  : const Text('Update Rider'),
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
