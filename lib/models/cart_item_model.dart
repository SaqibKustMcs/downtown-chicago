class CartItem {
  final String id; // Product ID from Firestore
  final String name;
  final String imageUrl;
  final double price; // Final price including variation and flavor
  final String size; // Variation name or "Regular"
  final int quantity;
  final String? selectedVariation; // e.g., "Medium"
  final String? selectedFlavor; // e.g., "Spicy"
  final String? productId; // Firestore product document ID
  final String? restaurantId; // Restaurant ID
  final String? restaurantName; // Restaurant name
  final double basePrice; // Base price before variations/flavors

  const CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.size,
    required this.quantity,
    this.selectedVariation,
    this.selectedFlavor,
    this.productId,
    this.restaurantId,
    this.restaurantName,
    this.basePrice = 0.0,
  });

  CartItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    String? size,
    int? quantity,
    String? selectedVariation,
    String? selectedFlavor,
    String? productId,
    String? restaurantId,
    String? restaurantName,
    double? basePrice,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      selectedVariation: selectedVariation ?? this.selectedVariation,
      selectedFlavor: selectedFlavor ?? this.selectedFlavor,
      productId: productId ?? this.productId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      basePrice: basePrice ?? this.basePrice,
    );
  }

  double get totalPrice => price * quantity;
}
