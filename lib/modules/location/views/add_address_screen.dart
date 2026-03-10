import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/services/location_service.dart';
import 'package:downtown/modules/auth/widgets/custom_text_field.dart';
import 'package:downtown/modules/location/services/address_service.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AddAddressScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const AddAddressScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingLocation = false;
  bool _setAsDefault = true;

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  static const LatLng _defaultCenter = LatLng(24.8607, 67.0011); // Karachi

  final _authController = DependencyInjection.instance.authController;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _addMarker(_selectedLocation!, widget.initialAddress ?? 'Selected location');
    }
    if (_selectedLocation == null && widget.initialAddress == null) {
      _useCurrentLocation();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _labelController.dispose();
    _mapController?.dispose();
    super.dispose();
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

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
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
          setState(() => _isLoadingLocation = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to use your current location.'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
          _addressController.text = address;
          _addMarker(_selectedLocation!, address);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _isLoadingLocation = true;
      _selectedLocation = latLng;
      _addMarker(latLng, 'Loading...');
    });
    try {
      final address = await LocationService.getAddressFromCoordinates(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
      if (mounted) {
        setState(() {
          _addressController.text = address ?? '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
          _addMarker(latLng, address ?? 'Selected');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressController.text = '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
          _addMarker(latLng, 'Selected');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
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

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _authController.currentUser!.id;

      await AddressService.addAddress(
        userId: userId,
        address: _addressController.text.trim(),
        label: _labelController.text.trim().isNotEmpty ? _labelController.text.trim() : null,
        latitude: _selectedLocation?.latitude ?? widget.initialLatitude,
        longitude: _selectedLocation?.longitude ?? widget.initialLongitude,
        setAsDefault: _setAsDefault,
      );

      await _authController.refreshUser();

      if (mounted) {
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(context),
            _buildUseCurrentLocationButton(context),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (c) {
                      _mapController = c;
                      if (_selectedLocation != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
                        );
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? _defaultCenter,
                      zoom: _selectedLocation != null ? 15.0 : 12.0,
                    ),
                    onTap: _onMapTap,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  if (_isLoadingLocation)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address (tap map to set pin)',
                        style: AppTextStyles.label.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      CustomTextField(
                        controller: _addressController,
                        hintText: 'Tap map pin or use current location',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please set location on map or enter address';
                          }
                          if (value.trim().length < 10) {
                            return 'Please enter a complete address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Sizes.s16),
                      Text(
                        'Label (Optional)',
                        style: AppTextStyles.label.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Sizes.s8),
                      CustomTextField(
                        controller: _labelController,
                        hintText: 'e.g., Home, Work, Office',
                        validator: null,
                      ),
                      const SizedBox(height: Sizes.s12),
                      CheckboxListTile(
                        value: _setAsDefault,
                        onChanged: (value) {
                          setState(() {
                            _setAsDefault = value ?? true;
                          });
                        },
                        title: Text(
                          'Set as default address',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        activeColor: const Color(0xFFFF6B35),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
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
              child: SizedBox(
                width: double.infinity,
                height: Sizes.s56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.s12),
                    ),
                    disabledBackgroundColor: const Color(0xFFFF6B35).withOpacity(0.6),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: Sizes.s20,
                          height: Sizes.s20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save Address',
                          style: AppTextStyles.buttonLargeBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseCurrentLocationButton(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: _isLoadingLocation ? null : _useCurrentLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s12),
          decoration: BoxDecoration(
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                  ),
                ),
            ],
          ),
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
              'Add New Address',
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
}
