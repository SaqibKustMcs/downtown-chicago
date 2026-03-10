import 'dart:async';
import 'dart:math' show Random;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/utils/delivery_fee_util.dart';
import 'package:downtown/models/cart_item_model.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/notifications/models/notification_model.dart';
import 'package:downtown/modules/notifications/services/notification_service.dart';
import 'package:downtown/modules/admin/services/admin_settings_service.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/rider/services/rider_location_service.dart';
import 'package:downtown/modules/location/services/address_service.dart';

class OrderService {
  OrderService._();

  static Future<String> createCashOnDeliveryOrder({
    required UserModel customer,
    required List<CartItem> cartItems,
    required double totalAmount,
    OrderType orderType = OrderType.delivery, // Default to delivery
    String? deliveryAddress,
    String? deliveryNote,
    String? addressTitle,
    double? latitude,
    double? longitude,
    String? phoneNumber,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final restaurantIds = cartItems.map((e) => e.restaurantId).whereType<String>().toSet();
    if (restaurantIds.isEmpty) {
      throw Exception('Restaurant information missing in cart');
    }
    if (restaurantIds.length > 1) {
      throw Exception('Please place an order from one restaurant at a time');
    }

    final restaurantId = restaurantIds.first;

    // Fetch restaurant to get adminId, name, location, and delivery fee (distance-based or fixed)
    String? adminId;
    String? restaurantName;
    double deliveryFee = 0.0;
    double? deliveryDistanceKm;
    double? riderTripKm;
    try {
      final restaurantDoc = await FirebaseService.firestore.collection('restaurants').doc(restaurantId).get();
      final data = restaurantDoc.data();
      if (data != null) {
        adminId = data['adminId'] as String?;
        restaurantName = data['name'] as String?;
        final fallbackFee = (data['deliveryFee'] ?? 0.0).toDouble();
        double pricePerKm = (data['deliveryPricePerKm'] as num?)?.toDouble() ?? 0.0;
        if (pricePerKm <= 0) {
          final appSettings = await AdminSettingsService.instance.getSettings();
          pricePerKm = ((appSettings['defaultDeliveryPricePerKm'] ?? 5.0) as num).toDouble();
        }

        Map<String, double>? restLoc;
        if (data['location'] != null) {
          final locData = data['location'] as Map;
          restLoc = {
            'latitude': (locData['latitude'] ?? locData['lat'] ?? 0.0).toDouble(),
            'longitude': (locData['longitude'] ?? locData['lng'] ?? 0.0).toDouble(),
          };
        }

        double? custLat = latitude;
        double? custLng = longitude;
        if (custLat == null || custLng == null) {
          final ul = customer.userLatLng;
          if (ul != null) {
            custLat = ul['latitude'];
            custLng = ul['longitude'];
          }
        }

        deliveryFee = DeliveryFeeUtil.calculate(
          restaurantLat: restLoc?['latitude'],
          restaurantLon: restLoc?['longitude'],
          customerLat: custLat,
          customerLon: custLng,
          pricePerKm: pricePerKm,
          fallbackFee: fallbackFee,
        );
        // One-way km (restaurant → customer) and round-trip km for rider pay
        if (restLoc != null && custLat != null && custLng != null) {
          final oneWayKm = DeliveryFeeUtil.distanceKm(
            lat1: restLoc['latitude']!,
            lon1: restLoc['longitude']!,
            lat2: custLat,
            lon2: custLng,
          );
          deliveryDistanceKm = oneWayKm;
          riderTripKm = oneWayKm * 2;
        }
        debugPrint('✅ Restaurant fetched - adminId: $adminId, name: $restaurantName');
        
        // Verify admin user exists and has correct userType
        if (adminId != null && adminId.isNotEmpty) {
          try {
            final adminDoc = await FirebaseService.firestore.collection('users').doc(adminId).get();
            if (adminDoc.exists) {
              final adminData = adminDoc.data();
              final adminUserType = adminData?['userType'] as String?;
              debugPrint('✅ Admin user found - userType: $adminUserType');
              
              if (adminUserType != 'admin') {
                debugPrint('⚠️ WARNING: Admin user has incorrect userType: $adminUserType (expected: admin)');
                debugPrint('   This may cause notification issues. Please update userType to "admin" in Firestore.');
              }
            } else {
              debugPrint('❌ ERROR: Admin user document not found: $adminId');
            }
          } catch (e) {
            debugPrint('❌ Error verifying admin user: $e');
          }
        }
      } else {
        debugPrint('⚠️ Restaurant document not found: $restaurantId');
      }
    } catch (e) {
      debugPrint('❌ Error fetching restaurant: $e');
    }
    
    if (adminId == null || adminId.isEmpty) {
      debugPrint('⚠️ WARNING: adminId is null or empty for restaurant: $restaurantId');
      debugPrint('   Please ensure restaurant document has "adminId" field set correctly.');
    }

    // Calculate subtotal (sum of all cart items)
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    // For takeaway orders, delivery fee is 0
    final finalDeliveryFee = orderType == OrderType.takeaway ? 0.0 : deliveryFee;
    
    // Calculate total amount (subtotal + delivery fee)
    final calculatedTotalAmount = subtotal + finalDeliveryFee;

    final items = cartItems.map((item) {
      return <String, dynamic>{
        'productId': item.productId ?? item.id,
        'name': item.name,
        'imageUrl': item.imageUrl,
        'quantity': item.quantity,
        'unitPrice': item.price,
        'basePrice': item.basePrice,
        'selectedVariation': item.selectedVariation,
        'selectedFlavor': item.selectedFlavor,
        'restaurantId': item.restaurantId,
        'restaurantName': item.restaurantName,
      };
    }).toList();

    // For takeaway orders, skip address-related fields
    String? finalDeliveryAddress;
    Map<String, double>? finalLatLng;
    String? finalPhoneNumber;
    
    if (orderType == OrderType.takeaway) {
      // Takeaway orders don't need delivery address, coordinates, or phone number
      finalDeliveryAddress = null;
      finalLatLng = null;
      finalPhoneNumber = null;
    } else {
      // Use provided delivery address, or fall back to customer's saved address
      finalDeliveryAddress = deliveryAddress ?? customer.address;
      
      // Use provided coordinates or customer's saved coordinates
      if (latitude != null && longitude != null) {
        finalLatLng = {'latitude': latitude, 'longitude': longitude};
      } else if (customer.userLatLng != null) {
        finalLatLng = customer.userLatLng;
      }
      
      // Use provided phone number or customer's saved phone number
      finalPhoneNumber = phoneNumber ?? customer.phoneNumber;
    }

    final orderData = <String, dynamic>{
      'customerId': customer.id,
      'restaurantId': restaurantId,
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (adminId != null) 'adminId': adminId,
      'riderId': null,
      'paymentMethod': 'cash_on_delivery',
      'status': OrderModel.statusToFirestore(OrderStatus.created),
      'orderType': OrderModel.orderTypeToFirestore(orderType), // Add order type
      'totalAmount': calculatedTotalAmount, // Use calculated total (subtotal + deliveryFee)
      'subtotal': subtotal,
      'deliveryFee': finalDeliveryFee, // Use final delivery fee (0 for takeaway)
      if (deliveryDistanceKm != null && orderType == OrderType.delivery) 'deliveryDistanceKm': deliveryDistanceKm,
      if (riderTripKm != null && orderType == OrderType.delivery) 'riderTripKm': riderTripKm,
      if (finalDeliveryAddress != null && finalDeliveryAddress.isNotEmpty) 'deliveryAddress': finalDeliveryAddress,
      if (deliveryNote != null && deliveryNote.isNotEmpty && orderType == OrderType.delivery) 'deliveryNote': deliveryNote,
      if (addressTitle != null && addressTitle.isNotEmpty && orderType == OrderType.delivery) 'addressTitle': addressTitle,
      if (finalLatLng != null) 'customerLatLng': finalLatLng,
      if (finalPhoneNumber != null && finalPhoneNumber.isNotEmpty) 'customerPhoneNumber': finalPhoneNumber,
      'items': items,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Generate a unique numeric order ID (timestamp + random suffix to avoid collisions)
    final numericOrderId = _generateNumericOrderId();

    await FirebaseService.firestore.collection('orders').doc(numericOrderId).set(orderData);

    // Save address with note and title to addresses collection AFTER order is placed (only for delivery orders)
    if (orderType == OrderType.delivery && finalDeliveryAddress != null && finalDeliveryAddress.isNotEmpty && finalLatLng != null) {
      try {
        // Check if address with same coordinates already exists
        final existingAddressesStream = AddressService.getUserAddresses(customer.id);
        final existingAddresses = await existingAddressesStream.first;
        final addressExists = existingAddresses.any((addr) =>
            addr.address == finalDeliveryAddress &&
            addr.latitude != null &&
            addr.longitude != null &&
            (addr.latitude! - finalLatLng!['latitude']!).abs() < 0.0001 &&
            (addr.longitude! - finalLatLng!['longitude']!).abs() < 0.0001);

        if (!addressExists) {
          // Save new address with note and title
          await AddressService.addAddress(
            userId: customer.id,
            address: finalDeliveryAddress,
            label: addressTitle,
            note: deliveryNote,
            latitude: finalLatLng['latitude'],
            longitude: finalLatLng['longitude'],
            setAsDefault: true, // Set as default since it's used for order
          );
          debugPrint('Saved address with note and title after order placement');
        } else {
          debugPrint('Address already exists, skipping save');
        }
      } catch (e) {
        debugPrint('Error saving address after order: $e');
        // Don't fail the order creation if address save fails
      }
    }

    // Save delivery address and phone number to user's profile if provided (only for delivery orders)
    if (orderType == OrderType.delivery && (finalDeliveryAddress != null && finalDeliveryAddress.isNotEmpty || finalPhoneNumber != null)) {
      try {
        final updateData = <String, dynamic>{};
        
        // Update address if provided and different
        if (finalDeliveryAddress != null && finalDeliveryAddress.isNotEmpty) {
          final currentAddress = customer.address?.trim() ?? '';
          final newAddress = finalDeliveryAddress.trim();
          
          if (currentAddress != newAddress) {
            updateData['address'] = newAddress;
            debugPrint('Updating user address from "$currentAddress" to "$newAddress"');
          }
        }
        
        // Update phone number if provided and different
        if (finalPhoneNumber != null && finalPhoneNumber.isNotEmpty) {
          final currentPhone = customer.phoneNumber?.trim() ?? '';
          final newPhone = finalPhoneNumber.trim();
          
          if (currentPhone != newPhone) {
            updateData['phoneNumber'] = newPhone;
            debugPrint('Updating user phone number from "$currentPhone" to "$newPhone"');
          }
        }
        
        // Update coordinates if provided
        if (finalLatLng != null) {
          updateData['userLatLng'] = finalLatLng;
        }
        
        if (updateData.isNotEmpty) {
          updateData['updatedAt'] = FieldValue.serverTimestamp();
          await FirebaseService.firestore.collection('users').doc(customer.id).update(updateData);
          
          // Refresh user data in AuthController
          try {
            final authController = DependencyInjection.instance.authController;
            await authController.refreshUser();
            debugPrint('User data refreshed successfully');
          } catch (e) {
            debugPrint('Error refreshing user data: $e');
            // Don't fail if refresh fails
          }
        } else {
          debugPrint('No user data changes, skipping update');
        }
      } catch (e) {
        debugPrint('Error updating user data: $e');
        // Don't fail the order creation if user update fails
      }
    }

    // Create notification for admin
    if (adminId != null && adminId.isNotEmpty) {
      final orderTypeText = orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery';
      debugPrint('📤 Sending notification to admin: $adminId');
      debugPrint('   Order ID: $numericOrderId');
      debugPrint('   Order Type: $orderTypeText');
      debugPrint('   Customer: ${customer.name ?? customer.email}');
      
      try {
        final notificationResult = await NotificationService.notifyUser(
          userId: adminId,
          title: 'New $orderTypeText order received',
          body: 'Order from ${customer.name ?? customer.email}',
          type: NotificationType.orderCreated,
          orderId: numericOrderId,
        );
        
        if (notificationResult) {
          debugPrint('✅ Admin notification sent successfully');
        } else {
          debugPrint('⚠️ Admin notification returned false');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error notifying admin: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('⚠️ Skipping admin notification - adminId is null or empty');
    }

    // Create notification for customer
    NotificationService.notifyUser(
      userId: customer.id,
      title: 'Order placed successfully',
      body: 'Your order #$numericOrderId has been placed',
      type: NotificationType.orderCreated,
      orderId: numericOrderId,
    ).catchError((e) {
      debugPrint('Error notifying customer: $e'); return false; });

    return numericOrderId;
  }

  /// Generates a unique numeric order ID: 13 digits (millis) + 3 random digits = 16 digits.
  static String _generateNumericOrderId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final suffix = Random().nextInt(1000).toString().padLeft(3, '0');
    return '$millis$suffix';
  }

  /// Get orders for a customer
  static Stream<List<OrderModel>> getCustomerOrders(String customerId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error fetching customer orders: $error');
      // Re-throw to be handled by StreamBuilder
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            } catch (e) {
              debugPrint('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    });
  }

  /// Get a single order by ID
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get order stream by ID
  static Stream<OrderModel?> getOrderStream(String orderId) {
    return FirebaseService.firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  /// Cancel an order (customer can cancel if status is created/sentToAdmin and within 30 seconds of creation)
  static Future<bool> cancelOrder(String orderId, String customerId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;
      if (order.customerId != customerId) return false;
      if (order.status != OrderStatus.created &&
          order.status != OrderStatus.sentToAdmin) {
        return false; // Cannot cancel at this stage
      }
      // Only allow cancel within 30 seconds of order creation
      if (order.createdAt == null ||
          DateTime.now().difference(order.createdAt!) > const Duration(seconds: 30)) {
        return false;
      }

      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'status': OrderModel.statusToFirestore(OrderStatus.cancelled),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify admin
      if (order.adminId != null) {
        NotificationService.notifyUser(
          userId: order.adminId!,
          title: 'Order cancelled',
          body: 'Order #${orderId.substring(0, 8).toUpperCase()} has been cancelled',
          type: NotificationType.orderCancelled,
          orderId: orderId,
        ).catchError((e) {
      debugPrint('Error notifying admin: $e'); return false; });
      }

      // Notify rider if assigned
      if (order.riderId != null) {
        NotificationService.notifyUser(
          userId: order.riderId!,
          title: 'Order cancelled',
          body: 'Order #${orderId.substring(0, 8).toUpperCase()} has been cancelled',
          type: NotificationType.orderCancelled,
          orderId: orderId,
        ).catchError((e) {
      debugPrint('Error notifying rider: $e'); return false; });
        // Update rider availability and stop location updates
        FirebaseService.firestore.collection('users').doc(order.riderId).update({
          'isAvailable': true,
          'activeOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((e) {
          debugPrint('Error updating rider availability: $e');
        });

        // Stop location updates if order was cancelled and rider had active order
        RiderLocationService.instance.stopLocationUpdates();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get orders for an admin (by adminId)
  static Stream<List<OrderModel>> getAdminOrders(String adminId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error fetching admin orders: $error');
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            } catch (e) {
              debugPrint('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    });
  }

  /// Get orders for a restaurant (by restaurantId)
  static Stream<List<OrderModel>> getRestaurantOrders(String restaurantId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error fetching restaurant orders: $error');
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            } catch (e) {
              debugPrint('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    });
  }

  /// Update order status (admin/rider can update)
  /// Requires userId and userType for authorization checks
  static Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    required String userId,
    required String userType, // 'admin', 'rider', or 'customer'
  }) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      // Authorization checks
      if (userType == 'admin') {
        // Admin can only update orders they manage
        if (order.adminId != userId) {
          debugPrint('Unauthorized: Admin $userId cannot update order ${order.id} (adminId: ${order.adminId})');
          return false;
        }
        // Admin can only change: created/sentToAdmin → assignedToRider, or cancel orders
        final isFromCreatedOrSentToAdmin = order.status == OrderStatus.created || order.status == OrderStatus.sentToAdmin;
        final isAssigningToRider = newStatus == OrderStatus.assignedToRider;
        final isCancelling = newStatus == OrderStatus.cancelled;
        
        if (!isCancelling && !(isFromCreatedOrSentToAdmin && isAssigningToRider)) {
          debugPrint('Unauthorized: Admin cannot change status from ${order.status} to $newStatus');
          return false;
        }
      } else if (userType == 'rider') {
        // Rider can only update orders assigned to them
        if (order.riderId != userId) {
          debugPrint('Unauthorized: Rider $userId cannot update order ${order.id} (riderId: ${order.riderId})');
          return false;
        }
        // Rider can only change statuses through progressive flow
        final allowedRiderTransitions = {
          OrderStatus.assignedToRider: [OrderStatus.acceptedByRider],
          OrderStatus.acceptedByRider: [OrderStatus.pickedUp],
          OrderStatus.pickedUp: [OrderStatus.onTheWay],
          OrderStatus.onTheWay: [OrderStatus.nearAddress],
          OrderStatus.nearAddress: [OrderStatus.atLocation],
          OrderStatus.atLocation: [OrderStatus.delivered],
        };
        final allowedNextStatuses = allowedRiderTransitions[order.status] ?? [];
        if (!allowedNextStatuses.contains(newStatus)) {
          debugPrint('Unauthorized: Rider cannot change status from ${order.status} to $newStatus');
          return false;
        }
      } else {
        // Customer cannot update order status
        debugPrint('Unauthorized: Customer cannot update order status');
        return false;
      }

      final updateData = <String, dynamic>{
        'status': OrderModel.statusToFirestore(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Set deliveredAt timestamp when order is delivered
      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
        
        // For Cash on Delivery orders, paymentCollected remains false until admin collects it
        // For online payments, payment is automatically collected
        if (order.paymentMethod != 'cash_on_delivery') {
          updateData['paymentCollected'] = true;
        }
      }

      await FirebaseService.firestore.collection('orders').doc(orderId).update(updateData);

      // Notify customer of status update
      String title;
      String body;
      switch (newStatus) {
        case OrderStatus.pickedUp:
          title = 'Order picked up';
          body = 'Your rider has picked up your order';
          break;
        case OrderStatus.onTheWay:
          title = 'Order on the way';
          body = 'Your order is on the way to you';
          break;
        case OrderStatus.nearAddress:
          title = 'Rider is near your address';
          body = 'Your rider is near your address. Hang tight!';
          break;
        case OrderStatus.atLocation:
          title = 'Rider has arrived';
          body = 'Your rider has arrived at your location';
          break;
        case OrderStatus.delivered:
          title = 'Order delivered';
          body = 'Your order has been delivered. Enjoy your meal!';
          // Rider is available for new order as soon as they deliver (for all payment types)
          if (order.riderId != null) {
            FirebaseService.firestore.collection('users').doc(order.riderId).update({
              'isAvailable': true,
              'activeOrderId': null,
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((e) {
              debugPrint('Error updating rider availability: $e');
            });
            RiderLocationService.instance.stopLocationUpdates();
          }
          break;
        default:
          title = 'Order status updated';
          body = 'Your order status has been updated';
      }

      NotificationService.notifyUser(
        userId: order.customerId,
        title: title,
        body: body,
        type: NotificationType.orderStatusUpdate,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error notifying customer: $e'); return false; });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Assign rider to order (admin only)
  static Future<bool> assignRiderToOrder(String orderId, String riderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'status': OrderModel.statusToFirestore(OrderStatus.assignedToRider),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Build notification body with order details
      final orderShortId = orderId.substring(0, 8).toUpperCase();
      final restaurantName = order.restaurantName ?? 'Restaurant';
      final deliveryAddress = order.deliveryAddress ?? 'Address not provided';
      final orderAmount = order.totalAmount.toStringAsFixed(2);
      
      final notificationBody = 'Order #$orderShortId from $restaurantName\n'
          'Amount: Rs. $orderAmount\n'
          'Delivery: $deliveryAddress';

      // Notify rider with detailed information
      NotificationService.notifyUser(
        userId: riderId,
        title: 'New order assignment',
        body: notificationBody,
        type: NotificationType.orderAssigned,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error notifying rider: $e'); return false; });

      // Notify customer
      NotificationService.notifyUser(
        userId: order.customerId,
        title: 'Rider assigned',
        body: 'A rider has been assigned to your order',
        type: NotificationType.orderStatusUpdate,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error notifying customer: $e'); return false; });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Complete/deliver an order
  static Future<bool> completeOrder(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      // Allow completion if order is onTheWay or atLocation (new flow)
      if (order.status != OrderStatus.onTheWay && order.status != OrderStatus.atLocation) {
        debugPrint('Order cannot be completed. Current status: ${order.status}');
        return false;
      }

      // For Cash on Delivery orders, don't mark payment as collected yet
      // Rider needs to handover cash to restaurant first
      final isCashOnDelivery = order.paymentMethod == 'cash_on_delivery';
      
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'status': OrderModel.statusToFirestore(OrderStatus.delivered),
        'updatedAt': FieldValue.serverTimestamp(),
        'deliveredAt': FieldValue.serverTimestamp(),
        // For COD orders, paymentCollected remains false until admin collects it
        if (!isCashOnDelivery) 'paymentCollected': true, // Online payments are automatically collected
      });

      // Rider is available for new order as soon as they deliver (not when payment is submitted to restaurant)
      if (order.riderId != null) {
        await FirebaseService.firestore.collection('users').doc(order.riderId).update({
          'isAvailable': true,
          'activeOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((e) {
          debugPrint('Error updating rider availability: $e');
        });
        RiderLocationService.instance.stopLocationUpdates();
      }

      // Build notification body with order details
      final orderShortId = orderId.substring(0, 8).toUpperCase();
      final restaurantName = order.restaurantName ?? 'Restaurant';
      
      // Notify customer with detailed information
      NotificationService.notifyUser(
        userId: order.customerId,
        title: 'Order delivered! 🎉',
        body: 'Your order #$orderShortId from $restaurantName has been delivered successfully. '
            'Enjoy your meal!',
        type: NotificationType.orderStatusUpdate,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error notifying customer: $e'); return false; });

      // Send review prompt notification to customer
      // This is sent separately to encourage reviews
      final reviewPromptBody = order.riderId != null
          ? 'Help us improve! Please rate your rider and the products from your order #$orderShortId.'
          : 'Help us improve! Please rate the products from your order #$orderShortId.';
      
      NotificationService.notifyUser(
        userId: order.customerId,
        title: 'Rate your experience ⭐',
        body: reviewPromptBody,
        type: NotificationType.general,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error sending review prompt notification: $e'); return false; });

      // Notify admin
      if (order.adminId != null) {
        NotificationService.notifyUser(
          userId: order.adminId!,
          title: 'Order delivered',
          body: 'Order #${orderId.substring(0, 8).toUpperCase()} has been delivered',
          type: NotificationType.orderStatusUpdate,
          orderId: orderId,
        ).catchError((e) {
      debugPrint('Error notifying admin: $e'); return false; });
      }

      return true;
    } catch (e) {
      debugPrint('Error completing order: $e');
      return false;
    }
  }

  /// Collect payment from rider (admin only) - for Cash on Delivery orders
  static Future<bool> collectPaymentFromRider({
    required String orderId,
    required String adminId,
  }) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      // Only allow payment collection for COD orders that are delivered but payment not collected
      if (order.paymentMethod != 'cash_on_delivery') {
        throw Exception('Payment collection is only for Cash on Delivery orders');
      }

      if (order.status != OrderStatus.delivered) {
        throw Exception('Order must be delivered before collecting payment');
      }

      if (order.paymentCollected) {
        throw Exception('Payment has already been collected for this order');
      }

      // Mark payment as collected (rider was already made available when order was delivered)
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'paymentCollected': true,
        'paymentCollectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify rider that payment has been collected
      if (order.riderId != null) {
        NotificationService.notifyUser(
          userId: order.riderId!,
          title: 'Payment Collected',
          body: 'Payment for order #${orderId.substring(0, 8).toUpperCase()} has been collected by the restaurant.',
          type: NotificationType.orderStatusUpdate,
          orderId: orderId,
        ).catchError((e) {
      debugPrint('Error notifying rider: $e'); return false; });
      }

      return true;
    } catch (e) {
      debugPrint('Error collecting payment from rider: $e');
      rethrow;
    }
  }

  /// Get orders assigned to a rider
  static Stream<List<OrderModel>> getRiderOrders(String riderId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error fetching rider orders: $error');
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            } catch (e) {
              debugPrint('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    });
  }

  /// Get orders assigned to rider but not yet accepted
  static Stream<List<OrderModel>> getRiderPendingOrders(String riderId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: OrderModel.statusToFirestore(OrderStatus.assignedToRider))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error fetching rider pending orders: $error');
      throw error;
    })
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            } catch (e) {
              debugPrint('Error parsing order ${doc.id}: $e');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    });
  }

  /// Accept order by rider
  static Future<bool> acceptOrderByRider(String orderId, String riderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null || order.riderId != riderId) return false;
      if (order.status != OrderStatus.assignedToRider) return false;

      // Update order status
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'status': OrderModel.statusToFirestore(OrderStatus.acceptedByRider),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update rider's activeOrderId and isAvailable
      await FirebaseService.firestore.collection('users').doc(riderId).update({
        'activeOrderId': orderId,
        'isAvailable': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify admin
      if (order.adminId != null) {
        NotificationService.notifyUser(
          userId: order.adminId!,
          title: 'Order accepted',
          body: 'Rider accepted order #${orderId.substring(0, 8).toUpperCase()}',
          type: NotificationType.orderAccepted,
          orderId: orderId,
        ).catchError((e) {
      debugPrint('Error notifying admin: $e'); return false; });
      }

      // Notify customer
      NotificationService.notifyUser(
        userId: order.customerId,
        title: 'Order accepted',
        body: 'Your rider has accepted the order and will pick it up soon',
        type: NotificationType.orderStatusUpdate,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error notifying customer: $e'); return false; });

      // Start location updates for rider (updates every 30 seconds)
      RiderLocationService.instance.startLocationUpdates(riderId).catchError((e) {
        debugPrint('Error starting location updates for rider: $e');
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Decline order by rider
  static Future<bool> declineOrderByRider(String orderId, String riderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null || order.riderId != riderId) return false;
      if (order.status != OrderStatus.assignedToRider) return false;

      // Remove rider from order
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'riderId': null,
        'status': OrderModel.statusToFirestore(OrderStatus.created),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update order items (admin only) - for removing unavailable products
  static Future<bool> updateOrderItems({
    required String orderId,
    required List<Map<String, dynamic>> updatedItems,
    String? modificationNote,
  }) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      // Don't allow modification if order is already delivered or cancelled
      if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
        throw Exception('Cannot modify a delivered or cancelled order');
      }

      // Calculate new subtotal
      final newSubtotal = updatedItems.fold(0.0, (sum, item) {
        final quantity = (item['quantity'] as int? ?? 0);
        final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
        return sum + (quantity * unitPrice);
      });

      // Calculate new total (subtotal + delivery fee)
      final newTotal = newSubtotal + order.deliveryFee;

      // Get original items if not already stored
      final originalItems = order.originalItems ?? order.items;

      // Update order in Firestore
      await FirebaseService.firestore.collection('orders').doc(orderId).update({
        'items': updatedItems,
        'subtotal': newSubtotal,
        'totalAmount': newTotal,
        'isModified': true,
        'modifiedAt': FieldValue.serverTimestamp(),
        if (order.originalItems == null) 'originalItems': originalItems, // Store original items only once
        if (modificationNote != null && modificationNote.isNotEmpty) 'modificationNote': modificationNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify customer about order modification
      await NotificationService.notifyUser(
        userId: order.customerId,
        title: 'Order Updated',
        body: modificationNote ?? 'Some items in your order have been modified. Please check your order details.',
        type: NotificationType.orderUpdated,
        orderId: orderId,
      ).catchError((e) {
      debugPrint('Error notifying customer about order modification: $e'); return false; });

      return true;
    } catch (e) {
      debugPrint('Error updating order items: $e');
      rethrow;
    }
  }
}

