import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/services/notification_listener_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import '../../widgets/role_based_bottom_nav_bar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_restaurants_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_profile_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeFcmToken();
    _startNotificationListener();
  }

  /// Start listening for notifications
  void _startNotificationListener() {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser?.id != null) {
      NotificationListenerService.instance.startListening(currentUser!.id!);
      debugPrint('Notification listener started for admin: ${currentUser.id}');
    }

    // Listen to auth changes
    authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser?.id != null) {
      NotificationListenerService.instance.startListening(currentUser!.id!);
    } else {
      NotificationListenerService.instance.stopListening();
    }
  }

  /// Initialize FCM token when admin reaches main screen
  Future<void> _initializeFcmToken() async {
    try {
      final pushService = PushNotificationService.instance;
      pushService.setupForegroundMessageHandler();
      final token = await pushService.initializeAndGetToken();
      if (token != null) {
        await pushService.saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error initializing FCM token for admin: $e');
    }
  }

  @override
  void dispose() {
    DependencyInjection.instance.authController.removeListener(_onAuthChanged);
    NotificationListenerService.instance.stopListening();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    // Role guard - only admins can access
    if (currentUser == null || currentUser.userType != UserType.admin) {
      return RoleGuard.guard(
        context: context,
        requiredRole: UserType.admin,
        child: const SizedBox.shrink(),
        accessDeniedMessage: 'Access denied. Admin only.',
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          AdminDashboardScreen(),
          AdminOrdersScreen(),
          AdminRestaurantsScreen(),
          AdminCategoriesScreen(),
          AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: RoleBasedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        userType: UserType.admin,
      ),
    );
  }
}
