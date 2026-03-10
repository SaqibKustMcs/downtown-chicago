import 'dart:async';
import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/services/notification_listener_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/widgets/restaurant_card.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:provider/provider.dart';
import 'package:downtown/core/providers/theme_provider.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    DependencyInjection.instance.authController.addListener(_onAuthStateChanged);
    _loadUserData();
  }

  @override
  void dispose() {
    DependencyInjection.instance.authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DependencyInjection.instance.authController.refreshUser();
    } catch (e) {
      debugPrint('Error loading user data: $e');
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser == null || currentUser.userType != UserType.admin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Access denied. Admin only.')),
      );
    }

    final userName = currentUser.name ?? 'Admin';
    final userBio = currentUser.bio ?? '';
    final userImage = currentUser.userImage ?? currentUser.photoUrl;
    final restaurantId = currentUser.restaurantId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Navigation
              TopNavigationBar(title: 'Admin Profile', showBackButton: false),

              // User Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s24),
                child: Row(
                  children: [
                    // Profile Picture
                    ClipOval(
                      child: NetworkImageWidget(
                        imageUrl: userImage ?? '',
                        width: Sizes.s80,
                        height: Sizes.s80,
                        fit: BoxFit.cover,
                        errorIcon: TablerIconsHelper.person,
                        errorIconSize: Sizes.s40,
                      ),
                    ),
                    const SizedBox(width: Sizes.s16),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              const SizedBox(width: Sizes.s8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
                                decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.2), borderRadius: BorderRadius.circular(Sizes.s8)),
                                child: Text(
                                  'Admin',
                                  style: AppTextStyles.label.copyWith(color: const Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: Sizes.s10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Sizes.s4),
                          Text(
                            userBio.isNotEmpty ? userBio : 'Restaurant Administrator',
                            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          if (restaurantId != null) ...[
                            const SizedBox(height: Sizes.s4),
                            Text(
                              'Restaurant ID: ${restaurantId.substring(0, 8)}...',
                              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
                child: Column(
                  children: [
                    // Personal Information
                    _buildMenuGroup(context, [
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.person,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Personal Info',
                        onTap: () async {
                          final result = await Navigator.pushNamed(context, Routes.editProfile);
                          if (result == true && mounted) {
                            await _loadUserData();
                          }
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.bell,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Notifications',
                        onTap: () {
                          Navigator.pushNamed(context, Routes.notifications);
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.bell,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Send Notification',
                        onTap: () {
                          Navigator.pushNamed(context, Routes.sendNotification);
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.users,
                        iconColor: Colors.blue,
                        title: 'User Management',
                        onTap: () {
                          Navigator.pushNamed(context, Routes.adminUsers);
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.truck,
                        iconColor: Colors.orange,
                        title: 'Riders Management',
                        onTap: () {
                          // Only admins can access this screen (additional guard in AdminRidersScreen)
                          Navigator.pushNamed(context, Routes.adminRiders);
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.star,
                        iconColor: Colors.amber,
                        title: 'Product Reviews',
                        onTap: () {
                          Navigator.pushNamed(context, Routes.adminReviews);
                        },
                      ),
                    ]),

                    const SizedBox(height: Sizes.s16),

                    // Settings
                    _buildMenuGroup(context, [
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.settings,
                        iconColor: Colors.purple,
                        title: 'Settings',
                        onTap: () {
                          Navigator.pushNamed(context, Routes.adminSettings);
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.lock_outline,
                        iconColor: Colors.blue,
                        title: 'Change Password',
                        onTap: () {
                          Navigator.pushNamed(context, Routes.changePassword);
                        },
                      ),
                      _buildThemeToggleItem(context),
                    ]),

                    const SizedBox(height: Sizes.s16),

                    // Log Out
                    _buildMenuGroup(context, [
                      _buildMenuItem(
                        context: context,
                        icon: TablerIconsHelper.logout,
                        iconColor: Colors.red,
                        title: 'Log Out',
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ]),

                    const SizedBox(height: Sizes.s24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Sizes.s12)),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({required BuildContext context, required IconData icon, required Color iconColor, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Sizes.s8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(Sizes.s8)),
              child: Icon(icon, color: iconColor, size: Sizes.s20),
            ),
            const SizedBox(width: Sizes.s16),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            ),
            Icon(TablerIconsHelper.chevronRight, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: Sizes.s20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleItem(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return InkWell(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Sizes.s8),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(Sizes.s8)),
                  child: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.amber, size: Sizes.s20),
                ),
                const SizedBox(width: Sizes.s16),
                Expanded(
                  child: Text(themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                ),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s16)),
          title: Text('Log Out', style: AppTextStyles.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          content: Text('Are you sure you want to log out?', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleLogout(context);
              },
              child: Text(
                'Log Out',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (!context.mounted) return;

    final authController = DependencyInjection.instance.authController;
    authController.removeListener(_onAuthStateChanged);

    // Stop notification listener immediately to prevent notifications after logout
    NotificationListenerService.instance.stopListening();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }

    unawaited(
      FirebaseService.auth.signOut().catchError((e) {
        debugPrint('Firebase signOut error: $e');
      }),
    );

    unawaited(
      PushNotificationService.instance.removeTokenByDeviceId().catchError((e) {
        debugPrint('Error removing FCM token: $e');
      }),
    );

    DependencyInjection.instance.favoritesController.clearFavorites();
  }
}
