import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:downtown/core/providers/theme_provider.dart';
import 'package:downtown/core/services/app_preferences_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/widgets/keyboard_dismisser.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _orderNotificationsEnabled = true;
  bool _promotionalNotificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Dismiss keyboard when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.dismissKeyboard();
      }
    });
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pushEnabled = await AppPreferencesService.isPushNotificationsEnabled();
      final orderEnabled = await AppPreferencesService.isOrderNotificationsEnabled();
      final promoEnabled = await AppPreferencesService.isPromotionalNotificationsEnabled();

      setState(() {
        _pushNotificationsEnabled = pushEnabled;
        _orderNotificationsEnabled = orderEnabled;
        _promotionalNotificationsEnabled = promoEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushNotificationsEnabled = value;
    });

    await AppPreferencesService.setPushNotificationsEnabled(value);

    if (value) {
      // Request permission if enabling
      final hasPermission = await PushNotificationService.instance.requestPermission();
      if (!hasPermission && mounted) {
        setState(() {
          _pushNotificationsEnabled = false;
        });
        await AppPreferencesService.setPushNotificationsEnabled(false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification permission denied. Please enable it in device settings.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).cardColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Save FCM token if permission granted
        final token = await PushNotificationService.instance.initializeAndGetToken();
        if (token != null) {
          await PushNotificationService.instance.saveTokenToFirestore(token);
        }
      }
    } else {
      // Remove token if disabling
      await PushNotificationService.instance.removeTokenByDeviceId();
    }
  }

  Future<void> _toggleOrderNotifications(bool value) async {
    setState(() {
      _orderNotificationsEnabled = value;
    });
    await AppPreferencesService.setOrderNotificationsEnabled(value);
  }

  Future<void> _togglePromotionalNotifications(bool value) async {
    setState(() {
      _promotionalNotificationsEnabled = value;
    });
    await AppPreferencesService.setPromotionalNotificationsEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: KeyboardDismisser(
        child: SafeArea(
          child: Column(
            children: [
              TopNavigationBar(title: 'Settings', showBackButton: true),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sizes.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Sizes.s8),

                      // Appearance Section
                      _buildSectionTitle('Appearance'),
                      const SizedBox(height: Sizes.s12),
                      _buildThemeToggle(),
                      const SizedBox(height: Sizes.s24),

                      // Notifications Section
                      _buildSectionTitle('Notifications'),
                      const SizedBox(height: Sizes.s12),
                      _buildNotificationSetting(
                        icon: TablerIconsHelper.bell,
                        iconColor: const Color(0xFFFF6B35),
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications on your device',
                        value: _pushNotificationsEnabled,
                        onChanged: _togglePushNotifications,
                      ),
                      const SizedBox(height: Sizes.s12),
                      _buildNotificationSetting(
                        icon: TablerIconsHelper.shoppingCart,
                        iconColor: Colors.blue,
                        title: 'Order Notifications',
                        subtitle: 'Get notified about your order status',
                        value: _orderNotificationsEnabled,
                        onChanged: _toggleOrderNotifications,
                        enabled: _pushNotificationsEnabled,
                      ),
                      const SizedBox(height: Sizes.s12),
                      _buildNotificationSetting(
                        icon: TablerIconsHelper.bell,
                        iconColor: Colors.purple,
                        title: 'Promotional Notifications',
                        subtitle: 'Receive offers, deals, and updates',
                        value: _promotionalNotificationsEnabled,
                        onChanged: _togglePromotionalNotifications,
                        enabled: _pushNotificationsEnabled,
                      ),
                      const SizedBox(height: Sizes.s24),

                      // About Section
                      _buildSectionTitle('About'),
                      const SizedBox(height: Sizes.s12),
                      _buildInfoCard(
                        icon: TablerIconsHelper.help,
                        iconColor: Colors.blue,
                        title: 'App Version',
                        subtitle: '1.0.0',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(Sizes.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: Sizes.s40,
                height: Sizes.s40,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Sizes.s8),
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.amber,
                  size: Sizes.s20,
                ),
              ),
              const SizedBox(width: Sizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s4),
                    Text(
                      themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                activeThumbColor: const Color(0xFFFF6B35),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationSetting({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: Sizes.s40,
              height: Sizes.s40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Sizes.s8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: Sizes.s20,
              ),
            ),
            const SizedBox(width: Sizes.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: Sizes.s4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: const Color(0xFFFF6B35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Sizes.s8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: Sizes.s20,
            ),
          ),
          const SizedBox(width: Sizes.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Sizes.s4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
