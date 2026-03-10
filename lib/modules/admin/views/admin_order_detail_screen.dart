import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/admin/services/admin_settings_service.dart';
import 'package:downtown/modules/admin/services/print_service.dart';
import 'package:downtown/modules/admin/widgets/rider_selection_dialog.dart';
import 'package:downtown/modules/admin/widgets/order_edit_dialog.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_status_chip.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final _authController = DependencyInjection.instance.authController;
  final _printService = PrintService.instance;
  bool _kotPrinted = false;
  bool _billPrinted = false;
  
  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    
    // Role guard - only admins can access
    if (currentUser == null || currentUser.userType != UserType.admin) {
      return RoleGuard.guard(
        context: context,
        requiredRole: UserType.admin,
        child: const SizedBox.shrink(),
        accessDeniedMessage: 'Access denied. Admin only.',
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<OrderModel?>(
          stream: OrderService.getOrderStream(widget.orderId),
          builder: (context, snapshot) {
            // Show loading only on initial load, not on subsequent updates
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Only show error if we have no data and connection is done
            if (snapshot.hasError || (!snapshot.hasData && snapshot.connectionState == ConnectionState.done)) {
              return Column(
                children: [
                  TopNavigationBar(
                    title: 'Order Details',
                    showBackButton: true,
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: Sizes.s64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'Order not found',
                            style: AppTextStyles.heading3.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final order = snapshot.data!;
            
            return RepaintBoundary(
              child: Column(
                children: [
                  TopNavigationBar(
                    title: 'Order Details',
                    showBackButton: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Sizes.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Order Status
                        Center(
                          child: OrderStatusChip(status: order.status),
                        ),
                        const SizedBox(height: Sizes.s24),

                        // Order Info Card
                        _buildOrderInfoCard(order),
                        const SizedBox(height: Sizes.s16),

                        // Customer Info
                        _buildCustomerInfoCard(order),
                        const SizedBox(height: Sizes.s16),

                        // Rider Info (if assigned)
                        if (order.riderId != null) ...[
                          _buildRiderInfoCard(order),
                          const SizedBox(height: Sizes.s16),
                        ],

                        // Items List
                        _buildItemsSection(order),
                        const SizedBox(height: Sizes.s16),

                        // Delivery Address
                        if (order.deliveryAddress != null)
                          _buildAddressSection(order),
                        const SizedBox(height: Sizes.s16),

                        // Price Summary
                        _buildPriceSummary(order),
                        if (order.orderType == OrderType.delivery && (order.riderTripKm != null || order.deliveryDistanceKm != null)) ...[
                          const SizedBox(height: Sizes.s16),
                          _buildRiderTripSummary(order),
                        ],
                        const SizedBox(height: Sizes.s16),

                        // Action Buttons
                        _buildActionButtons(order),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s16),
          _buildInfoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
          _buildInfoRow('Order Type', order.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery'),
          if (order.restaurantName != null)
            _buildInfoRow('Restaurant', order.restaurantName!),
          if (order.createdAt != null)
            _buildInfoRow('Order Date', dateFormat.format(order.createdAt!)),
          _buildInfoRow('Payment Method', 'Cash on Delivery'),
        ],
      ),
    );
  }

  Widget _buildRiderInfoCard(OrderModel order) {
    if (order.riderId == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.firestore.collection('users').doc(order.riderId!).snapshots(),
        builder: (context, snapshot) {
          // Show loading only on initial load
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rider Information',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Sizes.s16),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final riderData = snapshot.data?.data() as Map<String, dynamic>?;
          final riderName = riderData?['name'] as String? ?? 'N/A';
          final riderPhone = riderData?['phoneNumber'] as String? ?? 
                            riderData?['secondaryContactNumber'] as String? ?? 'N/A';
          final riderEmail = riderData?['email'] as String? ?? 'N/A';
          final isOnline = riderData?['isOnline'] as bool? ?? false;
          final isAvailable = riderData?['isAvailable'] as bool? ?? false;
          final vehicleType = riderData?['vehicleType'] as String?;
          final vehicleNumber = riderData?['vehicleNumber'] as String?;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Rider Information',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Online/Available Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
                    decoration: BoxDecoration(
                      color: isOnline && isAvailable
                          ? Colors.green.withOpacity(0.2)
                          : isOnline
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(Sizes.s8),
                      border: Border.all(
                        color: isOnline && isAvailable
                            ? Colors.green
                            : isOnline
                                ? Colors.orange
                                : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: Sizes.s8,
                          height: Sizes.s8,
                          decoration: BoxDecoration(
                            color: isOnline && isAvailable
                                ? Colors.green
                                : isOnline
                                    ? Colors.orange
                                    : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: Sizes.s4),
                        Text(
                          isOnline && isAvailable
                              ? 'Available'
                              : isOnline
                                  ? 'Online'
                                  : 'Offline',
                          style: AppTextStyles.captionTiny.copyWith(
                            color: isOnline && isAvailable
                                ? Colors.green.shade700
                                : isOnline
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.s16),
              _buildInfoRow('Rider Name', riderName.isEmpty ? 'N/A' : riderName),
              _buildInfoRow('Phone Number', riderPhone),
              _buildInfoRow('Email', riderEmail),
              if (vehicleType != null && vehicleType.isNotEmpty)
                _buildInfoRow('Vehicle Type', vehicleType),
              if (vehicleNumber != null && vehicleNumber.isNotEmpty)
                _buildInfoRow('Vehicle Number', vehicleNumber),
              _buildInfoRow('Rider ID', order.riderId!.substring(0, 8)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomerInfoCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.firestore.collection('users').doc(order.customerId).snapshots(),
        builder: (context, snapshot) {
          // Show loading only on initial load
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Information',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Sizes.s16),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final customerData = snapshot.data?.data() as Map<String, dynamic>?;
          final customerName = customerData?['name'] as String? ?? 
                              (customerData != null 
                                ? '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim()
                                : 'N/A');
          final customerPhone = order.customerPhoneNumber ?? customerData?['phoneNumber'] as String? ?? 'N/A';
          final customerEmail = customerData?['email'] as String? ?? 'N/A';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Information',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Sizes.s16),
              _buildInfoRow('Customer Name', customerName.isEmpty ? 'N/A' : customerName),
              _buildInfoRow('Phone Number', customerPhone),
              _buildInfoRow('Email', customerEmail),
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
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Item Image
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
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: Sizes.s60,
                height: Sizes.s60,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                child: Icon(
                  Icons.fastfood,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: Sizes.s12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? 'Item',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (item['selectedVariation'] != null ||
                    item['selectedFlavor'] != null) ...[
                  const SizedBox(height: Sizes.s4),
                  Text(
                    [
                      if (item['selectedVariation'] != null)
                        item['selectedVariation'],
                      if (item['selectedFlavor'] != null) item['selectedFlavor'],
                    ].join(' • '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: Sizes.s4),
                Text(
                  'Qty: ${item['quantity'] ?? 0} × ${CurrencyFormatter.format((item['unitPrice'] as num?)?.toDouble() ?? 0.0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Item Total
          Text(
            CurrencyFormatter.format(((item['quantity'] as int? ?? 0) * ((item['unitPrice'] as num?)?.toDouble() ?? 0.0))),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(OrderModel order) {
    final latLng = order.customerLatLng;
    final hasCoordinates = latLng != null && 
                          latLng['latitude'] != null && 
                          latLng['longitude'] != null;

    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFFFF6B35),
                size: Sizes.s20,
              ),
              const SizedBox(width: Sizes.s8),
              Text(
                'Delivery Address',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
          Text(
            order.deliveryAddress!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (order.addressTitle != null && order.addressTitle!.isNotEmpty) ...[
            const SizedBox(height: Sizes.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(Sizes.s8),
              ),
              child: Text(
                order.addressTitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFFFF6B35),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: Sizes.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note_outlined,
                size: Sizes.s16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: Sizes.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extra details for rider',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: Sizes.s4),
                    Text(
                      (order.deliveryNote != null && order.deliveryNote!.isNotEmpty)
                          ? order.deliveryNote!
                          : '—',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: (order.deliveryNote != null && order.deliveryNote!.isNotEmpty)
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                        fontStyle: (order.deliveryNote != null && order.deliveryNote!.isNotEmpty)
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasCoordinates) ...[
            const SizedBox(height: Sizes.s16),
            Container(
              height: Sizes.s200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Sizes.s12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.s12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      latLng['latitude']!,
                      latLng['longitude']!,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('delivery_location'),
                      position: LatLng(
                        latLng['latitude']!,
                        latLng['longitude']!,
                      ),
                      infoWindow: InfoWindow(
                        title: 'Delivery Location',
                        snippet: order.deliveryAddress,
                      ),
                    ),
                  },
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSummary(OrderModel order) {
    final subtotal = order.subtotal;
    final deliveryFee = order.deliveryFee;
    final total = order.totalAmount;
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', order.subtotal),
          const SizedBox(height: Sizes.s8),
          _buildPriceRow('Delivery Fee', order.deliveryFee, isFree: order.deliveryFee == 0.0),
          const SizedBox(height: Sizes.s12),
          const Divider(),
          const SizedBox(height: Sizes.s12),
          _buildPriceRow(
            'Total',
            order.totalAmount,
            isTotal: true,
          ),
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
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            CurrencyFormatter.formatWithFree(amount),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Delivery distance (round-trip) and rider pay based on KM (admin keeps 100% delivery fee).
  Widget _buildRiderTripSummary(OrderModel order) {
    final tripKm = order.riderTripKm ?? (order.deliveryDistanceKm != null ? order.deliveryDistanceKm! * 2 : null);
    if (tripKm == null || tripKm <= 0) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminSettingsService.instance.getSettings(),
      builder: (context, snapshot) {
        final ratePerKm = (snapshot.data?['riderPaymentPerKm'] ?? 10.0) as num;
        final riderPay = tripKm * ratePerKm.toDouble();
        return Container(
          padding: const EdgeInsets.all(Sizes.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rider trip (KM-based pay)',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Sizes.s8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sizes.s8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery distance (round trip)',
                      style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(
                      '${tripKm.toStringAsFixed(2)} km',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              _buildPriceRow('Rider pay (per km)', riderPay),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final canUpdateStatus = order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled;
    final canAssignRider = order.status == OrderStatus.created ||
        order.status == OrderStatus.created;

    final canEditOrder = order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled;

    // Check if payment needs to be collected (COD orders that are delivered but payment not collected)
    final canCollectPayment = order.paymentMethod == 'cash_on_delivery' &&
        order.status == OrderStatus.delivered &&
        !order.paymentCollected &&
        order.riderId != null;

    return Column(
      children: [
        // Collect Payment Button (for COD orders)
        if (canCollectPayment)
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton.icon(
              onPressed: () => _handleCollectPayment(order),
              icon: const Icon(Icons.payment, color: Colors.white),
              label: FutureBuilder<String?>(
                future: _getRiderName(order.riderId!),
                builder: (context, snapshot) {
                  final riderName = snapshot.data ?? 'Rider';
                  return Text(
                    'Collect Payment from $riderName',
                    style: AppTextStyles.buttonLargeBold.copyWith(
                      color: Colors.white,
                    ),
                  );
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
                elevation: 0,
              ),
            ),
          ),
        if (canCollectPayment) const SizedBox(height: Sizes.s12),

        // Edit Order Button
        if (canEditOrder)
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton.icon(
              onPressed: () => _handleEditOrder(order),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Text(
                'Edit Order Items',
                style: AppTextStyles.buttonLargeBold.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
                elevation: 0,
              ),
            ),
          ),
        if (canEditOrder) const SizedBox(height: Sizes.s12),
        
        // Print KOT Button
        SizedBox(
          width: double.infinity,
          height: Sizes.s56,
          child: ElevatedButton.icon(
            onPressed: () => _handlePrintKOT(order),
            icon: Icon(
              Icons.print,
              color: Colors.white,
            ),
            label: Text(
              'Print KOT',
              style: AppTextStyles.buttonLargeBold.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.s12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: Sizes.s12),
        
        // Print Bill Button
        SizedBox(
          width: double.infinity,
          height: Sizes.s56,
          child: ElevatedButton.icon(
            onPressed: () => _handlePrintBill(order),
            icon: Icon(
              Icons.receipt_long,
              color: Colors.white,
            ),
            label: Text(
              'Print Bill',
              style: AppTextStyles.buttonLargeBold.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Sizes.s12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: Sizes.s16),
        
        // Assign Rider Button
        if (canAssignRider)
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: ElevatedButton.icon(
              onPressed: () => _handleAssignRider(order),
              icon: const Icon(Icons.delivery_dining, color: Colors.white),
              label: Text(
                order.riderId == null ? 'Assign Rider' : 'Reassign Rider',
                style: AppTextStyles.buttonLargeBold.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
                elevation: 0,
              ),
            ),
          ),
        if (canAssignRider && canUpdateStatus) const SizedBox(height: Sizes.s12),

        // Update Status Button
        if (canUpdateStatus)
          SizedBox(
            width: double.infinity,
            height: Sizes.s56,
            child: OutlinedButton.icon(
              onPressed: () => _handleUpdateStatus(order),
              icon: const Icon(Icons.update, color: Color(0xFFFF6B35)),
              label: Text(
                'Update Status',
                style: AppTextStyles.buttonLargeBold.copyWith(
                  color: const Color(0xFFFF6B35),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Future<void> _loadPrintStatus(String orderId) async {
    final status = await _printService.checkPrintStatus(orderId);
    if (mounted) {
      setState(() {
        _kotPrinted = status['kotPrinted'] ?? false;
        _billPrinted = status['billPrinted'] ?? false;
      });
    }
  }
  
  Future<void> _handlePrintKOT(OrderModel order) async {
    // Double confirmation if already printed
    if (_kotPrinted) {
      final firstConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('KOT Already Printed'),
          content: const Text('This KOT has already been printed. Are you sure you want to print again?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Print Again', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      
      if (firstConfirm != true) return;
      
      final secondConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: Sizes.s8),
              const Text('Final Confirmation'),
            ],
          ),
          content: const Text('Double printing may cause duplicate orders. Are you absolutely sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Print Again'),
            ),
          ],
        ),
      );
      
      if (secondConfirm != true) return;
    }
    
    await _printService.printKOT(
      order: order,
      context: context,
      onPrintStatusChanged: (printed) {
        if (mounted) {
          setState(() {
            _kotPrinted = printed;
          });
        }
      },
    );
  }
  
  Future<void> _handlePrintBill(OrderModel order) async {
    // Fetch rider name if assigned
    String? riderName;
    if (order.riderId != null) {
      try {
        final riderDoc = await FirebaseService.firestore
            .collection('users')
            .doc(order.riderId!)
            .get();
        if (riderDoc.exists) {
          final riderData = riderDoc.data() as Map<String, dynamic>?;
          riderName = riderData?['name'] as String?;
        }
      } catch (e) {
        debugPrint('Error fetching rider name: $e');
      }
    }
    
    // Double confirmation if already printed
    if (_billPrinted) {
      final firstConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bill Already Printed'),
          content: const Text('This bill has already been printed. Are you sure you want to print again?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Print Again', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      
      if (firstConfirm != true) return;
      
      final secondConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: Sizes.s8),
              const Text('Final Confirmation'),
            ],
          ),
          content: const Text('Double printing may cause duplicate bills. Are you absolutely sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Print Again'),
            ),
          ],
        ),
      );
      
      if (secondConfirm != true) return;
    }
    
    await _printService.printBill(
      order: order,
      context: context,
      riderName: riderName,
      onPrintStatusChanged: (printed) {
        if (mounted) {
          setState(() {
            _billPrinted = printed;
          });
        }
      },
    );
  }

  Future<String?> _getRiderName(String riderId) async {
    try {
      final riderDoc = await FirebaseService.firestore.collection('users').doc(riderId).get();
      if (riderDoc.exists) {
        final riderData = riderDoc.data() as Map<String, dynamic>?;
        return riderData?['name'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching rider name: $e');
    }
    return null;
  }

  Future<void> _handleCollectPayment(OrderModel order) async {
    if (order.riderId == null) return;

    final riderName = await _getRiderName(order.riderId!);
    final displayName = riderName ?? 'Rider';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.payment,
              color: Colors.green,
              size: Sizes.s24,
            ),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                'Collect Payment',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm that you have collected payment from $displayName?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Sizes.s16),
            Container(
              padding: const EdgeInsets.all(Sizes.s12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Sizes.s8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: Sizes.s20),
                  const SizedBox(width: Sizes.s8),
                  Expanded(
                    child: Text(
                      'Amount: ${CurrencyFormatter.format(order.totalAmount)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              'Collect Payment',
              style: AppTextStyles.buttonLargeBold.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null || currentUser.userType != UserType.admin) {
        throw Exception('Only admins can collect payment');
      }

      final success = await OrderService.collectPaymentFromRider(
        orderId: order.id,
        adminId: currentUser.id!,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment collected successfully from $displayName',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // StreamBuilder will automatically update the UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to collect payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAssignRider(OrderModel order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RiderSelectionDialog(
        orderId: order.id,
        currentRiderId: order.riderId,
      ),
    );

    if (result == true && mounted) {
      // Rider was assigned successfully, dialog already shows success message
      // The StreamBuilder will automatically update the UI
    }
  }

  Future<void> _handleEditOrder(OrderModel order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => OrderEditDialog(order: order),
    );

    if (result == true && mounted) {
      // Order was edited successfully, dialog already shows success message
      // The StreamBuilder will automatically update the UI
    }
  }

  Future<void> _handleUpdateStatus(OrderModel order) async {
    final currentUser = _authController.currentUser;
    if (currentUser == null || currentUser.userType != UserType.admin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unauthorized: Admin access required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final newStatus = await showDialog<OrderStatus>(
      context: context,
      builder: (context) => _StatusUpdateDialog(currentStatus: order.status),
    );

    if (newStatus != null && newStatus != order.status) {
      final success = await OrderService.updateOrderStatus(
        order.id,
        newStatus,
        userId: currentUser.id!,
        userType: 'admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Order status updated successfully'
                : 'Failed to update order status. You may not have permission to change this status.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _StatusUpdateDialog extends StatelessWidget {
  final OrderStatus currentStatus;

  const _StatusUpdateDialog({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final availableStatuses = _getAvailableStatuses(currentStatus);

    return AlertDialog(
      title: const Text('Update Order Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableStatuses.map((status) {
            return ListTile(
              title: Text(_getStatusText(status)),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<OrderStatus> _getAvailableStatuses(OrderStatus current) {
    // Admin can only change: created/sentToAdmin → assignedToRider, or cancel orders
    switch (current) {
      case OrderStatus.created:
      case OrderStatus.sentToAdmin:
        return [OrderStatus.assignedToRider, OrderStatus.cancelled];
      // Admin cannot change status once rider is involved
      case OrderStatus.assignedToRider:
      case OrderStatus.acceptedByRider:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
      case OrderStatus.nearAddress:
      case OrderStatus.atLocation:
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'New Order';
      case OrderStatus.sentToAdmin:
        return 'New Order'; // Treat sentToAdmin same as created
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
