import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/routes/route_constants.dart';

/// Role-based access control guard
/// Prevents unauthorized access to role-specific screens
class RoleGuard {
  RoleGuard._();

  /// Check if user has required role
  static bool hasRequiredRole(UserType? userType, UserType requiredType) {
    return userType == requiredType;
  }

  /// Check if user is admin
  static bool isAdmin(UserType? userType) {
    return userType == UserType.admin;
  }

  /// Check if user is rider
  static bool isRider(UserType? userType) {
    return userType == UserType.rider;
  }

  /// Check if user is customer
  static bool isCustomer(UserType? userType) {
    return userType == UserType.customer;
  }

  /// Redirect user to appropriate screen based on role
  static void redirectToRoleScreen(BuildContext context, UserType? userType) {
    if (context.mounted) {
      String route;
      switch (userType) {
        case UserType.admin:
          route = Routes.adminMain;
          break;
        case UserType.rider:
          route = Routes.riderMain;
          break;
        case UserType.customer:
        default:
          route = Routes.mainContainer;
          break;
      }
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    }
  }

  /// Show access denied dialog and redirect
  static void showAccessDeniedDialog(
    BuildContext context,
    String message,
    UserType? userType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              redirectToRoleScreen(context, userType);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Guard widget that checks role before showing content
  static Widget guard({
    required BuildContext context,
    required UserType requiredRole,
    required Widget child,
    String? accessDeniedMessage,
  }) {
    final authController = DependencyInjection.instance.authController;
    final currentUser = authController.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Please login to access this screen'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.login,
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasRequiredRole(currentUser.userType, requiredRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAccessDeniedDialog(
          context,
          accessDeniedMessage ??
              'You do not have permission to access this screen.',
          currentUser.userType,
        );
      });

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                accessDeniedMessage ??
                    'Access denied. ${_getRoleName(requiredRole)} only.',
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }

  static String _getRoleName(UserType role) {
    switch (role) {
      case UserType.admin:
        return 'Admin';
      case UserType.rider:
        return 'Rider';
      case UserType.customer:
        return 'Customer';
    }
  }
}
