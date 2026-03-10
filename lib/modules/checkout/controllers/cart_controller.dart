import 'package:flutter/foundation.dart';
import 'package:downtown/core/base/base_controller.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/delivery_fee_util.dart';
import 'package:downtown/models/cart_item_model.dart';
import 'package:downtown/models/restaurant_model.dart';
import 'package:downtown/modules/admin/services/admin_settings_service.dart';

class CartController extends BaseController {
  final List<CartItem> _cartItems = [];
  double? _cachedDeliveryFee;
  String? _cachedRestaurantId;
  double? _cachedCustomerLat;
  double? _cachedCustomerLon;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal (sum of all cart items)
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Legacy getter for backward compatibility
  double get totalPrice => subtotal;

  /// Delivery fee: distance (restaurant → customer) × pricePerKm.
  /// [customerLat], [customerLon]: delivery address. If null, uses fallback fixed fee from restaurant.
  Future<double> getDeliveryFee({double? customerLat, double? customerLon}) async {
    if (_cartItems.isEmpty) {
      _cachedDeliveryFee = 0.0;
      _cachedRestaurantId = null;
      _cachedCustomerLat = null;
      _cachedCustomerLon = null;
      return 0.0;
    }

    final restaurantId = _cartItems.first.restaurantId;
    if (restaurantId == null) return 0.0;

    final cacheValid =
        _cachedRestaurantId == restaurantId &&
        _cachedDeliveryFee != null &&
        (customerLat == null && customerLon == null || (_cachedCustomerLat == customerLat && _cachedCustomerLon == customerLon));
    if (cacheValid) return _cachedDeliveryFee!;

    try {
      final restaurantDoc = await FirebaseService.firestore.collection('restaurants').doc(restaurantId).get();
      if (!restaurantDoc.exists) return 0.0;

      final data = restaurantDoc.data()!;
      final fallbackFee = (data['deliveryFee'] ?? 0.0).toDouble();
      double? pricePerKm = (data['deliveryPricePerKm'] as num?)?.toDouble();
      if (pricePerKm == null) {
        final appSettings = await AdminSettingsService.instance.getSettings();
        pricePerKm = ((appSettings['defaultDeliveryPricePerKm'] ?? 5.0) as num).toDouble();
      }

      Map<String, double>? loc;
      if (data['location'] != null) {
        final locData = data['location'] as Map;
        loc = {'latitude': (locData['latitude'] ?? locData['lat'] ?? 0.0).toDouble(), 'longitude': (locData['longitude'] ?? locData['lng'] ?? 0.0).toDouble()};
      }

      final fee = DeliveryFeeUtil.calculate(
        restaurantLat: loc?['latitude'],
        restaurantLon: loc?['longitude'],
        customerLat: customerLat,
        customerLon: customerLon,
        pricePerKm: pricePerKm,
        fallbackFee: fallbackFee,
      );

      _cachedDeliveryFee = fee;
      _cachedRestaurantId = restaurantId;
      _cachedCustomerLat = customerLat;
      _cachedCustomerLon = customerLon;
      return fee;
    } catch (e) {
      debugPrint('Error fetching delivery fee: $e');
    }
    return 0.0;
  }

  /// Total price including delivery fee (pass customer coords for distance-based fee)
  Future<double> getTotalWithDeliveryFee({double? customerLat, double? customerLon}) async {
    final fee = await getDeliveryFee(customerLat: customerLat, customerLon: customerLon);
    return subtotal + fee;
  }

  bool get isEmpty => _cartItems.isEmpty;

  /// Add item to cart
  /// If item with same id, variation, and flavor exists, increase quantity
  void addToCart(CartItem item) {
    // Check if item already exists with same variation and flavor
    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.id == item.id && cartItem.selectedVariation == item.selectedVariation && cartItem.selectedFlavor == item.selectedFlavor,
    );

    // Check if restaurant changed (clear cache if so)
    if (_cartItems.isNotEmpty && _cartItems.first.restaurantId != item.restaurantId) {
      _cachedDeliveryFee = null;
      _cachedRestaurantId = null;
    }

    if (existingIndex != -1) {
      // Update quantity
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(quantity: _cartItems[existingIndex].quantity + item.quantity);
    } else {
      // Add new item
      _cartItems.add(item);
    }

    notifyListeners();
  }

  /// Update item quantity by cart item index
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      if (index >= 0 && index < _cartItems.length) {
        _cartItems.removeAt(index);
        notifyListeners();
      }
      return;
    }

    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  /// Clear all items from cart
  void clearCart() {
    _cartItems.clear();
    _cachedDeliveryFee = null;
    _cachedRestaurantId = null;
    notifyListeners();
  }

  /// Get item by id
  CartItem? getItemById(String itemId) {
    try {
      return _cartItems.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Get total quantity of a product in cart (sums all variations/flavors)
  /// Returns 0 if product is not in cart
  int getProductQuantity(String? productId) {
    if (productId == null) return 0;
    return _cartItems.where((item) => item.productId == productId).fold(0, (sum, item) => sum + item.quantity);
  }

  /// Check if a product is in the cart
  bool isProductInCart(String? productId) {
    if (productId == null) return false;
    return _cartItems.any((item) => item.productId == productId);
  }
}
