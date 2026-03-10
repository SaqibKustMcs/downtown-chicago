import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_status_chip.dart';
import 'package:downtown/modules/orders/widgets/order_map_widget.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _authController = DependencyInjection.instance.authController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidCustomerLocation(Map<String, double>? location) {
    if (location == null) return false;
    final lat = location['latitude'];
    final lng = location['longitude'];
    if (lat == null || lng == null) return false;
    // Check if coordinates are valid (not 0,0 which is in the ocean)
    if (lat == 0.0 && lng == 0.0) return false;
    // Check if coordinates are within valid ranges
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  _buildTopNavigation(context),
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
            final pickupLocation = const Offset(0.2, 0.7); // Restaurant location (placeholder)
            final deliveryLocation = order.customerLatLng != null
                ? Offset((order.customerLatLng!['longitude']! + 180) / 360, (90 - order.customerLatLng!['latitude']!) / 180)
                : const Offset(0.8, 0.3);

            return Stack(
              children: [
                // Map View
                Column(
                  children: [
                    // Top Navigation
                    TopNavigationBar(title: 'Track Order', showBackButton: true),

                    // Google Map
                    Expanded(
                      child: _isValidCustomerLocation(order.customerLatLng) && order.riderId != null
                          ? OrderMapWidget(order: order, customerLocation: order.customerLatLng)
                          : CustomPaint(
                              painter: _MapPainter(pickupLocation: pickupLocation, deliveryLocation: deliveryLocation, animation: _animation, isDark: isDark),
                              child: Container(),
                            ),
                    ),
                  ],
                ),

                // Bottom Order Summary Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedCard(
                    delay: const Duration(milliseconds: 200),
                    child: _authController.currentUser?.userType == UserType.rider
                        ? _buildCustomerDetailsPanel(context, order)
                        : _buildOrderSummaryPanel(context, order),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          // Back Button
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(TablerIconsHelper.arrowLeft, color: Theme.of(context).colorScheme.onSurface, size: Sizes.s20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),

          // Title
          Text(
            'Track Order',
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryPanel(BuildContext context, OrderModel order) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = order.items.isNotEmpty ? order.items.first['imageUrl'] as String? : null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s24), topRight: Radius.circular(Sizes.s24)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1), blurRadius: Sizes.s16, offset: const Offset(0, -Sizes.s4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: Sizes.s12),
            width: Sizes.s40,
            height: Sizes.s4,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, borderRadius: BorderRadius.circular(Sizes.s2)),
          ),

          Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Chip
                Center(child: OrderStatusChip(status: order.status)),
                const SizedBox(height: Sizes.s16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Image
                    if (imageUrl != null)
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
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: Sizes.s80,
                            height: Sizes.s80,
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    if (imageUrl != null) const SizedBox(width: Sizes.s16),

                    // Order Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Restaurant Name
                          Text(
                            order.restaurantName ?? 'Restaurant',
                            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const SizedBox(height: Sizes.s4),

                          // Order Time
                          if (order.createdAt != null)
                            Text(
                              'Ordered At ${dateFormat.format(order.createdAt!)}',
                              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          const SizedBox(height: Sizes.s12),

                          // Ordered Items (show first 2)
                          ...order.items.take(2).map((item) {
                            final quantity = item['quantity'] as int? ?? 0;
                            final name = item['name'] as String? ?? 'Item';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: Sizes.s4),
                              child: Text('$quantity $name', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                            );
                          }),
                          if (order.items.length > 2)
                            Text('+${order.items.length - 2} more items', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsPanel(BuildContext context, OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Sizes.s24), topRight: Radius.circular(Sizes.s24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: Sizes.s16,
            offset: const Offset(0, -Sizes.s4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: Sizes.s12),
            width: Sizes.s40,
            height: Sizes.s4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(Sizes.s2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Chip
                Center(child: OrderStatusChip(status: order.status)),
                const SizedBox(height: Sizes.s16),

                // Customer Details Section
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseService.firestore.collection('users').doc(order.customerId).snapshots(),
                  builder: (context, customerSnapshot) {
                    if (customerSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(Sizes.s16), child: CircularProgressIndicator()));
                    }

                    final customerData = customerSnapshot.data?.data() as Map<String, dynamic>?;
                    final customerName = customerData != null
                        ? '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim()
                        : 'Customer';
                    final customerPhone = customerData?['phoneNumber'] as String?;
                    final customerEmail = customerData?['email'] as String?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Info Header
                        Row(
                          children: [
                            Container(
                              width: Sizes.s48,
                              height: Sizes.s48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: const Color(0xFFFF6B35), size: Sizes.s24),
                            ),
                            const SizedBox(width: Sizes.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName.isNotEmpty ? customerName : 'Customer',
                                    style: AppTextStyles.heading3.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  if (customerPhone != null) ...[
                                    const SizedBox(height: Sizes.s4),
                                    Row(
                                      children: [
                                        Icon(Icons.phone, size: Sizes.s14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                        const SizedBox(width: Sizes.s4),
                                        Text(
                                          customerPhone,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sizes.s16),

                        // Delivery Address Section
                        Container(
                          padding: const EdgeInsets.all(Sizes.s12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(Sizes.s12),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                            ),
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
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Sizes.s8),
                              if (order.deliveryAddress != null)
                                Text(
                                  order.deliveryAddress!,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                )
                              else
                                Text(
                                  'Address not provided',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Sizes.s12),

                        // Order Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
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
                                  '#${order.id.substring(0, 8).toUpperCase()}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            if (order.createdAt != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Order Time',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: Sizes.s4),
                                  Text(
                                    dateFormat.format(order.createdAt!),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Offset pickupLocation;
  final Offset deliveryLocation;
  final Animation<double> animation;
  final bool isDark;

  _MapPainter({required this.pickupLocation, required this.deliveryLocation, required this.animation, required this.isDark}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background (theme-aware)
    final backgroundPaint = Paint()..color = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw roads (theme-aware)
    final roadPaint = Paint()
      ..color = isDark ? Colors.grey.shade700 : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final roadOutlinePaint = Paint()
      ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    // Horizontal roads
    for (double y = 0.2; y <= 0.8; y += 0.2) {
      canvas.drawLine(Offset(0, size.height * y), Offset(size.width, size.height * y), roadOutlinePaint);
      canvas.drawLine(Offset(0, size.height * y), Offset(size.width, size.height * y), roadPaint);
    }

    // Vertical roads
    for (double x = 0.2; x <= 0.8; x += 0.2) {
      canvas.drawLine(Offset(size.width * x, 0), Offset(size.width * x, size.height), roadOutlinePaint);
      canvas.drawLine(Offset(size.width * x, 0), Offset(size.width * x, size.height), roadPaint);
    }

    // Draw green areas (parks) - theme-aware
    final greenPaint = Paint()..color = isDark ? Colors.green.shade800 : Colors.green.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.6, size.height * 0.1, size.width * 0.3, size.height * 0.25), greenPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.5, size.width * 0.2, size.height * 0.15), greenPaint);

    // Draw orange areas (water/features) - theme-aware
    final orangePaint = Paint()..color = isDark ? Colors.orange.shade900 : Colors.orange.shade100;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.2, size.width * 0.15, size.height * 0.2), orangePaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.7, size.height * 0.6, size.width * 0.2, size.height * 0.15), orangePaint);

    // Draw delivery route (orange line)
    final routePaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final routePath = Path();
    final pickupPoint = Offset(size.width * pickupLocation.dx, size.height * pickupLocation.dy);
    final deliveryPoint = Offset(size.width * deliveryLocation.dx, size.height * deliveryLocation.dy);

    // Create curved path
    routePath.moveTo(pickupPoint.dx, pickupPoint.dy);
    routePath.cubicTo(size.width * 0.4, size.height * 0.6, size.width * 0.6, size.height * 0.4, deliveryPoint.dx, deliveryPoint.dy);

    canvas.drawPath(routePath, routePaint);

    // Draw pickup location marker (red with pin icon)
    final pickupMarkerPaint = Paint()..color = Colors.red;
    canvas.drawCircle(pickupPoint, 20, pickupMarkerPaint);

    // White circle inside
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(pickupPoint, 12, whitePaint);

    // Pin icon (simplified as a small circle)
    final pinPaint = Paint()..color = Colors.red;
    canvas.drawCircle(pickupPoint, 6, pinPaint);

    // Draw delivery location marker (yellow with orange rings)
    final deliveryMarkerPaint = Paint()..color = Colors.yellow.shade700;
    canvas.drawCircle(deliveryPoint, 20, deliveryMarkerPaint);

    // White dot in center
    canvas.drawCircle(deliveryPoint, 8, whitePaint);

    // Animated orange rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFF6B35).withOpacity(0.3 * (1 - animation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final ringRadius1 = 20 + (animation.value * 15);
    final ringRadius2 = 20 + (animation.value * 25);

    canvas.drawCircle(deliveryPoint, ringRadius1, ringPaint);
    canvas.drawCircle(deliveryPoint, ringRadius2, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
