import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderCreated,
  orderAssigned,
  orderAccepted,
  orderStatusUpdate,
  orderUpdated, // Order items modified by admin
  orderCancelled,
  promotion,
  general,
  system,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseType(data['type']),
      orderId: data['orderId'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  static NotificationType _parseType(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'order_created':
        return NotificationType.orderCreated;
      case 'order_assigned':
        return NotificationType.orderAssigned;
      case 'order_accepted':
        return NotificationType.orderAccepted;
      case 'order_status_update':
        return NotificationType.orderStatusUpdate;
      case 'order_updated':
        return NotificationType.orderUpdated;
      case 'order_cancelled':
        return NotificationType.orderCancelled;
      case 'promotion':
        return NotificationType.promotion;
      case 'general':
        return NotificationType.general;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.general;
    }
  }

  static String typeToFirestore(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
        return 'order_created';
      case NotificationType.orderAssigned:
        return 'order_assigned';
      case NotificationType.orderAccepted:
        return 'order_accepted';
      case NotificationType.orderStatusUpdate:
        return 'order_status_update';
      case NotificationType.orderUpdated:
        return 'order_updated';
      case NotificationType.orderCancelled:
        return 'order_cancelled';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.general:
        return 'general';
      case NotificationType.system:
        return 'system';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': typeToFirestore(type),
      if (orderId != null) 'orderId': orderId,
      'isRead': isRead,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
