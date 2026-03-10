import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/rider/services/rider_order_notification_service.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Navigation item model
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const NavItem({required this.icon, required this.activeIcon, required this.label, required this.index});
}

/// Reusable bottom navigation bar that adapts based on user type
class RoleBasedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserType userType;
  final String? riderId; // For rider-specific features

  const RoleBasedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userType,
    this.riderId,
  });

  @override
  State<RoleBasedBottomNavBar> createState() => _RoleBasedBottomNavBarState();
}

class _RoleBasedBottomNavBarState extends State<RoleBasedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasPendingOrders = false;
  DateTime? _lastTapTime;
  Timer? _doubleTapTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster animation for more noticeable effect
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start listening for pending orders if rider
    if (widget.userType == UserType.rider && widget.riderId != null) {
      _startListening();
    }
  }

  void _startListening() {
    RiderOrderNotificationService.instance.startListening(widget.riderId!);
    
    RiderOrderNotificationService.instance
        .getPendingOrdersCount(widget.riderId!)
        .listen((count) {
      if (mounted) {
        final hasPending = count > 0;
        if (_hasPendingOrders != hasPending) {
          setState(() {
            _hasPendingOrders = hasPending;
          });

          if (hasPending) {
            // Start fade animation - repeat continuously
            if (!_animationController.isAnimating) {
              _animationController.repeat(reverse: true);
            }
          } else {
            // Stop animation and reset opacity
            if (_animationController.isAnimating) {
              _animationController.stop();
            }
            _animationController.reset();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    if (widget.userType == UserType.rider) {
      RiderOrderNotificationService.instance.stopListening();
    }
    _doubleTapTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoleBasedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart listening if rider ID changed
    if (widget.userType == UserType.rider &&
        widget.riderId != null &&
        widget.riderId != oldWidget.riderId) {
      _startListening();
    }
  }

  /// Get navigation items based on user type
  List<NavItem> _getNavItems() {
    switch (widget.userType) {
      case UserType.admin:
        return [
          NavItem(icon: TablerIconsHelper.dashboard, activeIcon: TablerIconsHelper.dashboard, label: 'Dashboard', index: 0),
          NavItem(icon: TablerIconsHelper.receipt, activeIcon: TablerIconsHelper.receipt, label: 'Orders', index: 1),
          NavItem(icon: TablerIconsHelper.buildingStore, activeIcon: TablerIconsHelper.buildingStore, label: 'Restaurants', index: 2),
          NavItem(icon: TablerIconsHelper.category, activeIcon: TablerIconsHelper.category, label: 'Categories', index: 3),
          NavItem(icon: TablerIconsHelper.personOutline, activeIcon: TablerIconsHelper.person, label: 'Profile', index: 4),
        ];

      case UserType.rider:
        return [
          NavItem(icon: TablerIconsHelper.homeOutline, activeIcon: TablerIconsHelper.home, label: 'Home', index: 0),
          NavItem(icon: TablerIconsHelper.receipt, activeIcon: TablerIconsHelper.receipt, label: 'Orders', index: 1),
          NavItem(icon: TablerIconsHelper.personOutline, activeIcon: TablerIconsHelper.person, label: 'Profile', index: 2),
        ];

      case UserType.customer:
      default:
        return [
          NavItem(icon: TablerIconsHelper.homeOutline, activeIcon: TablerIconsHelper.home, label: 'Home', index: 0),
          NavItem(icon: TablerIconsHelper.search, activeIcon: TablerIconsHelper.search, label: 'Search', index: 1),
          NavItem(icon: TablerIconsHelper.shoppingCart, activeIcon: TablerIconsHelper.shoppingCart, label: 'Cart', index: 2),
          NavItem(icon: TablerIconsHelper.receipt, activeIcon: TablerIconsHelper.receipt, label: 'Orders', index: 3),
          NavItem(icon: TablerIconsHelper.personOutline, activeIcon: TablerIconsHelper.person, label: 'Profile', index: 4),
        ];
    }
  }

  /// Get accent color based on user type
  Color _getAccentColor() {
    switch (widget.userType) {
      case UserType.admin:
        return const Color(0xFF4CAF50); // Green for admin
      case UserType.rider:
        return const Color(0xFF2196F3); // Blue for rider
      case UserType.customer:
      default:
        return const Color(0xFFFF6B35); // Orange for customer
    }
  }

  void _handleDoubleTap() {
    final now = DateTime.now();
    
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      // Double tap detected - exit app
      _doubleTapTimer?.cancel();
      SystemNavigator.pop();
    } else {
      // First tap - set timer to reset
      _lastTapTime = now;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(milliseconds: 500), () {
        _lastTapTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems();
    final accentColor = _getAccentColor();

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: Opacity(
            opacity: _hasPendingOrders ? _fadeAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: Sizes.s8,
                    offset: const Offset(0, -Sizes.s2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Sizes.s8,
                    horizontal: widget.userType == UserType.admin ? Sizes.s4 : Sizes.s8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: navItems.map((item) {
                      return _buildNavItem(item: item, accentColor: accentColor);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({required NavItem item, required Color accentColor}) {
    final isActive = widget.currentIndex == item.index;

    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => widget.onTap(item.index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: widget.userType == UserType.admin ? Sizes.s8 : Sizes.s12, vertical: Sizes.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey('${item.index}-$isActive'),
                    size: widget.userType == UserType.admin ? Sizes.s22 : Sizes.s24,
                    color: isActive ? accentColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: Sizes.s4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.label.copyWith(
                    color: isActive ? accentColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: widget.userType == UserType.admin ? Sizes.s8 : Sizes.s10,
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
