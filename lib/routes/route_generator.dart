import 'package:flutter/material.dart';
import 'package:food_flow_app/core/utils/page_transitions.dart';
import 'package:food_flow_app/modules/auth/views/forgot_password_screen.dart';
import 'package:food_flow_app/modules/auth/views/forgot_password_verification_screen.dart';
import 'package:food_flow_app/modules/auth/views/login_screen.dart';
import 'package:food_flow_app/modules/auth/views/password_reset_success_screen.dart';
import 'package:food_flow_app/modules/auth/views/signup_screen.dart';
import 'package:food_flow_app/modules/auth/views/update_password_screen.dart';
import 'package:food_flow_app/modules/auth/views/update_profile_screen.dart';
import 'package:food_flow_app/modules/auth/views/verification_screen.dart';
import 'package:food_flow_app/modules/auth/views/verification_success_screen.dart';
import 'package:food_flow_app/models/food_item_model.dart';
import 'package:food_flow_app/models/restaurant_model.dart';
import 'package:food_flow_app/modules/home/views/all_categories_screen.dart';
import 'package:food_flow_app/modules/home/views/all_restaurants_screen.dart';
import 'package:food_flow_app/modules/home/views/category_detail_screen.dart';
import 'package:food_flow_app/modules/home/views/item_detail_screen.dart';
import 'package:food_flow_app/modules/home/views/restaurant_view_screen.dart';
import 'package:food_flow_app/modules/location/views/location_permission_screen.dart';
import 'package:food_flow_app/modules/chat/views/chat_screen.dart';
import 'package:food_flow_app/modules/checkout/views/add_card_screen.dart';
import 'package:food_flow_app/modules/checkout/views/cart_screen.dart';
import 'package:food_flow_app/modules/checkout/views/payment_screen.dart';
import 'package:food_flow_app/modules/checkout/views/payment_success_screen.dart';
import 'package:food_flow_app/modules/orders/views/track_order_screen.dart';
import 'package:food_flow_app/modules/profile/views/change_password_screen.dart';
import 'package:food_flow_app/modules/profile/views/edit_profile_screen.dart';
import 'package:food_flow_app/modules/profile/views/favorite_items_screen.dart';
import 'package:food_flow_app/modules/profile/views/faqs_screen.dart';
import 'package:food_flow_app/modules/profile/views/notifications_screen.dart';
import 'package:food_flow_app/modules/profile/views/payment_methods_screen.dart';
import 'package:food_flow_app/modules/profile/views/profile_screen.dart';
import 'package:food_flow_app/modules/admin/views/admin_hub_screen.dart';
import 'package:food_flow_app/modules/admin/views/create_restaurant_screen.dart';
import 'package:food_flow_app/modules/admin/views/manage_categories_screen.dart';
import 'package:food_flow_app/modules/admin/views/add_product_screen.dart';
import 'package:food_flow_app/modules/main_container/views/main_container_screen.dart';
import 'package:food_flow_app/modules/onboarding/views/onboarding_screen.dart';
import 'package:food_flow_app/modules/search/views/search_screen.dart';
import 'package:food_flow_app/modules/splash/splash_screen.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import '../styles/typography/app_text_styles.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case Routes.initial:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);

      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);

      case Routes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen(), settings: settings);

      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);

      case Routes.signUp:
        return MaterialPageRoute(builder: (_) => const SignUpScreen(), settings: settings);

      case Routes.verification:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => VerificationScreen(email: args),
            settings: settings,
          );
        }
        return _errorRoute('Email is required for verification screen');

      case Routes.verificationSuccess:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => VerificationSuccessScreen(email: args),
            settings: settings,
          );
        }
        return _errorRoute('Email is required for verification success screen');

      case Routes.updateProfile:
        return MaterialPageRoute(
          builder: (_) => const UpdateProfileScreen(),
          settings: settings,
        );

      case Routes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen(), settings: settings);

      case Routes.forgotPasswordVerification:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ForgotPasswordVerificationScreen(email: args),
            settings: settings,
          );
        }
        return _errorRoute('Email is required for forgot password verification screen');

      case Routes.updatePassword:
        if (args is String || args is Map) {
          return MaterialPageRoute(
            builder: (_) => UpdatePasswordScreen(arguments: args),
            settings: settings,
          );
        }
        return _errorRoute('Email is required for update password screen');

      case Routes.passwordResetSuccess:
        return MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen(), settings: settings);

      case Routes.locationPermission:
        return MaterialPageRoute(builder: (_) => const LocationPermissionScreen(), settings: settings);

      case Routes.home:
        return MaterialPageRoute(builder: (_) => const MainContainerScreen(), settings: settings);

      case Routes.mainContainer:
        return MaterialPageRoute(builder: (_) => const MainContainerScreen(), settings: settings);

      case Routes.search:
        return PageTransitions.slideFromRight(
          page: const SearchScreen(),
          settings: settings,
        );

      case Routes.categoryDetail:
        if (args is String) {
          return PageTransitions.slideFromRight(
            page: CategoryDetailScreen(categoryName: args),
            settings: settings,
          );
        }
        return _errorRoute('Category name is required for category detail screen');

      case Routes.allCategories:
        return PageTransitions.slideFromRight(
          page: const AllCategoriesScreen(),
          settings: settings,
        );

      case Routes.allRestaurants:
        return PageTransitions.slideFromRight(
          page: const AllRestaurantsScreen(),
          settings: settings,
        );

      case Routes.restaurantView:
        if (args is Restaurant) {
          return PageTransitions.scale(
            page: RestaurantViewScreen(restaurant: args),
            settings: settings,
          );
        }
        return _errorRoute('Restaurant data is required for restaurant view screen');

      case Routes.itemDetail:
        if (args is FoodItem) {
          return PageTransitions.scale(
            page: ItemDetailScreen(foodItem: args),
            settings: settings,
          );
        }
        return _errorRoute('Food item data is required for item detail screen');

      case Routes.trackOrder:
        return PageTransitions.slideFromRight(
          page: const TrackOrderScreen(),
          settings: settings,
        );

      case Routes.profile:
        if (args is bool) {
          return PageTransitions.slideFromRight(
            page: ProfileScreen(showBackButton: args),
            settings: settings,
          );
        }
        return PageTransitions.slideFromRight(
          page: const ProfileScreen(showBackButton: false),
          settings: settings,
        );

      case Routes.editProfile:
        return PageTransitions.slideFromRight(
          page: const EditProfileScreen(),
          settings: settings,
        );

      case Routes.changePassword:
        return PageTransitions.slideFromRight(
          page: const ChangePasswordScreen(),
          settings: settings,
        );

      case Routes.favorites:
        return PageTransitions.slideFromRight(
          page: const FavoriteItemsScreen(),
          settings: settings,
        );

      case Routes.faqs:
        return PageTransitions.slideFromRight(
          page: const FAQsScreen(),
          settings: settings,
        );

      case Routes.notifications:
        return PageTransitions.slideFromRight(
          page: const NotificationsScreen(),
          settings: settings,
        );

      case Routes.chat:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(contactName: args['contactName'] ?? 'Contact', contactAvatarUrl: args['contactAvatarUrl']),
            settings: settings,
          );
        }
        return _errorRoute('Contact name is required for chat screen');

      case Routes.cart:
        return PageTransitions.slideFromRight(
          page: const CartScreen(),
          settings: settings,
        );

      case Routes.payment:
        if (args is double) {
          return PageTransitions.slideFromRight(
            page: PaymentScreen(totalAmount: args),
            settings: settings,
          );
        }
        return _errorRoute('Total amount is required for payment screen');

      case Routes.paymentMethods:
        return PageTransitions.slideFromRight(
          page: const PaymentMethodsScreen(),
          settings: settings,
        );

      case Routes.addCard:
        return PageTransitions.slideFromRight(
          page: const AddCardScreen(),
          settings: settings,
        );

      case Routes.paymentSuccess:
        if (args is double) {
          return PageTransitions.fade(
            page: PaymentSuccessScreen(totalAmount: args),
            settings: settings,
          );
        }
        return _errorRoute('Total amount is required for payment success screen');

      case Routes.adminHub:
        return PageTransitions.slideFromRight(
          page: const AdminHubScreen(),
          settings: settings,
        );

      case Routes.createRestaurant:
        return PageTransitions.slideFromRight(
          page: const CreateRestaurantScreen(),
          settings: settings,
        );

      case Routes.manageCategories:
        return PageTransitions.slideFromRight(
          page: const ManageCategoriesScreen(),
          settings: settings,
        );

      case Routes.addProduct:
        if (args is Map<String, dynamic>) {
          return PageTransitions.slideFromRight(
            page: AddProductScreen(
              restaurantId: args['restaurantId'],
              restaurantName: args['restaurantName'],
            ),
            settings: settings,
          );
        }
        return PageTransitions.slideFromRight(
          page: const AddProductScreen(),
          settings: settings,
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute([String? message]) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error'), backgroundColor: const Color(0xFF2E2739)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(message ?? 'Page not found', style: AppTextStyles.heading2, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}
