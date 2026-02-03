import 'package:flutter/foundation.dart';
import 'package:food_flow_app/core/base/base_controller.dart';
import 'package:food_flow_app/models/cart_item_model.dart';

class CartController extends BaseController {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _cartItems.isEmpty;

  /// Add item to cart
  /// If item with same id, variation, and flavor exists, increase quantity
  void addToCart(CartItem item) {
    // Check if item already exists with same variation and flavor
    final existingIndex = _cartItems.indexWhere((cartItem) =>
        cartItem.id == item.id &&
        cartItem.selectedVariation == item.selectedVariation &&
        cartItem.selectedFlavor == item.selectedFlavor);

    if (existingIndex != -1) {
      // Update quantity
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + item.quantity,
      );
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
}
