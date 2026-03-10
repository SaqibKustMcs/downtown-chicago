import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/services/location_service.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/modules/location/services/address_service.dart';
import 'package:downtown/modules/location/models/address_model.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class DeliveryAddressConfirmationScreen extends StatefulWidget {
  final double totalAmount;
  final String? initialAddress;

  const DeliveryAddressConfirmationScreen({
    super.key,
    required this.totalAmount,
    this.initialAddress,
  });

  @override
  State<DeliveryAddressConfirmationScreen> createState() => _DeliveryAddressConfirmationScreenState();
}

class _DeliveryAddressConfirmationScreenState extends State<DeliveryAddressConfirmationScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  final Set<Marker> _markers = {};
  
  final _noteController = TextEditingController();
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _authController = DependencyInjection.instance.authController;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
    _useCurrentLocation(); // Automatically get current location
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _loadCurrentAddress() {
    final currentUser = _authController.currentUser;
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      setState(() {
        _selectedAddress = widget.initialAddress;
      });
    } else if (currentUser?.address != null && currentUser!.address!.isNotEmpty) {
      setState(() {
        _selectedAddress = currentUser.address;
      });
      
      if (currentUser.userLatLng != null) {
        final lat = currentUser.userLatLng!['latitude'] as double?;
        final lng = currentUser.userLatLng!['longitude'] as double?;
        if (lat != null && lng != null) {
          setState(() {
            _selectedLocation = LatLng(lat, lng);
            _addMarker(_selectedLocation!, _selectedAddress!);
          });
        }
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final status = await LocationService.checkLocationAccess();

      if (!mounted) return;

      switch (status) {
        case LocationAccessStatus.serviceDisabled:
          setState(() => _isLoadingLocation = false);
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Location is off'),
              content: const Text(
                'Turn on device location in settings to use your current location.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (openSettings == true) {
            await Geolocator.openLocationSettings();
          }
          return;
        case LocationAccessStatus.permissionDenied:
          setState(() {
            _isLoadingLocation = false;
            _errorMessage = 'Location permission is required to use your current location.';
          });
          return;
        case LocationAccessStatus.permissionDeniedForever:
          setState(() => _isLoadingLocation = false);
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Location permission'),
              content: const Text(
                'Location access was denied. Open app settings to allow location.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (openSettings == true) {
            await openAppSettings();
          }
          return;
        case LocationAccessStatus.ready:
          break;
      }

      final locationData = await LocationService.getCurrentLocationAndAddress();
      
      if (locationData != null && mounted) {
        final lat = locationData['latitude'] as double;
        final lng = locationData['longitude'] as double;
        final address = locationData['address'] as String;

        setState(() {
          _selectedLocation = LatLng(lat, lng);
          _selectedAddress = address;
          _addMarker(_selectedLocation!, _selectedAddress!);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0));
      } else {
        setState(() {
          _errorMessage = 'Could not get your current location. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedLocation != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0));
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final address = await LocationService.getAddressFromCoordinates(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

      if (address != null && mounted) {
        setState(() {
          _selectedLocation = latLng;
          _selectedAddress = address;
          _addMarker(latLng, address);
        });
      } else {
        setState(() {
          _errorMessage = 'Could not find address for this location.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting address: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _addMarker(LatLng position, String title) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId(position.toString()),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _confirmAddress() async {
    if (_selectedLocation == null || _selectedAddress == null) {
      setState(() {
        _errorMessage = 'Please select a location first.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final currentUser = _authController.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not logged in.';
        });
        return;
      }

      // Don't save address here - will be saved after order is placed
      // Just navigate to phone verification screen
      if (mounted) {
        // Navigate to phone verification screen
        Navigator.pushNamed(
          context,
          Routes.phoneVerification,
          arguments: {
            'totalAmount': widget.totalAmount,
            'deliveryAddress': _selectedAddress,
            'deliveryNote': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            'addressTitle': _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving address: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            _buildTopNavigation(context),

            // Use Current Location Button
            _buildUseCurrentLocationButton(context),

            // Error Message
            if (_errorMessage != null) _buildErrorMessage(context),

            // Map View
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? const LatLng(0, 0),
                      zoom: _selectedLocation != null ? 15 : 2,
                    ),
                    onTap: _onMapTap,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  if (_isLoadingLocation)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                      ),
                    ),
                ],
              ),
            ),

            // Address Form
            _buildAddressForm(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s12),
      child: Row(
        children: [
          Container(
            width: Sizes.s40,
            height: Sizes.s40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
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
          Expanded(
            child: Text(
              'Confirm Delivery Address',
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

  Widget _buildUseCurrentLocationButton(BuildContext context) {
    return GestureDetector(
      onTap: _isLoadingLocation ? null : _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(TablerIconsHelper.navigation, color: const Color(0xFFFF6B35), size: Sizes.s20),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                'Use my current location',
                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            if (_isLoadingLocation)
              const SizedBox(
                width: Sizes.s20,
                height: Sizes.s20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s12),
      margin: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.s8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: Sizes.s20),
          const SizedBox(width: Sizes.s8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Sizes.s24),
          topRight: Radius.circular(Sizes.s24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: Sizes.s10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Address Display
                Row(
                  children: [
                    Icon(TablerIconsHelper.location, color: const Color(0xFFFF6B35), size: Sizes.s20),
                    const SizedBox(width: Sizes.s12),
                    Expanded(
                      child: Text(
                        _selectedAddress ?? 'No location selected',
                        style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Sizes.s16),

                // Address Title (Optional)
                Text(
                  'Address Title (Optional)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                CustomTextField(
                  controller: _titleController,
                  hintText: 'e.g., Home, Office, Work',
                ),
                const SizedBox(height: Sizes.s16),

                // Note to Rider
                Text(
                  'Note to Rider, Nearest Landmark',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Sizes.s8),
                CustomTextField(
                  controller: _noteController,
                  hintText: 'e.g., Near the blue building, 2nd floor',
                  maxLines: 3,
                ),
                const SizedBox(height: Sizes.s24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: Sizes.s56,
                  child: ElevatedButton(
                    onPressed: _isLoadingLocation ? null : _confirmAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                    ),
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: Sizes.s20,
                            height: Sizes.s20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'CONFIRM ADDRESS',
                            style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
