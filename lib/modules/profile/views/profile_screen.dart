import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:downtown/core/providers/theme_provider.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/services/secure_storage_service.dart';
import 'package:downtown/core/services/app_preferences_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/services/notification_listener_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/widgets/restaurant_card.dart';
import 'package:downtown/core/widgets/keyboard_dismisser.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false; // Flag to prevent infinite loop

  @override
  void initState() {
    super.initState();
    // Dismiss keyboard when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.dismissKeyboard();
      }
    });
    // Listen to auth state changes to update profile
    DependencyInjection.instance.authController.addListener(_onAuthStateChanged);
    // Load user data when screen initializes
    _loadUserData();
  }

  @override
  void dispose() {
    DependencyInjection.instance.authController.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    // Prevent infinite loop: don't refresh if we're already refreshing
    if (mounted && !_isRefreshing) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    // Prevent recursive calls
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      // Refresh user data from Firestore
      // Add a small delay to ensure any FCM token operations complete first
      await Future.delayed(const Duration(milliseconds: 100));
      await DependencyInjection.instance.authController.refreshUser();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // If refresh fails, try again after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isRefreshing) {
        try {
          await DependencyInjection.instance.authController.refreshUser();
        } catch (retryError) {
          debugPrint('Error retrying user data load: $retryError');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
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

    // Get user data
    final userName = currentUser?.name ?? 'User';
    final userBio = currentUser?.bio ?? '';
    final userImage = currentUser?.userImage ?? currentUser?.photoUrl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: KeyboardDismisser(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Navigation
                TopNavigationBar(title: 'Profile', showBackButton: widget.showBackButton),

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
                            Text(
                              userName,
                              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: Sizes.s4),
                            Text(
                              userBio.isNotEmpty ? userBio : 'No bio yet',
                              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            ),
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
                      // Note: Admin and Rider hubs are now accessed via bottom navigation

                      // First Group - Personal Information
                      _buildMenuGroup(context, [
                        _buildMenuItem(
                          context: context,
                          icon: TablerIconsHelper.person,
                          iconColor: const Color(0xFFFF6B35),
                          title: 'Personal Info',
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, Routes.editProfile);
                            // Refresh profile if updated
                            if (result == true && mounted) {
                              await _loadUserData();
                            }
                          },
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: TablerIconsHelper.location,
                          iconColor: Colors.blue,
                          title: 'Addresses',
                          onTap: () {
                            Navigator.pushNamed(context, Routes.addresses);
                          },
                        ),
                      ]),

                      const SizedBox(height: Sizes.s16),

                      // Second Group - App Features
                      _buildMenuGroup(context, [
                        _buildMenuItem(
                          context: context,
                          icon: TablerIconsHelper.shoppingCart,
                          iconColor: Colors.blue,
                          title: 'Cart',
                          onTap: () {
                            Navigator.pushNamed(context, Routes.cart);
                          },
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: TablerIconsHelper.favorite,
                          iconColor: Colors.purple,
                          title: 'Favourite',
                          onTap: () {
                            Navigator.pushNamed(context, Routes.favorites);
                          },
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: TablerIconsHelper.bell,
                          iconColor: const Color(0xFFFF6B35),
                          title: 'Notifications',
                          onTap: () {
                            Navigator.pushNamed(context, Routes.notifications);
                          },
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: TablerIconsHelper.payment,
                          iconColor: Colors.blue,
                          title: 'Payment Method',
                          onTap: () {
                            Navigator.pushNamed(context, Routes.paymentMethods);
                          },
                        ),
                      ]),

                      const SizedBox(height: Sizes.s16),

                      // Third Group - Support & Settings
                      RepaintBoundary(
                        child: _buildMenuGroup(
                          context,
                          [
                            _buildMenuItem(
                              context: context,
                              icon: TablerIconsHelper.help,
                              iconColor: const Color(0xFFFF6B35),
                              title: 'FAQs',
                              onTap: () {
                                Navigator.pushNamed(context, Routes.faqs);
                              },
                            ),
                            // Show User Reviews only for admin/rider, not for customers
                            if (currentUser?.userType != UserType.customer)
                              _buildMenuItem(
                                context: context,
                                icon: TablerIconsHelper.star,
                                iconColor: Colors.teal,
                                title: 'User Reviews',
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.userReviews);
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
                            _buildMenuItem(
                              context: context,
                              icon: TablerIconsHelper.settings,
                              iconColor: Colors.purple,
                              title: 'Settings',
                              onTap: () {
                                Navigator.pushNamed(context, Routes.settings);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Sizes.s16),

                      // Fourth Group - Log Out & Delete Account
                      RepaintBoundary(
                        child: _buildMenuGroup(context, [
                          _buildMenuItem(
                            context: context,
                            icon: TablerIconsHelper.logout,
                            iconColor: Colors.red,
                            title: 'Log Out',
                            onTap: () {
                              _showLogoutDialog(context);
                            },
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.delete_forever,
                            iconColor: Colors.red.shade700,
                            title: 'Delete Account',
                            onTap: () {
                              _showDeleteAccountDialog(context);
                            },
                          ),
                        ]),
                      ),

                      const SizedBox(height: Sizes.s24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<Widget> items) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(color: brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({required BuildContext context, required IconData icon, required Color iconColor, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Sizes.s16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
        child: Row(
          children: [
            // Icon
            Container(
              width: Sizes.s40,
              height: Sizes.s40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(Sizes.s8)),
              child: Icon(icon, color: iconColor, size: Sizes.s20),
            ),
            const SizedBox(width: Sizes.s16),

            // Title
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),

            // Arrow
            Icon(TablerIconsHelper.chevronRight, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: Sizes.s20),
          ],
        ),
      ),
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

    // CRITICAL: Remove listener BEFORE navigation to prevent notifyListeners()
    // from trying to update widgets that are no longer in the tree
    final authController = DependencyInjection.instance.authController;
    authController.removeListener(_onAuthStateChanged);

    // Stop notification listener immediately to prevent notifications after logout
    NotificationListenerService.instance.stopListening();

    // Step 1: Navigate FIRST - before any async operations
    // This ensures the user sees the login screen immediately
    // and prevents any widget updates after navigation
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }

    // Step 2: Sign out from Firebase in the background (fire and forget)
    // This happens after navigation, so notifyListeners() won't affect the old screen
    unawaited(
      FirebaseService.auth.signOut().catchError((e) {
        debugPrint('Firebase signOut error: $e');
      }),
    );

    // Step 3: Remove FCM token for this device
    unawaited(
      PushNotificationService.instance.removeTokenByDeviceId().catchError((e) {
        debugPrint('Error removing FCM token: $e');
      }),
    );

    // Step 4: Clear favorites
    DependencyInjection.instance.favoritesController.clearFavorites();

    // Step 5: Clear local storage in the background (fire and forget)
    // Clear storage directly without going through controller to avoid notifyListeners
    unawaited(
      _clearLocalStorageSilently().catchError((e) {
        debugPrint('Background logout cleanup error: $e');
      }),
    );
  }

  /// Clear local storage silently without triggering UI updates
  Future<void> _clearLocalStorageSilently() async {
    try {
      // Clear secure storage
      await Future.wait([SecureStorageService.delete('current_user'), SecureStorageService.delete('auth_token'), AppPreferencesService.clearAuthToken()]);

      // Update controller state without calling notifyListeners
      // This prevents trying to update widgets that are no longer in the tree
      final authController = DependencyInjection.instance.authController;
      // Use reflection or direct access if possible, otherwise just let it be
      // The controller will update on next access anyway
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: Sizes.s24),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: Text('Delete Account', style: AppTextStyles.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Sizes.s12),
              Text(
                'This action cannot be undone. All your data including:\n• Profile information\n• Order history\n• Saved addresses\n• Payment methods\n\nwill be permanently deleted.',
                style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
              ),
            ],
          ),
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
                await _handleDeleteAccount(context);
              },
              child: Text(
                'Delete Account',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    // Show second confirmation dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s16)),
          title: Text('Final Confirmation', style: AppTextStyles.heading2.copyWith(color: Colors.red)),
          content: Text(
            'This is your last chance to cancel. Your account will be permanently deleted. Are you absolutely sure?',
            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                'Yes, Delete Forever',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final authController = DependencyInjection.instance.authController;
      final currentUser = authController.currentUser;
      final userId = currentUser?.id;

      // Remove all FCM tokens for this user before deleting account
      if (userId != null) {
        await PushNotificationService.instance.removeAllTokensForUser(userId);
      }

      final success = await authController.deleteAccount();

      if (context.mounted) {
        // Close loading indicator
        Navigator.of(context).pop();

        if (success) {
          // Navigate to login screen and clear navigation stack
          Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);

          // Show success message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Your account has been permanently deleted'), backgroundColor: Colors.green, duration: Duration(seconds: 3)));
        } else {
          // Show error message
          final errorMsg = authController.error ?? 'Failed to delete account. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        // Close loading indicator if still open
        Navigator.of(context).pop();

        String errorMessage = 'Failed to delete account. Please try again.';

        switch (e.code) {
          case 'requires-recent-login':
            errorMessage = 'For security reasons, please log out and log back in before deleting your account.';
            break;
          default:
            errorMessage = e.message ?? 'Failed to delete account. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading indicator if still open
        Navigator.of(context).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    }
  }
}
