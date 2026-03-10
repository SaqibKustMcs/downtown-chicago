import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class UserEditDialog extends StatefulWidget {
  final UserModel user;

  const UserEditDialog({
    super.key,
    required this.user,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  UserType _selectedUserType = UserType.customer;
  bool _isLoading = false;
  String _countryCode = '+92';
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name ?? '';
    _emailController.text = widget.user.email;
    _selectedUserType = widget.user.userType;
    final phone = widget.user.phoneNumber ?? '';
    if (phone.isNotEmpty) {
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(Sizes.s24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit User',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s24),

              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Enter user name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Email
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'Enter email address',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: Sizes.s4),
                            child: Text(
                              'Email cannot be changed',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s16),

                      // Phone
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number (Pakistan only)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          IntlPhoneField(
                            controller: _phoneController,
                            initialCountryCode: 'PK',
                            countries: countries.where((c) => c.code == 'PK').toList(),
                            decoration: InputDecoration(
                              hintText: 'Enter Pakistan phone number',
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
                        ],
                      ),
                      const SizedBox(height: Sizes.s16),

                      // User Type
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Type',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          DropdownButtonFormField<UserType>(
                            value: _selectedUserType,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Sizes.s12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: UserType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(_getUserTypeLabel(type)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedUserType = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Sizes.s24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: Sizes.s8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserTypeLabel(UserType type) {
    switch (type) {
      case UserType.admin:
        return 'Admin';
      case UserType.rider:
        return 'Rider';
      case UserType.customer:
        return 'Customer';
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
      final digits = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (digits.isNotEmpty) 'phoneNumber': '$_countryCode$digits',
        'userType': _selectedUserType.name,
      };

      final success = await UserManagementService.instance.updateUserField(
        widget.user.id,
        updates,
      );

      if (mounted) {
        Navigator.pop(context, success);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'User updated successfully'
                : 'Failed to update user'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
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
