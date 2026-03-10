import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/admin/views/admin_order_detail_screen.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_card.dart';
import 'package:downtown/modules/orders/widgets/order_error_widget.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _authController = DependencyInjection.instance.authController;
  OrderStatus? _selectedStatus;
  TimeFilter _selectedTimeFilter = TimeFilter.all;
  bool _showOngoingOnly = false; // Filter for ongoing orders
  bool _showPendingPayment = false; // Filter for delivered orders with pending payment
  String? _selectedRiderId; // When set, show delivered + pending payment for this rider only
  List<OrderModel> _allOrders = [];

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.userType != UserType.admin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text('Access denied. Admin only.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopNavigationBar(
              title: 'Orders',
              showBackButton: false,
            ),

            // Filters
            _buildFilters(),

            // Orders List
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: OrderService.getAdminOrders(currentUser.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return OrderErrorWidget(error: snapshot.error);
                  }

                  _allOrders = snapshot.data ?? [];
                  final filteredOrders = _getFilteredOrders();

                  if (filteredOrders.isEmpty) {
                    final isRiderFilter = _selectedRiderId != null;
                    final isPendingPayment = _showPendingPayment || isRiderFilter;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPendingPayment
                                ? Icons.payment_outlined
                                : Icons.shopping_bag_outlined,
                            size: Sizes.s64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            isRiderFilter
                                ? 'No pending payments for this rider'
                                : isPendingPayment
                                    ? 'No pending payments'
                                    : 'No orders found',
                            style: AppTextStyles.heading3.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: Sizes.s8),
                          Text(
                            isRiderFilter
                                ? 'This rider has no delivered COD orders awaiting payment'
                                : isPendingPayment
                                    ? 'All delivered orders have been paid'
                                    : 'Orders will appear here when customers place them',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
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
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return OrderCard(
                        order: order,
                        priceLabel: 'Order + Delivery',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminOrderDetailScreen(
                                orderId: order.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s12),
          Row(
            children: [
              // Status Filter
              Expanded(
                child: _buildStatusFilter(),
              ),
              const SizedBox(width: Sizes.s12),
              // Time Filter
              Expanded(
                child: _buildTimeFilter(),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
          // Filter Chips Row
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(
                    'Ongoing Orders',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: _showOngoingOnly ? FontWeight.w600 : FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: _showOngoingOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showOngoingOnly = selected == true;
                      if (selected == true) {
                        _selectedStatus = null;
                        _showPendingPayment = false;
                        _selectedRiderId = null;
                      }
                    });
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  selectedColor: const Color(0xFFFF6B35).withOpacity(0.25),
                  checkmarkColor: const Color(0xFFFF6B35),
                  side: BorderSide(
                    color: _showOngoingOnly
                        ? const Color(0xFFFF6B35)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: FilterChip(
                  label: Text(
                    'Pending Payment',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: _showPendingPayment ? FontWeight.w600 : FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: _showPendingPayment,
                  onSelected: (selected) {
                    setState(() {
                      _showPendingPayment = selected == true;
                      if (selected == true) {
                        _selectedStatus = null;
                        _showOngoingOnly = false;
                        _selectedRiderId = null;
                      }
                    });
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  selectedColor: Colors.orange.withOpacity(0.25),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _showPendingPayment
                        ? Colors.orange
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
          // Rider filter: delivered + pending payment for selected rider
          _buildRiderFilter(),
        ],
      ),
    );
  }

  Widget _buildRiderFilter() {
    return StreamBuilder<List<UserModel>>(
      stream: UserManagementService.instance.getAllUsers(userType: UserType.rider),
      builder: (context, snapshot) {
        final riders = snapshot.data ?? [];
        final hasRiders = riders.isNotEmpty;
        return DropdownButtonFormField<String?>(
          value: _selectedRiderId,
          decoration: InputDecoration(
            labelText: 'Rider (pending payment)',
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sizes.s12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Sizes.s12,
              vertical: Sizes.s12,
            ),
          ),
          dropdownColor: Theme.of(context).cardColor,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Riders',
                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            if (hasRiders)
              ...riders.map((rider) {
                final label = (rider.name?.trim().isNotEmpty == true 
                    ? rider.name
                    : rider.email) ?? rider.id;
                return DropdownMenuItem<String?>(
                  value: rider.id,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                );
              }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRiderId = value;
              if (value != null) {
                _selectedStatus = null;
                _showOngoingOnly = false;
                _showPendingPayment = false;
              }
            });
          },
          iconEnabledColor: const Color(0xFFFF6B35),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<OrderStatus?>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.s12,
          vertical: Sizes.s12,
        ),
      ),
      dropdownColor: Theme.of(context).cardColor,
      style: AppTextStyles.bodyMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: [
        DropdownMenuItem<OrderStatus?>(
          value: null,
          child: Text(
            'All Status',
            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        ...OrderStatus.values.where((status) => status != OrderStatus.assignedToRider).map((status) {
          return DropdownMenuItem<OrderStatus?>(
            value: status,
            child: Text(
              _getStatusText(status),
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
      iconEnabledColor: const Color(0xFF4CAF50),
    );
  }

  Widget _buildTimeFilter() {
    return DropdownButtonFormField<TimeFilter>(
      value: _selectedTimeFilter,
      decoration: InputDecoration(
        labelText: 'Time',
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.s12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.s12,
          vertical: Sizes.s12,
        ),
      ),
      dropdownColor: Theme.of(context).cardColor,
      style: AppTextStyles.bodyMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: TimeFilter.values.map((filter) {
        return DropdownMenuItem<TimeFilter>(
          value: filter,
          child: Text(
            _getTimeFilterText(filter),
            style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTimeFilter = value;
          });
        }
      },
      iconEnabledColor: const Color(0xFF4CAF50),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'New Order';
      case OrderStatus.sentToAdmin:
        return 'Sent to Admin';
      case OrderStatus.assignedToRider:
        return 'Assigned to Rider';
      case OrderStatus.acceptedByRider:
        return 'Accepted by Rider';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.nearAddress:
        return 'Near Your Address';
      case OrderStatus.atLocation:
        return 'At Location';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getTimeFilterText(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.all:
        return 'All Time';
      case TimeFilter.lastHour:
        return 'Last Hour';
      case TimeFilter.today:
        return 'Today';
      case TimeFilter.thisWeek:
        return 'This Week';
    }
  }

  List<OrderModel> _getFilteredOrders() {
    var filtered = List<OrderModel>.from(_allOrders);

    // Filter by rider: show only this rider's delivered orders with pending payment
    if (_selectedRiderId != null) {
      filtered = filtered.where((order) {
        return order.riderId == _selectedRiderId &&
               order.status == OrderStatus.delivered &&
               order.paymentMethod == 'cash_on_delivery' &&
               !order.paymentCollected;
      }).toList();
    }
    // Filter by pending payment (all delivered orders where rider hasn't submitted payment)
    else if (_showPendingPayment) {
      filtered = filtered.where((order) {
        return order.status == OrderStatus.delivered &&
               order.paymentMethod == 'cash_on_delivery' &&
               !order.paymentCollected;
      }).toList();
    }
    // Filter by ongoing orders (orders from created to delivered, but not payment collected for COD)
    else if (_showOngoingOnly) {
      filtered = filtered.where((order) {
        // Include orders that are not cancelled and not fully completed
        if (order.status == OrderStatus.cancelled) return false;
        
        // For COD orders, include if delivered but payment not collected
        if (order.paymentMethod == 'cash_on_delivery' && 
            order.status == OrderStatus.delivered && 
            !order.paymentCollected) {
          return true;
        }
        
        // Include all other non-delivered orders (created, sentToAdmin, assigned, etc.)
        return order.status != OrderStatus.delivered || 
               (order.status == OrderStatus.delivered && order.paymentMethod != 'cash_on_delivery');
      }).toList();
    } else {
      // Filter by status (only if not showing ongoing or pending payment)
      if (_selectedStatus != null) {
        filtered = filtered.where((order) => order.status == _selectedStatus).toList();
      }
    }

    // Filter by time
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case TimeFilter.all:
        break;
      case TimeFilter.lastHour:
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        filtered = filtered.where((order) {
          return order.createdAt != null && order.createdAt!.isAfter(oneHourAgo);
        }).toList();
        break;
      case TimeFilter.today:
        final todayStart = DateTime(now.year, now.month, now.day);
        filtered = filtered.where((order) {
          return order.createdAt != null && order.createdAt!.isAfter(todayStart);
        }).toList();
        break;
      case TimeFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
        filtered = filtered.where((order) {
          return order.createdAt != null && order.createdAt!.isAfter(weekStartDay);
        }).toList();
        break;
    }

    return filtered;
  }
}

enum TimeFilter {
  all,
  lastHour,
  today,
  thisWeek,
}
