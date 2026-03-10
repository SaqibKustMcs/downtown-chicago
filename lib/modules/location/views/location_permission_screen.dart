import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/services/location_service.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleAccessLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        // Location services are disabled, show dialog to enable
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                'Location services are disabled. Please enable location services in your device settings to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await Geolocator.openLocationSettings();
            // Check again after user returns
            serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Please enable location services to continue.';
              });
              return;
            }
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Location services must be enabled to continue.';
            });
            return;
          }
        }
      }

      // Check location permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permission is required to use this app.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission is permanently denied, show dialog to open settings
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permission is permanently denied. Please enable it in app settings to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
            // Check permission again after user returns
            permission = await Geolocator.checkPermission();
            if (permission != LocationPermission.whileInUse &&
                permission != LocationPermission.always) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Please grant location permission in app settings.';
              });
              return;
            }
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Location permission is required to continue.';
            });
            return;
          }
        }
      }

      // Permission granted, get current location and address
      try {
        final locationData = await LocationService.getCurrentLocationAndAddress();
        
        if (locationData != null && mounted) {
          // Update user address in Firebase
          final authController = DependencyInjection.instance.authController;
          if (authController.isAuthenticated()) {
            await authController.updateUserLocation(
              address: locationData['address'] as String,
              latitude: locationData['latitude'] as double,
              longitude: locationData['longitude'] as double,
            );
          }
        }
      } catch (e) {
        debugPrint('Error getting location and address: $e');
        // Even if getting location fails, permission is granted, so continue
      }

      // All checks passed, navigate to main container
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.mainContainer);
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Map Graphic with Location Pin
              _buildMapGraphic(context),
              
              const SizedBox(height: Sizes.s48),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(Sizes.s16),
                  margin: const EdgeInsets.only(bottom: Sizes.s16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Sizes.s12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: Sizes.s20,
                      ),
                      const SizedBox(width: Sizes.s12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Access Location Button
              SizedBox(
                width: double.infinity,
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAccessLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.s12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: Sizes.s20,
                          height: Sizes.s20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ACCESS LOCATION',
                              style: AppTextStyles.buttonLargeBold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: Sizes.s8),
                            const Icon(
                              TablerIconsHelper.location,
                              color: Colors.white,
                              size: Sizes.s20,
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: Sizes.s24),
              
              // Privacy Text
              Text(
                'FOOD FLOW WILL ACCESS YOUR LOCATION ONLY WHILE USING THE APP',
                style: AppTextStyles.bodySmallSecondary.copyWith(
                  fontSize: Sizes.s12,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapGraphic(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: Sizes.s240,
      height: Sizes.s240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey.shade800 : const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: Sizes.s20,
            offset: const Offset(0, Sizes.s8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Map Grid Pattern
          CustomPaint(
            painter: _MapPatternPainter(isDark: isDark),
            size: Size(Sizes.s240, Sizes.s240),
          ),
          
          // Location Pin
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: Sizes.s80,
                  height: Sizes.s80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: Sizes.s12,
                        offset: const Offset(0, Sizes.s4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pin Shape
                      CustomPaint(
                        painter: _LocationPinPainter(),
                        size: Size(Sizes.s80, Sizes.s80),
                      ),
                      // White Circle in center
                      Container(
                        width: Sizes.s16,
                        height: Sizes.s16,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
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

class _MapPatternPainter extends CustomPainter {
  final bool isDark;

  _MapPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid lines
    final gridSpacing = size.width / 8;
    for (double i = gridSpacing; i < size.width; i += gridSpacing) {
      // Vertical lines
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Draw streets (yellow roads) - theme-aware
    final streetPaint = Paint()
      ..color = isDark ? Colors.yellow.shade800 : const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;

    // Main horizontal street
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.15),
      streetPaint,
    );

    // Main vertical street
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.15, size.height),
      streetPaint,
    );

    // Secondary horizontal street
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.1),
      streetPaint,
    );

    // Secondary vertical street
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.65, 0, size.width * 0.1, size.height),
      streetPaint,
    );

    // Green area (park) - theme-aware
    final greenPaint = Paint()
      ..color = isDark ? Colors.green.shade800 : const Color(0xFFC8E6C9)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.1, size.width * 0.25, size.height * 0.25),
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.25;
    
    // Draw teardrop shape (pin)
    // Top circle part
    path.addOval(
      Rect.fromCircle(
        center: Offset(centerX, centerY - radius * 0.3),
        radius: radius,
      ),
    );
    
    // Bottom point
    path.moveTo(centerX, centerY + radius * 0.7);
    path.lineTo(centerX - radius * 0.6, centerY + radius * 0.2);
    path.lineTo(centerX + radius * 0.6, centerY + radius * 0.2);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
