import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/admin/services/admin_settings_service.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_status_chip.dart';
import 'package:downtown/modules/rider/services/rider_location_service.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class RiderOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool showAcceptDecline;

  const RiderOrderDetailScreen({super.key, required this.orderId, this.showAcceptDecline = false});

  @override
  State<RiderOrderDetailScreen> createState() => _RiderOrderDetailScreenState();
}

class _RiderOrderDetailScreenState extends State<RiderOrderDetailScreen> {
  final _authController = DependencyInjection.instance.authController;
  final _locationService = RiderLocationService.instance;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartLocationUpdates();
  }

  @override
  void dispose() {
    // Don't stop location updates here - they should continue while rider is on delivery
    // Location updates will stop when order is delivered or rider goes offline
    super.dispose();
  }

  Future<void> _checkAndStartLocationUpdates() async {
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.userType != UserType.rider) return;

    // Start location updates if rider is online
    if (currentUser.isOnline == true) {
      await _locationService.startLocationUpdates(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    
    // Role guard - only riders can access
    if (currentUser == null || currentUser.userType != UserType.rider) {
      return RoleGuard.guard(
        context: context,
        requiredRole: UserType.rider,
        child: const SizedBox.shrink(),
        accessDeniedMessage: 'Access denied. Rider only.',
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<OrderModel?>(
          stream: OrderService.getOrderStream(widget.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Column(
                children: [
                  TopNavigationBar(title: 'Order Details', showBackButton: true),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: Sizes.s64, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: Sizes.s16),
                          Text('Order not found', style: AppTextStyles.heading3.copyWith(color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final order = snapshot.data!;
            return Column(
              children: [
                TopNavigationBar(title: 'Order Details', showBackButton: true),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Sizes.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Status
                        Center(
                          child: _buildRiderOrderStatus(order),
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Order Info Card
                        _buildOrderInfoCard(order),
                        const SizedBox(height: Sizes.s16),

                        // Customer Info
                        _buildCustomerInfoCard(order),
                        const SizedBox(height: Sizes.s16),

                        // Items List
                        _buildItemsSection(order),
                        const SizedBox(height: Sizes.s16),

                        // Delivery Address
                        if (order.deliveryAddress != null) _buildAddressSection(order),
                        const SizedBox(height: Sizes.s16),

                        // Price Summary
                        _buildPriceSummary(order),
                        if (order.orderType == OrderType.delivery && (order.riderTripKm != null || order.deliveryDistanceKm != null)) ...[
                          const SizedBox(height: Sizes.s12),
                          _buildRiderTripCard(order),
                        ],
                        const SizedBox(height: Sizes.s16),

                        // Action Buttons
                        _buildActionButtons(order),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRiderOrderStatus(OrderModel order) {
    // For COD orders that are delivered but payment not collected, show special status
    if (order.paymentMethod == 'cash_on_delivery' &&
        order.status == OrderStatus.delivered &&
        !order.paymentCollected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.s20, vertical: Sizes.s12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Sizes.s24),
          border: Border.all(
            color: Colors.orange,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payment,
              color: Colors.orange.shade700,
              size: Sizes.s20,
            ),
            const SizedBox(width: Sizes.s8),
            Flexible(
              child: Text(
                'Handover the cash to the restaurant',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    // For other statuses, use the standard chip
    return OrderStatusChip(status: order.status);
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: Sizes.s16),
          _buildInfoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
          if (order.restaurantName != null) _buildInfoRow('Restaurant', order.restaurantName!),
          if (order.createdAt != null) _buildInfoRow('Order Date', dateFormat.format(order.createdAt!)),
          _buildInfoRow('Payment Method', 'Cash on Delivery'),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.firestore.collection('users').doc(order.customerId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Information',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: Sizes.s16),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final customerData = snapshot.data?.data() as Map<String, dynamic>?;
          // Use order's customerPhoneNumber first, then fallback to user's phoneNumber
          final customerPhone = order.customerPhoneNumber ?? customerData?['phoneNumber'] as String? ?? 'N/A';
          final customerName = customerData?['name'] as String? ?? 
                              (customerData != null 
                                ? '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim()
                                : 'N/A');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Information',
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: Sizes.s16),
              _buildInfoRow('Customer Name', customerName.isEmpty || customerName == 'N/A' ? 'N/A' : customerName),
              _buildInfoRow('Phone Number', customerPhone),
              _buildInfoRow('Customer ID', order.customerId.substring(0, 8)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sizes.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: Sizes.s12),
        ...order.items.map((item) => _buildOrderItemCard(item)),
      ],
    );
  }

  Widget _buildOrderItemCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      padding: const EdgeInsets.all(Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Sizes.s8),
            child: CachedNetworkImage(
              imageUrl: item['imageUrl'] as String? ?? '',
              width: Sizes.s60,
              height: Sizes.s60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: Sizes.s60,
                height: Sizes.s60,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
              ),
              errorWidget: (context, url, error) => Container(
                width: Sizes.s60,
                height: Sizes.s60,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: Sizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? 'Item',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
                if (item['selectedVariation'] != null || item['selectedFlavor'] != null) ...[
                  const SizedBox(height: Sizes.s4),
                  Text(
                    [if (item['selectedVariation'] != null) item['selectedVariation'], if (item['selectedFlavor'] != null) item['selectedFlavor']].join(' • '),
                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
                const SizedBox(height: Sizes.s4),
                Text(
                  'Qty: ${item['quantity'] ?? 0} × ${CurrencyFormatter.format((item['unitPrice'] as num?)?.toDouble() ?? 0.0)}',
                  style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(((item['quantity'] as int? ?? 0) * ((item['unitPrice'] as num?)?.toDouble() ?? 0.0))),
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(OrderModel order) {
    return InkWell(
      onTap: () {
        // Navigate to track order screen
        Navigator.pushNamed(context, Routes.trackOrder, arguments: order.id);
      },
      borderRadius: BorderRadius.circular(Sizes.s16),
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: const Color(0xFFFF6B35), size: Sizes.s20),
                const SizedBox(width: Sizes.s8),
                Text(
                  'Delivery Address',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: Sizes.s16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: Sizes.s12),
            Text(order.deliveryAddress!, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            if (order.deliveryNote != null && order.deliveryNote!.isNotEmpty) ...[
              const SizedBox(height: Sizes.s8),
              Text(
                'Extra details: ${order.deliveryNote!}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: Sizes.s8),
            Text(
              'Tap to view on map',
              style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFFF6B35)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', order.subtotal),
          const SizedBox(height: Sizes.s8),
          _buildPriceRow('Delivery Fee', order.deliveryFee, isFree: order.deliveryFee == 0.0),
          const SizedBox(height: Sizes.s12),
          const Divider(),
          const SizedBox(height: Sizes.s12),
          _buildPriceRow('Total', order.totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal, color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            CurrencyFormatter.formatWithFree(amount),
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  /// Your trip distance and earnings for this order (KM-based; admin keeps delivery fee).
  Widget _buildRiderTripCard(OrderModel order) {
    final tripKm = order.riderTripKm ?? (order.deliveryDistanceKm != null ? order.deliveryDistanceKm! * 2 : null);
    if (tripKm == null || tripKm <= 0) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminSettingsService.instance.getSettings(),
      builder: (context, snapshot) {
        final ratePerKm = (snapshot.data?['riderPaymentPerKm'] ?? 10.0) as num;
        final earnings = tripKm * ratePerKm.toDouble();
        return Container(
          padding: const EdgeInsets.all(Sizes.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your trip (KM-based pay)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Sizes.s8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distance (round trip)', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                  Text('${tripKm.toStringAsFixed(2)} km', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: Sizes.s4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your earnings', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                  Text(CurrencyFormatter.format(earnings), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final currentUser = _authController.currentUser;
    final canAcceptDecline = widget.showAcceptDecline && order.status == OrderStatus.assignedToRider && order.riderId == currentUser?.id;
    final isRiderOrder = order.riderId == currentUser?.id;
    final isNotDeliveredOrCancelled = order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;

    return Column(
      children: [
        // Accept/Decline Buttons
        if (canAcceptDecline) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: Sizes.s56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _handleAcceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: Sizes.s20,
                            height: Sizes.s20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Accept Order', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: SizedBox(
                  height: Sizes.s56,
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _handleDeclineOrder(order),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                    ),
                    child: Text('Decline', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
          if (isRiderOrder && isNotDeliveredOrCancelled) const SizedBox(height: Sizes.s12),
        ],

        // Progressive Status Buttons
        if (isRiderOrder && isNotDeliveredOrCancelled) ...[
          _buildNextStatusButton(order),
        ],

        // Customer Contact Buttons
        if (order.customerId.isNotEmpty && (isRiderOrder && isNotDeliveredOrCancelled || canAcceptDecline)) ...[
          const SizedBox(height: Sizes.s12),
          // WhatsApp Message Button
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _whatsAppCustomer(order),
              icon: const Icon(Icons.chat, color: Colors.white),
              label: Text('Text Customer on WhatsApp', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: Sizes.s12),
          // Call Button
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : () => _callCustomer(order),
              icon: const Icon(Icons.phone, color: Color(0xFFFF6B35)),
              label: Text('Call Customer', style: AppTextStyles.buttonLargeBold.copyWith(color: const Color(0xFFFF6B35))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B35)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleAcceptOrder(OrderModel order) async {
    final currentUser = _authController.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await OrderService.acceptOrderByRider(order.id, currentUser.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted successfully'), backgroundColor: Colors.green));
          // Refresh user data to update activeOrderId
          await _authController.refreshUser();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to accept order'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error accepting order'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleDeclineOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Order'),
        content: const Text('Are you sure you want to decline this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final currentUser = _authController.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await OrderService.declineOrderByRider(order.id, currentUser.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order declined'), backgroundColor: Colors.orange));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to decline order'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error declining order'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }


  /// Get customer phone number (from order first, then user profile)
  Future<String?> _getCustomerPhoneNumber(OrderModel order) async {
    // First try to use phone number from order
    if (order.customerPhoneNumber != null && order.customerPhoneNumber!.isNotEmpty) {
      return order.customerPhoneNumber;
    }

    // Fallback to fetching from user profile
    try {
      final customerDoc = await FirebaseService.firestore
          .collection('users')
          .doc(order.customerId)
          .get();

      if (customerDoc.exists) {
        final customerData = customerDoc.data();
        return customerData?['phoneNumber'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching customer phone number: $e');
    }

    return null;
  }

  Future<void> _callCustomer(OrderModel order) async {
    try {
      final phoneNumber = await _getCustomerPhoneNumber(order);

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer phone number not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Clean phone number (remove spaces, dashes, etc.)
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Make phone call
      await FlutterPhoneDirectCaller.callNumber(cleanedNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calling customer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _whatsAppCustomer(OrderModel order) async {
    try {
      final phoneNumber = await _getCustomerPhoneNumber(order);

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer phone number not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Clean phone number (remove spaces, dashes, etc., but keep +)
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Remove leading + if present for WhatsApp URL
      final whatsappNumber = cleanedNumber.startsWith('+') ? cleanedNumber.substring(1) : cleanedNumber;
      
      // Open WhatsApp with the phone number
      final url = 'https://wa.me/$whatsappNumber';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp is not installed or cannot be opened'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build the next status button based on current order status
  Widget _buildNextStatusButton(OrderModel order) {
    OrderStatus? nextStatus;
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;

    switch (order.status) {
      case OrderStatus.acceptedByRider:
        nextStatus = OrderStatus.pickedUp;
        buttonText = 'Picked Up';
        buttonIcon = Icons.shopping_bag;
        buttonColor = Colors.blue;
        break;
      case OrderStatus.pickedUp:
        nextStatus = OrderStatus.onTheWay;
        buttonText = 'On the Way';
        buttonIcon = Icons.directions_bike;
        buttonColor = Colors.purple;
        break;
      case OrderStatus.onTheWay:
        nextStatus = OrderStatus.nearAddress;
        buttonText = 'I am near your address, hang tight';
        buttonIcon = Icons.near_me;
        buttonColor = Colors.orange;
        break;
      case OrderStatus.nearAddress:
        nextStatus = OrderStatus.atLocation;
        buttonText = 'I am at the location';
        buttonIcon = Icons.location_on;
        buttonColor = Colors.deepOrange;
        break;
      case OrderStatus.atLocation:
        nextStatus = OrderStatus.delivered;
        buttonText = 'Handing the order and take the cash';
        buttonIcon = Icons.handshake;
        buttonColor = Colors.green;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: Sizes.s56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _handleNextStatus(order, nextStatus!),
            icon: Icon(buttonIcon, color: Colors.white),
            label: Text(
              buttonText,
              style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNextStatus(OrderModel order, OrderStatus nextStatus) async {
    final currentUser = DependencyInjection.instance.authController.currentUser;
    if (currentUser == null || currentUser.userType != UserType.rider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: Rider access required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await OrderService.updateOrderStatus(
        order.id,
        nextStatus,
        userId: currentUser.id!,
        userType: 'rider',
      );
      if (mounted) {
        if (success) {
          // If status is delivered, show special message
          if (nextStatus == OrderStatus.delivered) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Order marked as delivered. Please hand over the cash to the restaurant.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated: ${_getStatusText(nextStatus)}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update status. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'New Order';
      case OrderStatus.sentToAdmin:
        return 'Preparing';
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
}

