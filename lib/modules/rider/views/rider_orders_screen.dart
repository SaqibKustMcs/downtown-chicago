import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_card.dart';
import 'package:downtown/modules/orders/widgets/order_error_widget.dart';
import 'package:downtown/modules/rider/views/rider_order_detail_screen.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});

  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final _authController = DependencyInjection.instance.authController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      // Only update state when tab change is complete, not during animation
      final newIndex = _tabController.index;
      if (_selectedTab != newIndex) {
        setState(() {
          _selectedTab = newIndex;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.userType != UserType.rider) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text('Access denied. Rider only.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            RepaintBoundary(
              child: TopNavigationBar(
                title: 'Orders',
                showBackButton: false,
              ),
            ),

            // Tabs
            RepaintBoundary(
              child: _buildTabs(),
            ),

            // Content
            Expanded(
              child: RepaintBoundary(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    RepaintBoundary(
                      key: const PageStorageKey<String>('new_orders'),
                      child: _buildNewOrders(currentUser.id),
                    ),
                    RepaintBoundary(
                      key: const PageStorageKey<String>('active_orders'),
                      child: _buildActiveOrders(currentUser.id),
                    ),
                    RepaintBoundary(
                      key: const PageStorageKey<String>('history_orders'),
                      child: _buildHistoryOrders(currentUser.id),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
      child: Row(
        children: [
          _buildTab('New Orders', 0),
          const SizedBox(width: Sizes.s16),
          _buildTab('Active', 1),
          const SizedBox(width: Sizes.s16),
          _buildTab('History', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: Sizes.s8),
          Container(
            width: Sizes.s40,
            height: Sizes.s2,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(Sizes.s1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewOrders(String riderId) {
    return StreamBuilder<List<OrderModel>>(
      key: const PageStorageKey<String>('new_orders_stream'),
      stream: OrderService.getRiderPendingOrders(riderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return OrderErrorWidget(error: snapshot.error);
        }

        final newOrders = snapshot.data ?? [];

        if (newOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: Sizes.s64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s16),
                Text(
                  'No new orders',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                Text(
                  'New orders assigned to you will appear here',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.s12,
            vertical: Sizes.s16,
          ),
          itemCount: newOrders.length,
          itemBuilder: (context, index) {
            final order = newOrders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: Sizes.s12),
              child: OrderCard(
                order: order,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RiderOrderDetailScreen(
                        orderId: order.id,
                        showAcceptDecline: true,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveOrders(String riderId) {
    return StreamBuilder<List<OrderModel>>(
      key: const PageStorageKey<String>('active_orders_stream'),
      stream: OrderService.getRiderOrders(riderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return OrderErrorWidget(error: snapshot.error);
        }

        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((order) {
          return order.status == OrderStatus.acceptedByRider ||
              order.status == OrderStatus.pickedUp ||
              order.status == OrderStatus.onTheWay ||
              order.status == OrderStatus.nearAddress ||
              order.status == OrderStatus.atLocation;
        }).toList();

        if (activeOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delivery_dining_outlined,
                  size: Sizes.s64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s16),
                Text(
                  'No active orders',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                Text(
                  'Your active deliveries will appear here',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey<String>('active_orders_list'),
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.s12,
            vertical: Sizes.s16,
          ),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return Padding(
              key: ValueKey('active_order_${order.id}'),
              padding: const EdgeInsets.only(bottom: Sizes.s12),
              child: OrderCard(
                order: order,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RiderOrderDetailScreen(
                        orderId: order.id,
                        showAcceptDecline: false,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryOrders(String riderId) {
    return StreamBuilder<List<OrderModel>>(
      key: const PageStorageKey<String>('history_orders_stream'),
      stream: OrderService.getRiderOrders(riderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return OrderErrorWidget(error: snapshot.error);
        }

        final allOrders = snapshot.data ?? [];
        final historyOrders = allOrders.where((order) {
          return order.status == OrderStatus.delivered ||
              order.status == OrderStatus.cancelled;
        }).toList();

        if (historyOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: Sizes.s64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s16),
                Text(
                  'No order history',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                Text(
                  'Your completed orders will appear here',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey<String>('history_orders_list'),
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.s12,
            vertical: Sizes.s16,
          ),
          itemCount: historyOrders.length,
          itemBuilder: (context, index) {
            final order = historyOrders[index];
            return Padding(
              key: ValueKey('history_order_${order.id}'),
              padding: const EdgeInsets.only(bottom: Sizes.s12),
              child: OrderCard(
                order: order,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RiderOrderDetailScreen(
                        orderId: order.id,
                        showAcceptDecline: false,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
