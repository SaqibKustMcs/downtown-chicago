import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  created,
  sentToAdmin,
  assignedToRider,
  acceptedByRider,
  pickedUp,
  onTheWay,
  nearAddress, // I am near your address, hang tight
  atLocation, // I am at the location
  delivered,
  cancelled,
}

enum OrderType {
  delivery,
  takeaway,
}

class OrderModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? restaurantName;
  final String? adminId;
  final String? riderId;
  final String paymentMethod; // cash_on_delivery
  final OrderStatus status;
  final OrderType orderType; // delivery or takeaway
  final double totalAmount; // Total including delivery fee
  final double subtotal; // Subtotal before delivery fee
  final double deliveryFee; // Delivery fee amount (customer pays; admin keeps 100%)
  /// One-way distance restaurant → customer in km (for display).
  final double? deliveryDistanceKm;
  /// Round-trip distance (one-way × 2) in km; used for rider pay calculation.
  final double? riderTripKm;
  final String? deliveryAddress;
  final String? deliveryNote; // Note to rider, nearest landmark
  final String? addressTitle; // Address title (Home, Office, Work, etc.)
  final String? customerPhoneNumber; // Customer phone number for rider contact
  final Map<String, double>? customerLatLng; // {latitude, longitude}
  final List<Map<String, dynamic>> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt; // Timestamp when order was delivered
  final bool hasRiderReview;
  final bool hasProductReviews;
  final bool isModified; // Whether the order has been modified by admin
  final DateTime? modifiedAt; // Timestamp when order was modified
  final List<Map<String, dynamic>>? originalItems; // Original items before modification
  final String? modificationNote; // Note about the modification (e.g., "Product unavailable")
  final bool paymentCollected; // Whether payment has been collected from rider (for COD orders)
  final DateTime? paymentCollectedAt; // Timestamp when payment was collected

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.restaurantName,
    this.adminId,
    this.riderId,
    required this.paymentMethod,
    required this.status,
    this.orderType = OrderType.delivery, // Default to delivery
    required this.totalAmount,
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.deliveryDistanceKm,
    this.riderTripKm,
    this.deliveryAddress,
    this.deliveryNote,
    this.addressTitle,
    this.customerPhoneNumber,
    this.customerLatLng,
    required this.items,
    this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.hasRiderReview = false,
    this.hasProductReviews = false,
    this.isModified = false,
    this.modifiedAt,
    this.originalItems,
    this.modificationNote,
    this.paymentCollected = false,
    this.paymentCollectedAt,
  });

  static OrderStatus _parseStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'created':
        return OrderStatus.created;
      case 'sent_to_admin':
      case 'senttoadmin':
        return OrderStatus.sentToAdmin;
      case 'assigned_to_rider':
      case 'assignedtorider':
        return OrderStatus.assignedToRider;
      case 'accepted_by_rider':
      case 'acceptedbyrider':
        return OrderStatus.acceptedByRider;
      case 'picked_up':
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'on_the_way':
      case 'ontheway':
        return OrderStatus.onTheWay;
      case 'near_address':
      case 'nearaddress':
        return OrderStatus.nearAddress;
      case 'at_location':
      case 'atlocation':
        return OrderStatus.atLocation;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.created;
    }
  }

  static String statusToFirestore(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return 'created';
      case OrderStatus.sentToAdmin:
        return 'sent_to_admin';
      case OrderStatus.assignedToRider:
        return 'assigned_to_rider';
      case OrderStatus.acceptedByRider:
        return 'accepted_by_rider';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.nearAddress:
        return 'near_address';
      case OrderStatus.atLocation:
        return 'at_location';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static String? _parseOptionalString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static OrderType _parseOrderType(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'takeaway':
        return OrderType.takeaway;
      case 'delivery':
      default:
        return OrderType.delivery;
    }
  }

  static String orderTypeToFirestore(OrderType type) {
    switch (type) {
      case OrderType.takeaway:
        return 'takeaway';
      case OrderType.delivery:
        return 'delivery';
    }
  }

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    Map<String, double>? latLng;
    if (data['customerLatLng'] != null) {
      final latLngData = data['customerLatLng'] as Map;
      latLng = {
        'latitude': (latLngData['latitude'] ?? latLngData['lat'] ?? 0.0).toDouble(),
        'longitude': (latLngData['longitude'] ?? latLngData['lng'] ?? 0.0).toDouble(),
      };
    }

    final items = (data['items'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];

    return OrderModel(
      id: id,
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'],
      adminId: data['adminId'],
      riderId: data['riderId'],
      paymentMethod: data['paymentMethod'] ?? 'cash_on_delivery',
      status: _parseStatus(data['status']),
      orderType: _parseOrderType(data['orderType']), // Parse order type, default to delivery
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      subtotal: (data['subtotal'] ?? data['totalAmount'] ?? 0.0).toDouble(), // Fallback to totalAmount for backward compatibility
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      deliveryDistanceKm: (data['deliveryDistanceKm'] as num?)?.toDouble(),
      riderTripKm: (data['riderTripKm'] as num?)?.toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? data['address'],
      deliveryNote: _parseOptionalString(data['deliveryNote']),
      addressTitle: data['addressTitle'],
      customerPhoneNumber: data['customerPhoneNumber'],
      customerLatLng: latLng,
      items: items,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
      hasRiderReview: data['hasRiderReview'] ?? false,
      hasProductReviews: data['hasProductReviews'] ?? false,
      isModified: data['isModified'] ?? false,
      modifiedAt: data['modifiedAt'] != null ? (data['modifiedAt'] as Timestamp).toDate() : null,
      originalItems: data['originalItems'] != null
          ? (data['originalItems'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : null,
      modificationNote: data['modificationNote'] as String?,
      paymentCollected: data['paymentCollected'] ?? false,
      paymentCollectedAt: data['paymentCollectedAt'] != null ? (data['paymentCollectedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'restaurantId': restaurantId,
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (adminId != null) 'adminId': adminId,
      if (riderId != null) 'riderId': riderId,
      'paymentMethod': paymentMethod,
      'status': statusToFirestore(status),
      'orderType': orderTypeToFirestore(orderType), // Add order type
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      if (deliveryDistanceKm != null) 'deliveryDistanceKm': deliveryDistanceKm,
      if (riderTripKm != null) 'riderTripKm': riderTripKm,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (deliveryNote != null && deliveryNote!.isNotEmpty) 'deliveryNote': deliveryNote,
      if (addressTitle != null && addressTitle!.isNotEmpty) 'addressTitle': addressTitle,
      if (customerPhoneNumber != null && customerPhoneNumber!.isNotEmpty) 'customerPhoneNumber': customerPhoneNumber,
      if (customerLatLng != null) 'customerLatLng': customerLatLng,
      'items': items,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      'hasRiderReview': hasRiderReview,
      'hasProductReviews': hasProductReviews,
      'isModified': isModified,
      if (modifiedAt != null) 'modifiedAt': Timestamp.fromDate(modifiedAt!),
      if (originalItems != null) 'originalItems': originalItems,
      if (modificationNote != null && modificationNote!.isNotEmpty) 'modificationNote': modificationNote,
      'paymentCollected': paymentCollected,
      if (paymentCollectedAt != null) 'paymentCollectedAt': Timestamp.fromDate(paymentCollectedAt!),
    };
  }
}

