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

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  String? _currentAddress;
  String? _selectedSavedAddressId; // id of selected saved address, null = from map/current
  bool _isLoadingLocation = false;
  String? _errorMessage;
  final Set<Marker> _markers = {};
  final _authController = DependencyInjection.instance.authController;
  final _extraDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  void _selectSavedAddress(AddressModel address) async {
    setState(() {
      _selectedSavedAddressId = address.id;
      _currentAddress = address.address;
      _extraDetailsController.text = address.note ?? '';
      if (address.latitude != null && address.longitude != null) {
        _currentLocation = LatLng(address.latitude!, address.longitude!);
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(address.id),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
        );
      } else {
        _currentLocation = null;
        _markers.clear();
      }
    });
    final userId = _authController.currentUser?.id;
    if (userId != null) {
      try {
        await AddressService.setDefaultAddress(userId, address.id);
        await _authController.refreshUser();
      } catch (e) {
        debugPrint('Error setting default address: $e');
      }
    }
  }

  void _loadCurrentAddress() async {
    final currentUser = _authController.currentUser;
    if (currentUser?.address != null && currentUser!.address!.isNotEmpty) {
      setState(() {
        _currentAddress = currentUser.address;
      });
      
      // If user has coordinates, load them on map
      if (currentUser.userLatLng != null) {
        final lat = currentUser.userLatLng!['latitude'] as double?;
        final lng = currentUser.userLatLng!['longitude'] as double?;
        if (lat != null && lng != null) {
          setState(() {
            _currentLocation = LatLng(lat, lng);
            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('current_location'),
                position: _currentLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          });
          
          // Move camera to user's location after map is created
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
            );
          });
        }
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
      _selectedSavedAddressId = null;
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

      // Get current location and address
      final locationData = await LocationService.getCurrentLocationAndAddress();
      
      if (locationData != null) {
        final lat = locationData['latitude'] as double;
        final lng = locationData['longitude'] as double;
        final address = locationData['address'] as String;

        setState(() {
          _currentLocation = LatLng(lat, lng);
          _currentAddress = address;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
        );

        // Save to user profile
        if (_authController.isAuthenticated()) {
          await _authController.updateUserLocation(
            address: address,
            latitude: lat,
            longitude: lng,
          );
        }
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
    if (_currentLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedSavedAddressId = null;
      _currentLocation = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _currentAddress = 'Loading address...';
    });

    // Reverse geocode to get address from coordinates
    try {
      final address = await LocationService.getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (mounted) {
        setState(() {
          _currentAddress = address ?? '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      if (mounted) {
        setState(() {
          _currentAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    }
  }

  Future<void> _saveCurrentAddress() async {
    if (_currentAddress == null || _currentAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_authController.isAuthenticated()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userId = _authController.currentUser!.id;
      
      final extraDetails = _extraDetailsController.text.trim();
      await AddressService.addAddress(
        userId: userId,
        address: _currentAddress!,
        note: extraDetails.isEmpty ? null : extraDetails,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        setAsDefault: true,
      );

      // Refresh user data
      await _authController.refreshUser();

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate address was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
            
            // Country Selection
            _buildCountrySection(context),

            // Saved addresses
            _buildSavedAddressesSection(context),
            
            // Use Current Location Button
            _buildCurrentLocationButton(context),
            
            // Map View
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? const LatLng(24.8607, 67.0011), // Default to Karachi
                      zoom: 12.0,
                    ),
                    markers: _markers,
                    onTap: _onMapTap,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  
                  // Loading overlay
                  if (_isLoadingLocation)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            
            // Current Address Display
            if (_currentAddress != null)
              _buildAddressDisplay(context),
            
            // Add New Address Button
            _buildAddAddressButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              TablerIconsHelper.arrowLeft,
              color: Theme.of(context).colorScheme.onSurface,
              size: Sizes.s24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: Sizes.s8),
          Expanded(
            child: Text(
              'Select Delivery Address',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesSection(BuildContext context) {
    final currentUser = _authController.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<List<AddressModel>>(
      stream: AddressService.getUserAddresses(currentUser.id!),
      builder: (context, snapshot) {
        // Show only 3 latest saved addresses (already ordered by createdAt desc from service)
        final addresses = (snapshot.data ?? []).take(3).toList();
        if (addresses.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade200,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saved addresses',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Sizes.s8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final isSelected = _selectedSavedAddressId == address.id;
                    final label = address.label?.trim().isNotEmpty == true
                        ? address.label!
                        : 'Address ${index + 1}';
                    return Padding(
                      padding: const EdgeInsets.only(right: Sizes.s12),
                      child: Material(
                        color: isSelected
                            ? const Color(0xFFFF6B35).withOpacity(0.12)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Sizes.s12),
                        child: InkWell(
                          onTap: () => _selectSavedAddress(address),
                          borderRadius: BorderRadius.circular(Sizes.s12),
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(Sizes.s12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Sizes.s12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF6B35)
                                    : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      TablerIconsHelper.location,
                                      size: Sizes.s16,
                                      color: isSelected
                                          ? const Color(0xFFFF6B35)
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: Sizes.s6),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Sizes.s6),
                                Text(
                                  address.address,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountrySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TablerIconsHelper.world,
            color: Theme.of(context).colorScheme.onSurface,
            size: Sizes.s20,
          ),
          const SizedBox(width: Sizes.s12),
          const Text('🇵🇰', style: TextStyle(fontSize: Sizes.s20)),
          const SizedBox(width: Sizes.s8),
          Expanded(
            child: Text(
              'Pakistan',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Show country selection dialog
            },
            child: Text(
              'Change',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFFF6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: InkWell(
        onTap: _useCurrentLocation,
        child: Row(
          children: [
            Icon(
              TablerIconsHelper.navigation,
              color: const Color(0xFFFF6B35),
              size: Sizes.s20,
            ),
            const SizedBox(width: Sizes.s12),
            Expanded(
              child: Text(
                'Use my current location',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (_isLoadingLocation)
              const SizedBox(
                width: Sizes.s20,
                height: Sizes.s20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                TablerIconsHelper.location,
                color: const Color(0xFFFF6B35),
                size: Sizes.s20,
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: Text(
                  _currentAddress ?? 'Select a location',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
          Text(
            'Extra details for rider (optional)',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: Sizes.s8),
          CustomTextField(
            controller: _extraDetailsController,
            hintText: 'e.g. landmark, floor, gate code – helps rider find you',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAddAddressButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TablerIconsHelper.plus,
            color: const Color(0xFFFF6B35),
            size: Sizes.s20,
          ),
          const SizedBox(width: Sizes.s12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, Routes.addAddress, arguments: {
                  'address': _currentAddress,
                  'latitude': _currentLocation?.latitude,
                  'longitude': _currentLocation?.longitude,
                }).then((result) {
                  if (result == true) {
                    _loadCurrentAddress();
                  }
                });
              },
              child: Text(
                'Add New Address',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ),
          ),
          if (_currentAddress != null)
            ElevatedButton(
              onPressed: _saveCurrentAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.s8),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _extraDetailsController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
