import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Map View
            Column(
              children: [
                // Top Navigation
                _buildTopNavigation(context),
                
                // Map
                Expanded(
                  child: CustomPaint(
                    painter: _MapPainter(
                      pickupLocation: const Offset(0.2, 0.7),
                      deliveryLocation: const Offset(0.8, 0.3),
                      animation: _animation,
                      isDark: isDark,
                    ),
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
                child: _buildOrderSummaryPanel(context),
              ),
            ),
          ],
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
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                TablerIconsHelper.arrowLeft,
                color: Theme.of(context).colorScheme.onSurface,
                size: Sizes.s20,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: Sizes.s12),
          
          // Title
          Text(
            'Track Order',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Sizes.s24),
          topRight: Radius.circular(Sizes.s24),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(Sizes.s2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(Sizes.s12),
                  child: CachedNetworkImage(
                    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&q=80',
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
                const SizedBox(width: Sizes.s16),
                
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name
                      Text(
                        'Uttora Coffee House',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Sizes.s4),
                      
                      // Order Time
                      Text(
                        'Orderd At 06 Sept, 10:00pm',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: Sizes.s12),
                      
                      // Ordered Items
                      Text(
                        '2x Burger',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Sizes.s4),
                      Text(
                        '4x Sanwitch',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
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

  _MapPainter({
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.animation,
    required this.isDark,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background (theme-aware)
    final backgroundPaint = Paint()
      ..color = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
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
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        roadOutlinePaint,
      );
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        roadPaint,
      );
    }

    // Vertical roads
    for (double x = 0.2; x <= 0.8; x += 0.2) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        roadOutlinePaint,
      );
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        roadPaint,
      );
    }

    // Draw green areas (parks) - theme-aware
    final greenPaint = Paint()
      ..color = isDark ? Colors.green.shade800 : Colors.green.shade100;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.1, size.width * 0.3, size.height * 0.25),
      greenPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.5, size.width * 0.2, size.height * 0.15),
      greenPaint,
    );

    // Draw orange areas (water/features) - theme-aware
    final orangePaint = Paint()
      ..color = isDark ? Colors.orange.shade900 : Colors.orange.shade100;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.2, size.width * 0.15, size.height * 0.2),
      orangePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.6, size.width * 0.2, size.height * 0.15),
      orangePaint,
    );

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
    routePath.cubicTo(
      size.width * 0.4,
      size.height * 0.6,
      size.width * 0.6,
      size.height * 0.4,
      deliveryPoint.dx,
      deliveryPoint.dy,
    );

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
