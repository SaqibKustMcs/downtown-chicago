import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/modules/notifications/services/notification_listener_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import '../../widgets/role_based_bottom_nav_bar.dart';
import 'rider_home_screen.dart';
import 'rider_orders_screen.dart';
import 'rider_profile_screen.dart';

class RiderMainScreen extends StatefulWidget {
  const RiderMainScreen({super.key});

  @override
  State<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends State<RiderMainScreen> {
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
      debugPrint('Notification listener started for rider: ${currentUser.id}');
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

  /// Initialize FCM token when rider reaches main screen
  Future<void> _initializeFcmToken() async {
    try {
      final pushService = PushNotificationService.instance;
      pushService.setupForegroundMessageHandler();
      final token = await pushService.initializeAndGetToken();
      if (token != null) {
        await pushService.saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error initializing FCM token for rider: $e');
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

    // Role guard - only riders can access
    if (currentUser == null || currentUser.userType != UserType.rider) {
      return RoleGuard.guard(
        context: context,
        requiredRole: UserType.rider,
        child: const SizedBox.shrink(),
        accessDeniedMessage: 'Access denied. Rider only.',
      );
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          RiderHomeScreen(),
          RiderOrdersScreen(),
          RiderProfileScreen(),
        ],
      ),
      bottomNavigationBar: RoleBasedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        userType: UserType.rider,
        riderId: currentUser?.id,
      ),
    );
  }
}
