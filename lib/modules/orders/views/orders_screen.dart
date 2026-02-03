import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/routes/route_constants.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RepaintBoundary(child: _buildOngoingOrders()),
                    RepaintBoundary(child: _buildHistoryOrders()),
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
          // Title
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
            decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent, borderRadius: BorderRadius.circular(Sizes.s1)),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingOrders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Section
          _buildSectionHeader('Food'),
          const SizedBox(height: Sizes.s12),
          AnimatedListItem(
            index: 0,
            child: _buildOngoingOrderCard(
              restaurantName: 'Pizza Hut',
              imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
              price: 35.25,
              itemCount: 3,
              orderId: '#162432',
            ),
          ),
          const SizedBox(height: Sizes.s16),

          // Drink Section
          _buildSectionHeader('Drink'),
          const SizedBox(height: Sizes.s12),
          AnimatedListItem(
            index: 1,
            child: _buildOngoingOrderCard(
              restaurantName: 'McDonald',
              imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&q=80',
              price: 40.15,
              itemCount: 2,
              orderId: '#242432',
            ),
          ),
          const SizedBox(height: Sizes.s16),
          AnimatedListItem(
            index: 2,
            child: _buildOngoingOrderCard(
              restaurantName: 'Starbucks',
              imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&q=80',
              price: 10.20,
              itemCount: 1,
              orderId: '#240112',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food - Completed
          _buildSectionHeaderWithStatus('Food', 'Completed', Colors.green),
          const SizedBox(height: Sizes.s12),
          AnimatedListItem(
            index: 0,
            child: _buildHistoryOrderCard(
              restaurantName: 'Pizza Hut',
              imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
              price: 35.25,
              itemCount: 3,
              orderId: '#162432',
              dateTime: '29 JAN, 12:30',
              status: 'Completed',
            ),
          ),
          const SizedBox(height: Sizes.s16),

          // Drink - Completed
          _buildSectionHeaderWithStatus('Drink', 'Completed', Colors.green),
          const SizedBox(height: Sizes.s12),
          AnimatedListItem(
            index: 1,
            child: _buildHistoryOrderCard(
              restaurantName: 'McDonald',
              imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&q=80',
              price: 40.15,
              itemCount: 2,
              orderId: '#242432',
              dateTime: '30 JAN, 12:30',
              status: 'Completed',
            ),
          ),
          const SizedBox(height: Sizes.s16),

          // Drink - Canceled
          _buildSectionHeaderWithStatus('Drink', 'Canceled', Colors.red),
          const SizedBox(height: Sizes.s12),
          AnimatedListItem(
            index: 2,
            child: _buildHistoryOrderCard(
              restaurantName: 'Starbucks',
              imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&q=80',
              price: 10.20,
              itemCount: 1,
              orderId: '#240112',
              dateTime: '30 JAN, 12:30',
              status: 'Canceled',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSectionHeaderWithStatus(String title, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          status,
          style: AppTextStyles.bodyMedium.copyWith(color: statusColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildOngoingOrderCard({required String restaurantName, required String imageUrl, required double price, required int itemCount, required String orderId}) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: Sizes.s8,
            offset: const Offset(0, Sizes.s2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Image
              ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.s12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: Sizes.s80,
                  height: Sizes.s80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: Sizes.s80,
                    height: Sizes.s80,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: Sizes.s80,
                    height: Sizes.s80,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),

              // Restaurant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurantName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s4),

                    // Price and Item Count
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          width: Sizes.s1,
                          height: Sizes.s16,
                          margin: const EdgeInsets.symmetric(horizontal: Sizes.s8),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        Text(
                          '$itemCount Items',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order ID
              Text(
                orderId,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.trackOrder);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                  ),
                  child: Text(
                    'Track Order',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showCancelOrderBottomSheet(context, orderId, restaurantName);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s8)),
                    padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrderCard({
    required String restaurantName,
    required String imageUrl,
    required double price,
    required int itemCount,
    required String orderId,
    required String dateTime,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: Sizes.s8,
            offset: const Offset(0, Sizes.s2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Image
              ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.s12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: Sizes.s80,
                  height: Sizes.s80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: Sizes.s80,
                    height: Sizes.s80,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: Sizes.s80,
                    height: Sizes.s80,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),

              // Restaurant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurantName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Sizes.s4),

                    // Price, Date/Time, and Item Count
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: Sizes.s8),
                        Text(
                          dateTime,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: Sizes.s8),
                        Text(
                          '$itemCount Items',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order ID
              Text(
                orderId,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Rate order
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s8)),
                    padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                  ),
                  child: Text(
                    'Rate',
                    style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFFF6B35), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Re-order
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                  ),
                  child: Text(
                    'Re-Order',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelOrderBottomSheet(BuildContext context, String orderId, String restaurantName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCancelOrderBottomSheet(context, orderId, restaurantName),
    );
  }

  Widget _buildCancelOrderBottomSheet(BuildContext context, String orderId, String restaurantName) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Sizes.s24)),
      ),
      padding: EdgeInsets.only(left: Sizes.s12, right: Sizes.s12, top: Sizes.s24, bottom: MediaQuery.of(context).viewInsets.bottom + Sizes.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: Sizes.s40,
              height: Sizes.s4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(Sizes.s2),
              ),
            ),
          ),
          const SizedBox(height: Sizes.s24),

          // Title
          Text(
            'Cancel Order',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s16),

          // Order Info
          Container(
            padding: const EdgeInsets.all(Sizes.s16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(Sizes.s12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: Sizes.s4),
                      Text(
                        orderId,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: Sizes.s1,
                  height: Sizes.s40,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
                const SizedBox(width: Sizes.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restaurant',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: Sizes.s4),
                      Text(
                        restaurantName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sizes.s24),

          // Warning Message
          Container(
            padding: const EdgeInsets.all(Sizes.s16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(Sizes.s12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(TablerIconsHelper.help, color: Colors.orange.shade700, size: Sizes.s20),
                const SizedBox(width: Sizes.s12),
                Expanded(
                  child: Text(
                    'Are you sure you want to cancel this order? This action cannot be undone.',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.orange.shade900, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sizes.s32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                    padding: const EdgeInsets.symmetric(vertical: Sizes.s16),
                  ),
                  child: Text(
                    'Keep Order',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement cancel order logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Order $orderId has been cancelled'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: Sizes.s16),
                  ),
                  child: Text(
                    'Cancel Order',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
        ],
      ),
    );
  }
}
