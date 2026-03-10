import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_card.dart';
import 'package:downtown/modules/orders/widgets/order_error_widget.dart';
import 'package:downtown/modules/orders/views/order_detail_screen.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final _authController = DependencyInjection.instance.authController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text('Please login to view orders'),
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
              child: _buildTopNavigation(),
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
                      key: const PageStorageKey<String>('ongoing_orders'),
                      child: _buildOngoingOrders(currentUser.id),
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

  Widget _buildTopNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My Orders',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12),
      child: Row(
        children: [
          _buildTab('Ongoing', 0),
          const SizedBox(width: Sizes.s24),
          _buildTab('History', 1),
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
                  ? const Color(0xFFFF6B35)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: Sizes.s8),
          Container(
            width: Sizes.s40,
            height: Sizes.s2,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
              borderRadius: BorderRadius.circular(Sizes.s1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingOrders(String customerId) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.getCustomerOrders(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return OrderErrorWidget(error: snapshot.error);
        }

        final allOrders = snapshot.data ?? [];
        final ongoingOrders = allOrders.where((order) {
          return order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled;
        }).toList();

        if (ongoingOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: Sizes.s64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s16),
                Text(
                  'No ongoing orders',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                Text(
                  'Your active orders will appear here',
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
          itemCount: ongoingOrders.length,
          itemBuilder: (context, index) {
            final order = ongoingOrders[index];
            return OrderCard(
              order: order,
              showNewOrderAsPreparing: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: order.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryOrders(String customerId) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.getCustomerOrders(customerId),
      key: const PageStorageKey<String>('history_stream'),
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
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.s12,
            vertical: Sizes.s16,
          ),
          itemCount: historyOrders.length,
          itemBuilder: (context, index) {
            final order = historyOrders[index];
            return OrderCard(
              order: order,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: order.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
