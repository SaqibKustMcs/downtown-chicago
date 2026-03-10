import 'package:flutter/material.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Admin Hub',
              showBackButton: true,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Sizes.s16),

                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(Sizes.s20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900.withOpacity(0.3)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(Sizes.s16),
                        border: Border.all(
                          color: isDark
                              ? Colors.orange.shade700
                              : Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: Sizes.s40,
                            color: isDark
                                ? Colors.orange.shade300
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: Sizes.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Dashboard',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: isDark
                                        ? Colors.orange.shade200
                                        : Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: Sizes.s4),
                                Text(
                                  'Manage your restaurant and orders',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? Colors.orange.shade300
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Sizes.s24),

                    // Admin Features Grid
                    Text(
                      'Admin Features',
                      style: AppTextStyles.heading3.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Sizes.s16),

                    // Features Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: Sizes.s12,
                      mainAxisSpacing: Sizes.s12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.restaurant,
                          title: 'Restaurant',
                          subtitle: 'Manage menu',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.createRestaurant);
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.fastfood,
                          title: 'Products',
                          subtitle: 'Add products',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.addProduct);
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.category,
                          title: 'Categories',
                          subtitle: 'Manage categories',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.manageCategories);
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.shopping_bag,
                          title: 'Orders',
                          subtitle: 'View orders',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.adminOrders);
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.analytics,
                          title: 'Analytics',
                          subtitle: 'View stats',
                          color: Colors.purple,
                          onTap: () {
                            // TODO: Navigate to analytics
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Analytics coming soon'),
                              ),
                            );
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.people,
                          title: 'Riders',
                          subtitle: 'Manage riders',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.adminRiders);
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.inventory,
                          title: 'Inventory',
                          subtitle: 'Stock management',
                          color: Colors.teal,
                          onTap: () {
                            // TODO: Navigate to inventory
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inventory management coming soon'),
                              ),
                            );
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.star_rate,
                          title: 'Reviews',
                          subtitle: 'Manage reviews',
                          color: Colors.amber,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.adminReviews);
                          },
                        ),
                        _buildAdminFeatureCard(
                          context: context,
                          icon: Icons.settings,
                          title: 'Settings',
                          subtitle: 'Admin settings',
                          color: Colors.grey,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.adminSettings);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: Sizes.s24),

                    // Quick Stats Section
                    Text(
                      'Quick Stats',
                      style: AppTextStyles.heading3.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Sizes.s16),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            title: 'Today Orders',
                            value: '0',
                            icon: Icons.shopping_cart,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: Sizes.s12),
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            title: 'Pending',
                            value: '0',
                            icon: Icons.pending,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sizes.s12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            title: 'Revenue',
                            value: 'Rs. 0',
                            icon: Icons.attach_money,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: Sizes.s12),
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            title: 'Riders',
                            value: '0',
                            icon: Icons.delivery_dining,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Sizes.s32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Sizes.s16),
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).cardColor
              : Colors.white,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(
            color: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Sizes.s12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: Sizes.s32,
                color: color,
              ),
            ),
            const SizedBox(height: Sizes.s12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Sizes.s4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).cardColor
            : Colors.white,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Icon(
                icon,
                size: Sizes.s20,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: Sizes.s8),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
