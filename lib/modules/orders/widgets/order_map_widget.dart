import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/rider_location_service.dart' as RiderLocation;

class OrderMapWidget extends StatefulWidget {
  final OrderModel order;
  final Map<String, double>? customerLocation;

  const OrderMapWidget({super.key, required this.order, this.customerLocation});

  @override
  State<OrderMapWidget> createState() => _OrderMapWidgetState();
}

class _OrderMapWidgetState extends State<OrderMapWidget> {
  GoogleMapController? _mapController;
  Map<MarkerId, Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, double>? _riderLocation;
  Map<String, double>? _restaurantLocation;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantLocation();
    if (widget.order.riderId != null) {
      _listenToRiderLocation();
    }
  }

  Future<void> _fetchRestaurantLocation() async {
    try {
      final restaurantDoc = await FirebaseService.firestore.collection('restaurants').doc(widget.order.restaurantId).get();

      if (restaurantDoc.exists && mounted) {
        final data = restaurantDoc.data();
        if (data != null && data['location'] != null) {
          final locationData = data['location'] as Map;
          setState(() {
            _restaurantLocation = {
              'latitude': (locationData['latitude'] ?? locationData['lat'] ?? 0.0).toDouble(),
              'longitude': (locationData['longitude'] ?? locationData['lng'] ?? 0.0).toDouble(),
            };
          });
          _updateMarkers();
          _updatePolylines();
        }
      }
    } catch (e) {
      debugPrint('Error fetching restaurant location: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _listenToRiderLocation() {
    if (widget.order.riderId == null) return;

    RiderLocation.RiderLocationService.getRiderLocationStream(widget.order.riderId!).listen((location) {
      if (mounted) {
        setState(() {
          _riderLocation = location;
        });
        _updateMarkers();
        _updatePolylines();
        if (location != null) {
          _moveCameraToRider(location);
        }
      }
    });
  }

  bool _isValidLocation(Map<String, double>? location) {
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

  void _updateMarkers() {
    _markers.clear();

    // Restaurant location marker (Red icon)
    if (_isValidLocation(_restaurantLocation)) {
      try {
        final restaurantMarker = Marker(
          markerId: const MarkerId('restaurant'),
          position: LatLng(_restaurantLocation!['latitude']!, _restaurantLocation!['longitude']!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.order.restaurantName ?? 'Restaurant', snippet: 'Pickup Location'),
        );
        _markers[const MarkerId('restaurant')] = restaurantMarker;
      } catch (e) {
        debugPrint('Error creating restaurant marker: $e');
      }
    }

    // Customer location marker (Green icon)
    if (_isValidLocation(widget.customerLocation)) {
      try {
        final customerMarker = Marker(
          markerId: const MarkerId('customer'),
          position: LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Delivery Address', snippet: 'Customer Location'),
        );
        _markers[const MarkerId('customer')] = customerMarker;
      } catch (e) {
        debugPrint('Error creating customer marker: $e');
      }
    }

    // Rider location marker (Orange/Blue icon)
    if (_isValidLocation(_riderLocation)) {
      try {
        final riderMarker = Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Rider', snippet: 'On the way'),
        );
        _markers[const MarkerId('rider')] = riderMarker;
      } catch (e) {
        debugPrint('Error creating rider marker: $e');
      }
    }

    setState(() {});
  }

  void _updatePolylines() {
    _polylines.clear();
    
    // Check if order is picked up or on the way
    final isPickedUpOrOnTheWay = widget.order.status == OrderStatus.pickedUp || 
                                  widget.order.status == OrderStatus.onTheWay;

    if (isPickedUpOrOnTheWay) {
      // Order is picked up and on the way: Show polyline between rider and customer only
      if (_isValidLocation(_riderLocation) && _isValidLocation(widget.customerLocation)) {
        final points = [
          LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!),
          LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!),
        ];
        // Get primary color from theme
        final primaryColor = Theme.of(context).colorScheme.primary;
        _polylines.add(Polyline(
          polylineId: const PolylineId('rider_to_customer'),
          points: points,
          color: primaryColor,
          width: 5,
          patterns: [],
        ));
      }
    } else {
      // Order not picked up yet: Show polyline from rider -> restaurant -> customer
      
      // If we have all three points: rider -> restaurant -> customer (continuous line)
      if (_isValidLocation(_riderLocation) && _isValidLocation(_restaurantLocation) && _isValidLocation(widget.customerLocation)) {
        final points = [
          LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!),
          LatLng(_restaurantLocation!['latitude']!, _restaurantLocation!['longitude']!),
          LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!),
        ];
        _polylines.add(Polyline(
          polylineId: const PolylineId('rider_to_restaurant_to_customer'),
          points: points,
          color: Colors.blue,
          width: 5,
          patterns: [],
        ));
      }
      // If we have rider and restaurant but no customer: rider -> restaurant
      else if (_isValidLocation(_riderLocation) && _isValidLocation(_restaurantLocation) && !_isValidLocation(widget.customerLocation)) {
        final points = [
          LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!),
          LatLng(_restaurantLocation!['latitude']!, _restaurantLocation!['longitude']!),
        ];
        _polylines.add(Polyline(
          polylineId: const PolylineId('rider_to_restaurant'),
          points: points,
          color: Colors.orange,
          width: 4,
          patterns: [],
        ));
      }
      // If we have restaurant and customer but no rider: restaurant -> customer (dashed)
      else if (_isValidLocation(_restaurantLocation) && _isValidLocation(widget.customerLocation) && !_isValidLocation(_riderLocation)) {
        final points = [
          LatLng(_restaurantLocation!['latitude']!, _restaurantLocation!['longitude']!),
          LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!),
        ];
        _polylines.add(Polyline(
          polylineId: const PolylineId('restaurant_to_customer'),
          points: points,
          color: Colors.grey,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
      // If we have rider and customer but no restaurant: rider -> customer
      else if (_isValidLocation(_riderLocation) && _isValidLocation(widget.customerLocation) && !_isValidLocation(_restaurantLocation)) {
        final points = [
          LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!),
          LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!),
        ];
        // Get primary color from theme
        final primaryColor = Theme.of(context).colorScheme.primary;
        _polylines.add(Polyline(
          polylineId: const PolylineId('rider_to_customer_fallback'),
          points: points,
          color: primaryColor,
          width: 4,
          patterns: [],
        ));
      }
    }

    setState(() {});
  }

  void _moveCameraToRider(Map<String, double> location) {
    if (!_isValidLocation(location)) return;
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(location['latitude']!, location['longitude']!)));
    } catch (e) {
      debugPrint('Error moving camera to rider: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Set initial camera position
    try {
      if (_isValidLocation(widget.customerLocation)) {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!), 14.0));
      } else if (_isValidLocation(_riderLocation)) {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!), 14.0));
      }
    } catch (e) {
      debugPrint('Error setting initial camera position: $e');
    }

    _updateMarkers();
    _updatePolylines();

    // Fit bounds to show all markers after map is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _fitBoundsToShowAllMarkers();
    });
  }

  void _fitBoundsToShowAllMarkers() {
    if (_markers.isEmpty) return;

    final List<LatLng> positions = [];
    for (final marker in _markers.values) {
      positions.add(marker.position);
    }

    if (positions.isEmpty) return;

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    try {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding as double (pixels)
        ),
      );
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    // Determine initial camera position with validation
    LatLng initialPosition;
    double initialZoom = 14.0;

    try {
      if (_isValidLocation(_riderLocation)) {
        initialPosition = LatLng(_riderLocation!['latitude']!, _riderLocation!['longitude']!);
      } else if (_isValidLocation(widget.customerLocation)) {
        initialPosition = LatLng(widget.customerLocation!['latitude']!, widget.customerLocation!['longitude']!);
      } else if (_isValidLocation(_restaurantLocation)) {
        initialPosition = LatLng(_restaurantLocation!['latitude']!, _restaurantLocation!['longitude']!);
      } else {
        // Default to a safe location (avoid 0,0 which can cause issues)
        // Using a default location that won't crash
        initialPosition = const LatLng(37.7749, -122.4194); // San Francisco as default
        initialZoom = 10.0;
      }
    } catch (e) {
      debugPrint('Error determining initial position: $e');
      // Fallback to safe default
      initialPosition = const LatLng(37.7749, -122.4194);
      initialZoom = 10.0;
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(target: initialPosition, zoom: initialZoom),
          markers: Set<Marker>.from(_markers.values),
          polylines: _polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapType: MapType.normal,
        ),
        // Custom Zoom Buttons
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              // Zoom In Button
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: InkWell(
                  onTap: _zoomIn,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Zoom Out Button
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: InkWell(
                  onTap: _zoomOut,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
