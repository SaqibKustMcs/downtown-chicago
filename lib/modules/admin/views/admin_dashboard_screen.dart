import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

enum DashboardDateFilter {
  today,
  weekly,
  monthly,
  sixMonth,
  yearly,
  custom,
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authController = DependencyInjection.instance.authController;
  DashboardDateFilter _dateFilter = DashboardDateFilter.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Dashboard',
              showBackButton: false,
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
                            ? Colors.green.shade900.withOpacity(0.3)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(Sizes.s16),
                        border: Border.all(
                          color: isDark
                              ? Colors.green.shade700
                              : Colors.green.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.dashboard,
                            size: Sizes.s40,
                            color: isDark
                                ? Colors.green.shade300
                                : Colors.green.shade700,
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
                                        ? Colors.green.shade200
                                        : Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: Sizes.s4),
                                Text(
                                  'Welcome back, ${currentUser.name ?? 'Admin'}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark
                                        ? Colors.green.shade300
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Sizes.s24),

                    // Date filter
                    _buildFilterSection(context),
                    const SizedBox(height: Sizes.s16),

                    // Stats Section
                    Text(
                      'Statistics',
                      style: AppTextStyles.heading3.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Sizes.s16),

                    // Stats Cards
                    StreamBuilder<List<OrderModel>>(
                      stream: FirebaseService.firestore
                          .collection('orders')
                          .where('adminId', isEqualTo: currentUser.id)
                          .snapshots()
                          .map((snapshot) => snapshot.docs
                              .map((doc) {
                                try {
                                  return OrderModel.fromFirestore(
                                    doc.data() as Map<String, dynamic>,
                                    doc.id,
                                  );
                                } catch (e) {
                                  debugPrint('Error parsing order ${doc.id}: $e');
                                  return null;
                                }
                              })
                              .whereType<OrderModel>()
                              .toList())
                          .handleError((error) {
                            debugPrint('Error fetching orders: $error');
                            return <OrderModel>[];
                          }),
                      builder: (context, snapshot) {
                        final allOrders = snapshot.data ?? [];
                        final range = _getDateRange();
                        if (range == null && _dateFilter == DashboardDateFilter.custom) {
                          return Column(
                            children: [
                              _buildStatCard(context: context, title: 'Orders', value: '0', icon: Icons.shopping_cart, color: Colors.green),
                              const SizedBox(height: Sizes.s12),
                              _buildStatCard(context: context, title: 'Revenue', value: CurrencyFormatter.formatInt(0), icon: Icons.attach_money, color: Colors.blue),
                              const Padding(
                                padding: EdgeInsets.all(Sizes.s16),
                                child: Text('Select a date range using "Select date"', style: AppTextStyles.bodySmall),
                              ),
                            ],
                          );
                        }
                        final orders = range != null
                            ? allOrders.where((o) {
                                final t = o.createdAt;
                                if (t == null) return false;
                                return !t.isBefore(range.$1) && !t.isAfter(range.$2);
                              }).toList()
                            : allOrders;
                        final pendingOrders = orders.where((order) {
                          return order.status == OrderStatus.created ||
                              order.status == OrderStatus.sentToAdmin ||
                              order.status == OrderStatus.assignedToRider;
                        }).toList();
                        final totalRevenue = orders
                            .where((order) => order.status == OrderStatus.delivered)
                            .fold<double>(0.0, (sum, order) => sum + order.totalAmount);

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context: context,
                                    title: _getOrdersLabel(),
                                    value: '${orders.length}',
                                    icon: Icons.shopping_cart,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: Sizes.s12),
                                Expanded(
                                  child: _buildStatCard(
                                    context: context,
                                    title: 'Pending',
                                    value: '${pendingOrders.length}',
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
                                    value: CurrencyFormatter.formatInt(totalRevenue),
                                    icon: Icons.attach_money,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: Sizes.s12),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseService.firestore
                                        .collection('restaurants')
                                        .where('isActive', isEqualTo: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      final restaurantCount = snapshot.data?.docs.length ?? 0;
                                      return _buildStatCard(
                                        context: context,
                                        title: 'Restaurants',
                                        value: '$restaurantCount',
                                        icon: Icons.restaurant,
                                        color: Colors.purple,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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

  /// Returns (start, end) inclusive for order.createdAt filtering. End is end of day.
  (DateTime, DateTime)? _getDateRange() {
    final now = DateTime.now();
    switch (_dateFilter) {
      case DashboardDateFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, now);
      case DashboardDateFilter.weekly:
        final start = now.subtract(const Duration(days: 7));
        return (DateTime(start.year, start.month, start.day), now);
      case DashboardDateFilter.monthly:
        final start = DateTime(now.year, now.month, 1);
        return (start, now);
      case DashboardDateFilter.sixMonth:
        final start = now.subtract(const Duration(days: 180));
        return (DateTime(start.year, start.month, start.day), now);
      case DashboardDateFilter.yearly:
        final start = DateTime(now.year, 1, 1);
        return (start, now);
      case DashboardDateFilter.custom:
        if (_customStart == null || _customEnd == null) return null;
        final endOfDay = DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59, 999);
        return (_customStart!, endOfDay);
    }
  }

  String _getOrdersLabel() {
    switch (_dateFilter) {
      case DashboardDateFilter.today:
        return 'Today Orders';
      case DashboardDateFilter.weekly:
        return 'Orders (7 days)';
      case DashboardDateFilter.monthly:
        return 'Orders (Month)';
      case DashboardDateFilter.sixMonth:
        return 'Orders (6 months)';
      case DashboardDateFilter.yearly:
        return 'Orders (Year)';
      case DashboardDateFilter.custom:
        return _customStart != null && _customEnd != null
            ? 'Orders (Custom)'
            : 'Orders';
    }
  }

  Widget _buildFilterSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date range',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Sizes.s8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Today', DashboardDateFilter.today),
              const SizedBox(width: Sizes.s8),
              _buildFilterChip('Weekly', DashboardDateFilter.weekly),
              const SizedBox(width: Sizes.s8),
              _buildFilterChip('Monthly', DashboardDateFilter.monthly),
              const SizedBox(width: Sizes.s8),
              _buildFilterChip('6 Months', DashboardDateFilter.sixMonth),
              const SizedBox(width: Sizes.s8),
              _buildFilterChip('Yearly', DashboardDateFilter.yearly),
              const SizedBox(width: Sizes.s8),
              _buildFilterChip('Select date', DashboardDateFilter.custom),
            ],
          ),
        ),
        if (_dateFilter == DashboardDateFilter.custom && (_customStart != null || _customEnd != null))
          Padding(
            padding: const EdgeInsets.only(top: Sizes.s8),
            child: Text(
              _customStart != null && _customEnd != null
                  ? '${_formatDate(_customStart!)} – ${_formatDate(_customEnd!)}'
                  : 'Tap "Select date" then pick From & To',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _buildFilterChip(String label, DashboardDateFilter filter) {
    final selected = _dateFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (filter == DashboardDateFilter.custom) {
          _showDateRangePicker(context);
          return;
        }
        setState(() => _dateFilter = filter);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart ?? now.subtract(const Duration(days: 7)),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _customEnd ?? (start.isBefore(now) ? now : start),
      firstDate: start,
      lastDate: now,
    );
    if (end == null || !mounted) return;
    setState(() {
      _dateFilter = DashboardDateFilter.custom;
      _customStart = start;
      _customEnd = end;
    });
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
