import 'package:flutter/material.dart';
import 'package:food_flow_app/core/services/push_notification_service.dart';
import 'package:food_flow_app/core/di/dependency_injection.dart';
import '../viewmodels/main_container_viewmodel.dart';
import '../../home/views/home_screen.dart';
import '../../orders/views/orders_screen.dart';
import '../../checkout/views/cart_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  late MainContainerViewModel _viewModel;
  late PageController _pageController;
  final _pushNotificationService = PushNotificationService.instance;

  @override
  void initState() {
    super.initState();
    _viewModel = MainContainerViewModel();
    _pageController = PageController(initialPage: 0);
    
    // Listen to tab changes and update page controller
    _viewModel.currentIndexNotifier.addListener(_onTabChanged);
    
    // Initialize push notifications when user reaches main container
    _initializePushNotifications();
    
    // Initialize favorites when user reaches main container
    _initializeFavorites();
  }
  
  /// Initialize push notifications - request permissions and save token
  Future<void> _initializePushNotifications() async {
    try {
      // Setup foreground message handler
      _pushNotificationService.setupForegroundMessageHandler();
      
      // Request permissions and get token
      final token = await _pushNotificationService.initializeAndGetToken();
      
      if (token != null) {
        // Save token to Firestore with device ID
        await _pushNotificationService.saveTokenToFirestore(token);
        debugPrint('Push notifications initialized successfully');
      } else {
        debugPrint('Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Initialize favorites for current user
  Future<void> _initializeFavorites() async {
    try {
      final authController = DependencyInjection.instance.authController;
      final currentUser = authController.currentUser;

      if (currentUser?.id != null) {
        final favoritesController = DependencyInjection.instance.favoritesController;
        await favoritesController.initialize(currentUser!.id!);
        debugPrint('Favorites initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing favorites: $e');
    }
  }

  void _onTabChanged() {
    final currentIndex = _viewModel.currentIndexNotifier.value;
    if (_pageController.hasClients && _pageController.page?.round() != currentIndex) {
      _pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    _viewModel.changeTab(index);
  }

  @override
  void dispose() {
    _viewModel.currentIndexNotifier.removeListener(_onTabChanged);
    _viewModel.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: ValueListenableBuilder<int>(
          valueListenable: _viewModel.currentIndexNotifier,
          builder: (context, currentIndex, child) {
            return PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: const [
                HomeScreen(),
                OrdersScreen(),
                CartScreen(),
                ProfileScreen(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: RepaintBoundary(
        child: ValueListenableBuilder<int>(
          valueListenable: _viewModel.currentIndexNotifier,
          builder: (context, currentIndex, child) {
            return CustomBottomNavBar(
              currentIndex: currentIndex,
              onTap: _viewModel.changeTab,
            );
          },
        ),
      ),
    );
  }
}
