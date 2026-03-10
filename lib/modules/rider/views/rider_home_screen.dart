import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/admin/services/admin_settings_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/notifications/services/notification_service.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/reviews/services/review_service.dart';
import 'package:downtown/modules/reviews/widgets/rating_stars_widget.dart';
import 'package:downtown/modules/rider/services/rider_service.dart';
import 'package:downtown/modules/rider/services/rider_location_service.dart';
import 'package:downtown/modules/rider/views/rider_orders_screen.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final _authController = DependencyInjection.instance.authController;
  final _locationService = RiderLocationService.instance;
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.userType != UserType.rider) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Access denied. Rider only.')),
      );
    }

    final isOnline = currentUser.isOnline ?? false;
    final isAvailable = currentUser.isAvailable ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopNavigationBar(
              title: 'Rider Dashboard',
              showBackButton: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _refreshUser();
                    },
                    tooltip: 'Refresh',
                  ),
                  _buildNotificationButton(context, currentUser.id),
                  const SizedBox(width: Sizes.s8),
                  _buildActiveOrderButton(context, currentUser.id),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshUser,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(Sizes.s16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Sizes.s16),

                    // Online Status Toggle Card with Availability (checks active orders in real-time)
                    _buildStatusCard(isOnline, isAvailable, currentUser.id),
                    const SizedBox(height: Sizes.s24),

                    // Analytics Section
                    Text(
                      'Analytics',
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: Sizes.s16),

                    // Analytics Cards
                    _buildAnalyticsSection(currentUser.id),
                    const SizedBox(height: Sizes.s24),
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshUser() async {
    await _authController.refreshUser();
    if (mounted) setState(() {});
  }

  Widget _buildStatusCard(bool isOnline, bool isAvailable, String riderId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.getRiderOrders(riderId),
      builder: (context, ordersSnapshot) {
        // Check if rider has any active orders (not delivered or cancelled)
        final orders = ordersSnapshot.data ?? [];
        final hasActiveOrder = orders.any((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled);

        return Container(
          padding: const EdgeInsets.all(Sizes.s20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(color: isOnline ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: Sizes.s8, offset: const Offset(0, Sizes.s2))],
          ),
          child: Column(
            children: [
              // Status and Availability Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Status Indicator
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: Sizes.s60,
                          height: Sizes.s60,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: isOnline ? Colors.green : Colors.grey, width: 2),
                          ),
                          child: Icon(isOnline ? Icons.check_circle : Icons.cancel, size: Sizes.s30, color: isOnline ? Colors.green : Colors.grey),
                        ),
                        const SizedBox(height: Sizes.s8),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isOnline ? Colors.green : Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Only show Availability section if there's no active order
                  if (!hasActiveOrder) ...[
                    // Divider
                    Container(width: 1, height: Sizes.s60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),

                    // Availability Indicator
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: Sizes.s60,
                            height: Sizes.s60,
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: isAvailable ? Colors.blue : Colors.orange, width: 2),
                            ),
                            child: Icon(isAvailable ? Icons.check_circle : Icons.delivery_dining, size: Sizes.s30, color: isAvailable ? Colors.blue : Colors.orange),
                          ),
                          const SizedBox(height: Sizes.s8),
                          Text(
                            isAvailable ? 'Available' : 'On Delivery',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isAvailable ? Colors.blue : Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Show "On Delivery" when there's an active order
                    Container(width: 1, height: Sizes.s60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: Sizes.s60,
                            height: Sizes.s60,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            child: const Icon(Icons.delivery_dining, size: Sizes.s30, color: Colors.orange),
                          ),
                          const SizedBox(height: Sizes.s8),
                          Text(
                            'On Delivery',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: Sizes.s20),

              // Toggle Button
              SizedBox(
                width: double.infinity,
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: _isUpdatingStatus ? null : () => _handleToggleStatus(!isOnline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline ? Colors.red : Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                    elevation: 0,
                  ),
                  child: _isUpdatingStatus
                      ? const SizedBox(
                          width: Sizes.s20,
                          height: Sizes.s20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isOnline ? Icons.power_settings_new : Icons.power, color: Colors.white),
                            const SizedBox(width: Sizes.s8),
                            Text(isOnline ? 'Go Offline' : 'Go Online', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleToggleStatus(bool newStatus) async {
    final currentUser = _authController.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final success = await RiderService.updateOnlineStatus(currentUser.id, newStatus);

      if (mounted) {
        if (success) {
          // Refresh user data
          await _authController.refreshUser();

          // Start/stop location updates based on online status
          if (newStatus) {
            // Start location updates when going online
            await _locationService.startLocationUpdates(currentUser.id);
          } else {
            // Stop location updates when going offline
            _locationService.stopLocationUpdates();
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus ? 'You are now online' : 'You are now offline'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating status'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Widget _buildAnalyticsSection(String riderId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminSettingsService.instance.getSettings(),
      builder: (context, settingsSnapshot) {
        final riderPaymentPerKm = (settingsSnapshot.data?['riderPaymentPerKm'] ?? 10.0) as num;
        final rate = riderPaymentPerKm.toDouble();

        return StreamBuilder<List<OrderModel>>(
          stream: OrderService.getRiderOrders(riderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: Sizes.s200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final orders = snapshot.data ?? [];
            final analytics = _calculateAnalytics(orders, riderId, rate);

            return Column(
              children: [
                // Top Row - Total Deliveries & Today's Deliveries
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Total Deliveries',
                        value: analytics['totalDeliveries'].toString(),
                        icon: Icons.local_shipping,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: Sizes.s12),
                    Expanded(
                      child: _buildStatCard(context: context, title: "Today's Deliveries", value: analytics['todayDeliveries'].toString(), icon: Icons.today, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: Sizes.s12),

                // Second Row - Total KM & Total Earnings (KM-based)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Total KM',
                        value: (analytics['totalKm'] as double).toStringAsFixed(1),
                        icon: Icons.straighten,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: Sizes.s12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Total Earnings',
                        value: CurrencyFormatter.format(analytics['totalEarnings']),
                        icon: Icons.attach_money,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sizes.s12),

                // Third Row - Active Orders
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Active Orders',
                        value: analytics['activeOrders'].toString(),
                        icon: Icons.shopping_bag,
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(width: Sizes.s12),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: Sizes.s12),

                // Rating Card
                _buildRatingCard(riderId, analytics['averageRating'] as double),
              ],
            );
          },
        );
      },
    );
  }

  /// [riderPaymentPerKm] from admin settings; earnings = sum of (riderTripKm * rate) for delivered orders.
  Map<String, dynamic> _calculateAnalytics(List<OrderModel> orders, String riderId, double riderPaymentPerKm) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    int totalDeliveries = 0;
    int todayDeliveries = 0;
    double totalEarnings = 0.0;
    double totalKm = 0.0;
    int activeOrders = 0;

    for (final order in orders) {
      // Count delivered orders
      if (order.status == OrderStatus.delivered) {
        totalDeliveries++;

        // Count today's deliveries (use updatedAt when status is delivered)
        if (order.updatedAt != null) {
          final deliveredDate = order.updatedAt!;
          if (deliveredDate.isAfter(todayStart) && deliveredDate.isBefore(todayEnd)) {
            todayDeliveries++;
          }
        }

        // Rider pay is per km (round-trip), not from delivery fee; admin keeps 100% delivery fee
        final tripKm = order.riderTripKm ?? (order.deliveryDistanceKm != null ? order.deliveryDistanceKm! * 2 : 0.0);
        totalKm += tripKm;
        totalEarnings += tripKm * riderPaymentPerKm;
      }

      // Count active orders (not delivered or cancelled)
      if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) {
        activeOrders++;
      }
    }

    return {
      'totalDeliveries': totalDeliveries,
      'todayDeliveries': todayDeliveries,
      'totalEarnings': totalEarnings,
      'totalKm': totalKm,
      'activeOrders': activeOrders,
      'averageRating': 0.0, // Will be fetched separately
    };
  }

  Widget _buildStatCard({required BuildContext context, required String title, required String value, required IconData icon, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(Sizes.s8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(Sizes.s8)),
                  child: Icon(icon, color: color, size: Sizes.s20),
                ),
              ],
            ),
            const SizedBox(height: Sizes.s12),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: Sizes.s4),
            Text(title, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(String riderId, double cachedRating) {
    return FutureBuilder<double>(
      future: ReviewService.getRiderAverageRating(riderId),
      builder: (context, snapshot) {
        final rating = snapshot.data ?? cachedRating;
        final hasRating = rating > 0;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(Sizes.s16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Sizes.s16),
              border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3), width: 1),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Sizes.s12),
                  decoration: BoxDecoration(color: const Color(0xFFFFC107).withOpacity(0.1), borderRadius: BorderRadius.circular(Sizes.s12)),
                  child: const Icon(Icons.star_rate_rounded, color: Color(0xFFFFC107), size: Sizes.s24),
                ),
                const SizedBox(width: Sizes.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average Rating', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      const SizedBox(height: Sizes.s8),
                      Row(
                        children: [
                          RatingStarsWidget(rating: rating, size: Sizes.s18),
                          const SizedBox(width: Sizes.s8),
                          Text(
                            hasRating ? rating.toStringAsFixed(1) : 'No rating yet',
                            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFFC107)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton(BuildContext context, String userId) {
    return StreamBuilder<int>(
      stream: NotificationService.getUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                TablerIconsHelper.bell,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s24,
              ),
              onPressed: () {
                Navigator.pushNamed(context, Routes.notifications);
              },
              tooltip: 'Notifications',
            ),
            // Badge showing unread count
            if (unreadCount > 0)
              Positioned(
                right: Sizes.s6,
                top: Sizes.s6,
                child: Container(
                  padding: const EdgeInsets.all(Sizes.s4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: Sizes.s18,
                    minHeight: Sizes.s18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: AppTextStyles.captionTiny.copyWith(
                        color: Colors.white,
                        fontSize: Sizes.s10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActiveOrderButton(BuildContext context, String riderId) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.getRiderOrders(riderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final orders = snapshot.data ?? [];
        final activeOrders = orders.where((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled).toList();

        // Only show button if there are active orders
        if (activeOrders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s24),
              onPressed: () {
                Navigator.pushNamed(context, Routes.riderOrders);
              },
              tooltip: 'Active Orders',
            ),
            // Badge showing count
            Positioned(
              right: Sizes.s6,
              top: Sizes.s6,
              child: Container(
                padding: const EdgeInsets.all(Sizes.s4),
                decoration: const BoxDecoration(color: Color(0xFF2196F3), shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: Sizes.s18, minHeight: Sizes.s18),
                child: Center(
                  child: Text(
                    activeOrders.length > 9 ? '9+' : activeOrders.length.toString(),
                    style: AppTextStyles.captionTiny.copyWith(color: Colors.white, fontSize: Sizes.s10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
