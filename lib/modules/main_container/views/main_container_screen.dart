import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/notifications/services/notification_listener_service.dart';
import 'package:downtown/routes/route_constants.dart';
import '../viewmodels/main_container_viewmodel.dart';
import '../../home/views/home_screen.dart';
import '../../search/views/search_screen.dart';
import '../../orders/views/orders_screen.dart';
import '../../checkout/views/cart_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../widgets/role_based_bottom_nav_bar.dart';
import 'package:downtown/modules/auth/models/user_model.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
  
  // Use AutomaticKeepAliveClientMixin to maintain state
  static const bool maintainState = true;
}

class _MainContainerScreenState extends State<MainContainerScreen> with AutomaticKeepAliveClientMixin {
  late MainContainerViewModel _viewModel;
  late PageController _pageController;
  final _pushNotificationService = PushNotificationService.instance;
  DateTime? _lastBackPressTime;
  Timer? _backPressTimer;
  
  @override
  bool get wantKeepAlive => true;

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
    
    // Start listening for notifications
    _startNotificationListener();

    // If we landed here with openTrackOrderId (from payment success), open track order screen so back goes to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['openTrackOrderId'] != null) {
        Navigator.pushNamed(context, Routes.trackOrder, arguments: args['openTrackOrderId']);
      }
    });
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

  /// Start listening for notifications
  void _startNotificationListener() {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser?.id != null) {
      NotificationListenerService.instance.startListening(currentUser!.id!);
      debugPrint('Notification listener started for user: ${currentUser.id}');
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

  bool _handleBackPress() {
    final now = DateTime.now();
    
    // Check if back button was pressed within 2 seconds
    if (_lastBackPressTime != null && now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
      // Second back press - exit app
      _backPressTimer?.cancel();
      SystemNavigator.pop();
      return true;
    } else {
      // First back press - show message and set timer
      _lastBackPressTime = now;
      _backPressTimer?.cancel();
      _backPressTimer = Timer(const Duration(seconds: 2), () {
        _lastBackPressTime = null;
      });
      
      // Show snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true; // Prevent default back navigation
    }
  }

  @override
  void dispose() {
    _backPressTimer?.cancel();
    _viewModel.currentIndexNotifier.removeListener(_onTabChanged);
    DependencyInjection.instance.authController.removeListener(_onAuthChanged);
    NotificationListenerService.instance.stopListening();
    _viewModel.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
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
                  SearchScreen(),
                  CartScreen(),
                  OrdersScreen(),
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
              final authController = DependencyInjection.instance.authController;
              final userType = authController.currentUser?.userType ?? UserType.customer;
              
              return RoleBasedBottomNavBar(
                currentIndex: currentIndex,
                onTap: _viewModel.changeTab,
                userType: userType,
              );
            },
          ),
        ),
      ),
    );
  }
}
