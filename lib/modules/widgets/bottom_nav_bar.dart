import 'package:flutter/material.dart';
import '../../core/utils/tabler_icons_helper.dart';
import '../../styles/styles.dart';
import '../../styles/layouts/sizes.dart';
import '../../styles/typography/app_text_styles.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sizes.s8, horizontal: Sizes.s8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: TablerIconsHelper.homeOutline, activeIcon: TablerIconsHelper.home, label: 'Home', index: 0),
            _buildNavItem(icon: TablerIconsHelper.receipt, activeIcon: TablerIconsHelper.receipt, label: 'Orders', index: 1),
            _buildNavItem(icon: TablerIconsHelper.shoppingCart, activeIcon: TablerIconsHelper.shoppingCart, label: 'Cart', index: 2),
            _buildNavItem(icon: TablerIconsHelper.personOutline, activeIcon: TablerIconsHelper.person, label: 'Profile', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required IconData activeIcon, required String label, required int index}) {
    final isActive = currentIndex == index;

    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey('$index-$isActive'),
                    size: Sizes.s24,
                    color: isActive
                        ? const Color(0xFFFF6B35)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: Sizes.s4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyles.label.copyWith(
                    color: isActive
                        ? const Color(0xFFFF6B35)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: Sizes.s10,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
