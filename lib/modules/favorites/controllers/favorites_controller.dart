import 'package:flutter/foundation.dart';
import 'package:downtown/core/base/base_controller.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/models/food_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesController extends BaseController {
  final List<String> _favoriteProductIds = [];
  final Map<String, FoodItem> _favoriteProducts = {};

  List<String> get favoriteProductIds => List.unmodifiable(_favoriteProductIds);
  List<FoodItem> get favoriteProducts => _favoriteProducts.values.toList();
  bool get isEmpty => _favoriteProductIds.isEmpty;

  /// Check if a product is favorited
  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  /// Initialize favorites for current user
  Future<void> initialize(String userId) async {
    try {
      setLoading(true);
      clearError();

      final snapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      _favoriteProductIds.clear();
      _favoriteProducts.clear();

      for (var doc in snapshot.docs) {
        final productId = doc.id;
        _favoriteProductIds.add(productId);

        // Fetch product details
        final productDoc = await FirebaseService.firestore
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final product = FoodItem.fromFirestore(
            productDoc.data()!,
            productDoc.id,
          );
          _favoriteProducts[productId] = product;
        }
      }

      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      setError(e.toString());
      debugPrint('Error initializing favorites: $e');
    }
  }

  /// Add product to favorites
  Future<bool> addToFavorites(String userId, FoodItem product) async {
    try {
      if (_favoriteProductIds.contains(product.id)) {
        return true; // Already favorited
      }

      // Add to Firestore
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(product.id ?? '')
          .set({
        'productId': product.id,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      _favoriteProductIds.add(product.id ?? '');
      _favoriteProducts[product.id ?? ''] = product;

      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      debugPrint('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove product from favorites
  Future<bool> removeFromFavorites(String userId, String productId) async {
    try {
      if (!_favoriteProductIds.contains(productId)) {
        return true; // Already removed
      }

      // Remove from Firestore
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();

      // Update local state
      _favoriteProductIds.remove(productId);
      _favoriteProducts.remove(productId);

      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      debugPrint('Error removing from favorites: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String userId, FoodItem product) async {
    if (isFavorite(product.id ?? '')) {
      return await removeFromFavorites(userId, product.id ?? '');
    } else {
      return await addToFavorites(userId, product);
    }
  }

  /// Clear all favorites (for logout)
  void clearFavorites() {
    _favoriteProductIds.clear();
    _favoriteProducts.clear();
    notifyListeners();
  }
}
