import 'package:flutter/material.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/admin/services/admin_settings_service.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _adminSettingsService = AdminSettingsService.instance;
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final _defaultDeliveryFeeController = TextEditingController(text: '0');
  final _defaultPricePerKmController = TextEditingController(text: '5');
  final _riderPaymentPerKmController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _defaultDeliveryFeeController.dispose();
    _defaultPricePerKmController.dispose();
    _riderPaymentPerKmController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _adminSettingsService.getSettings();
      setState(() {
        _settings = settings;
        _defaultDeliveryFeeController.text = ((settings['defaultDeliveryFee'] ?? 0.0) as num).toStringAsFixed(2);
        _defaultPricePerKmController.text = ((settings['defaultDeliveryPricePerKm'] ?? 5.0) as num).toStringAsFixed(0);
        _riderPaymentPerKmController.text = ((settings['riderPaymentPerKm'] ?? 10.0) as num).toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _isSaving = true;
    });

    final success = await _adminSettingsService.updateSetting(key, value);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _settings[key] = value;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Setting updated' : 'Failed to update setting'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Admin Settings',
              showBackButton: true,
            ),

            // Settings Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(Sizes.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // System Settings
                          _buildSection(
                            title: 'System Settings',
                            icon: TablerIconsHelper.settings,
                            children: [
                              _buildSwitchTile(
                                title: 'Maintenance Mode',
                                subtitle: 'Disable app access for all users',
                                value: _settings['maintenanceMode'] ?? false,
                                onChanged: (value) => _updateSetting('maintenanceMode', value),
                              ),
                              _buildSwitchTile(
                                title: 'Allow New Registrations',
                                subtitle: 'Enable/disable new user signups',
                                value: _settings['allowNewRegistrations'] ?? true,
                                onChanged: (value) => _updateSetting('allowNewRegistrations', value),
                              ),
                              _buildSwitchTile(
                                title: 'Allow New Orders',
                                subtitle: 'Enable/disable order placement',
                                value: _settings['allowNewOrders'] ?? true,
                                onChanged: (value) => _updateSetting('allowNewOrders', value),
                              ),
                            ],
                          ),

                          const SizedBox(height: Sizes.s24),

                          // Order Settings
                          _buildSection(
                            title: 'Order Settings',
                            icon: TablerIconsHelper.receipt,
                            children: [
                              _buildTapTile(
                                title: 'Order status flow',
                                subtitle: 'View order status progression',
                                onTap: () => _showOrderStatusBottomSheet(context),
                              ),
                              _buildNumberInputTile(
                                title: 'Minimum Order Amount',
                                subtitle: 'Minimum order value required',
                                value: (_settings['minOrderAmount'] ?? 0.0).toDouble(),
                                onChanged: (value) => _updateSetting('minOrderAmount', value),
                                suffix: 'Rs.',
                              ),
                              _buildNumberInputTile(
                                title: 'Max Delivery Distance',
                                subtitle: 'Maximum delivery radius in km',
                                value: (_settings['maxDeliveryDistance'] ?? 10.0).toDouble(),
                                onChanged: (value) => _updateSetting('maxDeliveryDistance', value),
                                suffix: 'km',
                              ),
                              _buildTapTile(
                                title: 'Delivery fee',
                                subtitle: 'How delivery fee is calculated',
                                onTap: () => _showDeliveryFeeBottomSheet(context),
                              ),
                              _buildNumberInputTileWithSave(
                                key: 'defaultDeliveryFee',
                                title: 'Default delivery fee (fallback)',
                                subtitle: 'Used when distance is unknown. Change value then tap Save.',
                                controller: _defaultDeliveryFeeController,
                                suffix: 'Rs.',
                                formatDecimal: true,
                              ),
                              _buildNumberInputTileWithSave(
                                key: 'defaultDeliveryPricePerKm',
                                title: 'Base price per KM (Rs)',
                                subtitle: 'Default rate: fee = distance × this. Change value then tap Save.',
                                controller: _defaultPricePerKmController,
                                suffix: 'Rs./km',
                                formatDecimal: false,
                              ),
                              _buildSwitchTile(
                                title: 'Auto Accept Orders',
                                subtitle: 'Automatically accept new orders',
                                value: _settings['orderAutoAccept'] ?? false,
                                onChanged: (value) => _updateSetting('orderAutoAccept', value),
                              ),
                            ],
                          ),

                          const SizedBox(height: Sizes.s24),

                          // Notification Settings
                          _buildSection(
                            title: 'Notification Settings',
                            icon: TablerIconsHelper.bell,
                            children: [
                              _buildSwitchTile(
                                title: 'Enable Notifications',
                                subtitle: 'Enable in-app notifications',
                                value: _settings['enableNotifications'] ?? true,
                                onChanged: (value) => _updateSetting('enableNotifications', value),
                              ),
                              _buildSwitchTile(
                                title: 'Enable Push Notifications',
                                subtitle: 'Enable push notifications',
                                value: _settings['enablePushNotifications'] ?? true,
                                onChanged: (value) => _updateSetting('enablePushNotifications', value),
                              ),
                              _buildSwitchTile(
                                title: 'Enable Email Notifications',
                                subtitle: 'Send email notifications',
                                value: _settings['enableEmailNotifications'] ?? false,
                                onChanged: (value) => _updateSetting('enableEmailNotifications', value),
                              ),
                            ],
                          ),

                          const SizedBox(height: Sizes.s24),

                          // Rider Settings
                          _buildSection(
                            title: 'Rider Settings',
                            icon: TablerIconsHelper.truck,
                            children: [
                              _buildSwitchTile(
                                title: 'Auto Assign Riders',
                                subtitle: 'Automatically assign orders to available riders',
                                value: _settings['riderAutoAssign'] ?? false,
                                onChanged: (value) => _updateSetting('riderAutoAssign', value),
                              ),
                              _buildNumberInputTileWithSave(
                                key: 'riderPaymentPerKm',
                                title: 'Rider payment per KM (Rs)',
                                subtitle: 'Admin pays rider this amount per km (round-trip). Delivery fee stays with admin.',
                                controller: _riderPaymentPerKmController,
                                suffix: 'Rs./km',
                                formatDecimal: false,
                              ),
                            ],
                          ),

                          const SizedBox(height: Sizes.s24),

                          // App Info
                          _buildSection(
                            title: 'App Information',
                            icon: Icons.info_outline,
                            children: [
                              _buildInfoTile(
                                title: 'App Version',
                                value: _settings['appVersion'] ?? '1.0.0',
                              ),
                              _buildSwitchTile(
                                title: 'Force Update',
                                subtitle: 'Require users to update the app',
                                value: _settings['forceUpdate'] ?? false,
                                onChanged: (value) => _updateSetting('forceUpdate', value),
                              ),
                            ],
                          ),

                          const SizedBox(height: Sizes.s24),
                        ],
                      ),
                    ),
            ),

            // Saving Indicator
            if (_isSaving)
              Container(
                padding: const EdgeInsets.all(Sizes.s16),
                color: Theme.of(context).cardColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: Sizes.s12),
                    Text(
                      'Saving...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: Sizes.s20),
            const SizedBox(width: Sizes.s8),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Sizes.s12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTapTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
    );
  }

  Widget _buildNumberInputTileWithSave({
    required String key,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    String? suffix,
    bool formatDecimal = true,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.s8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s8),
              ),
            ),
          ),
          const SizedBox(width: Sizes.s8),
          FilledButton.tonal(
            onPressed: _isSaving
                ? null
                : () async {
                    final text = controller.text.trim();
                    final value = double.tryParse(text);
                    if (value == null || value < 0) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid number'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    await _updateSetting(key, value);
                    if (mounted) {
                      controller.text = formatDecimal ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
                    }
                  },
            child: const Text('Save'),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
    );
  }

  Widget _buildNumberInputTile({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    String? suffix,
  }) {
    final controller = TextEditingController(text: value.toStringAsFixed(2));
    
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s8),
          ),
          onSubmitted: (text) {
            final newValue = double.tryParse(text) ?? value;
            controller.text = newValue.toStringAsFixed(2);
            onChanged(newValue);
          },
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
    );
  }

  void _showOrderStatusBottomSheet(BuildContext context) {
    const statuses = [
      (OrderStatus.created, 'Created'),
      (OrderStatus.sentToAdmin, 'Sent to admin'),
      (OrderStatus.assignedToRider, 'Assigned to rider'),
      (OrderStatus.acceptedByRider, 'Accepted by rider'),
      (OrderStatus.pickedUp, 'Picked up'),
      (OrderStatus.onTheWay, 'On the way'),
      (OrderStatus.nearAddress, 'Near address'),
      (OrderStatus.atLocation, 'At location'),
      (OrderStatus.delivered, 'Delivered'),
      (OrderStatus.cancelled, 'Cancelled'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Sizes.s16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(Sizes.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Sizes.s16),
              Text(
                'Order status flow',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Sizes.s8),
              Text(
                'Orders move through these statuses. You can update status from Admin Orders.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: Sizes.s16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: statuses.length,
                  itemBuilder: (_, i) {
                    final (status, label) = statuses[i];
                    final isLast = i == statuses.length - 1;
                    final isCancelled = status == OrderStatus.cancelled;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? Colors.red.shade100
                                    : Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 24,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                          ],
                        ),
                        const SizedBox(width: Sizes.s12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: Sizes.s20),
                          child: Text(
                            label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryFeeBottomSheet(BuildContext context) {
    final defaultFee = (_settings['defaultDeliveryFee'] ?? 0.0).toDouble();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Sizes.s16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          Sizes.s16,
          Sizes.s16,
          Sizes.s16,
          Sizes.s16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Sizes.s16),
            Text(
              'Delivery fee',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Sizes.s12),
            Text(
              'Fee is calculated at checkout using distance from restaurant to customer address (like Foodpanda):',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: Sizes.s12),
            Container(
              padding: const EdgeInsets.all(Sizes.s12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(Sizes.s8),
              ),
              child: Text(
                'Delivery fee = distance (km) × price per KM',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: Sizes.s12),
            Text(
              '• Price per KM is set per restaurant in Create/Edit Restaurant (“Delivery price per KM (Rs)”).',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: Sizes.s4),
            Text(
              '• If distance or location is missing, the fallback “Default delivery fee” is used.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: Sizes.s4),
            Text(
              '• “Default price per KM” is used when a restaurant has no own rate. Set both in Order Settings above and tap Save after changing.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: Sizes.s16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current default (fallback)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                Text(
                  'Rs. ${defaultFee.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.s12),
            Container(
              padding: const EdgeInsets.all(Sizes.s12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(Sizes.s8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: Sizes.s8),
                  Expanded(
                    child: Text(
                      'To update: in Order Settings above, edit "Default delivery fee (fallback)" or "Base price per KM (Rs)", then tap the Save button next to each field.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
