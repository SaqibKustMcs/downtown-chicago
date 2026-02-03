import 'package:flutter/material.dart';
import 'package:food_flow_app/core/widgets/animated_list_item.dart';
import 'package:food_flow_app/core/utils/tabler_icons_helper.dart';
import 'package:food_flow_app/modules/widgets/top_navigation_bar.dart';
import 'package:food_flow_app/styles/layouts/sizes.dart';
import 'package:food_flow_app/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });
}

enum NotificationType {
  order,
  promotion,
  general,
  system,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Order Confirmed',
      message: 'Your order #12345 has been confirmed and is being prepared.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.order,
    ),
    NotificationItem(
      id: '2',
      title: 'Special Offer',
      message: 'Get 20% off on all pizzas this weekend! Use code PIZZA20.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.promotion,
    ),
    NotificationItem(
      id: '3',
      title: 'Order Out for Delivery',
      message: 'Your order #12345 is out for delivery. Track it now!',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.order,
    ),
    NotificationItem(
      id: '4',
      title: 'Order Delivered',
      message: 'Your order #12340 has been delivered. Rate your experience!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.order,
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'New Restaurant Added',
      message: 'Check out our new partner restaurant - Sushi House!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.general,
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      title: 'App Update Available',
      message: 'A new version of Food Flow is available. Update now for better experience.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.system,
      isRead: true,
    ),
    NotificationItem(
      id: '7',
      title: 'Flash Sale',
      message: 'Limited time offer! 30% off on burgers. Valid for next 2 hours.',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      type: NotificationType.promotion,
      isRead: true,
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          timestamp: _notifications[index].timestamp,
          type: _notifications[index].type,
          isRead: true,
        );
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) {
        return NotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          timestamp: n.timestamp,
          type: n.type,
          isRead: true,
        );
      }).toList();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return TablerIconsHelper.receipt;
      case NotificationType.promotion:
        return TablerIconsHelper.bell;
      case NotificationType.general:
        return TablerIconsHelper.bell;
      case NotificationType.system:
        return TablerIconsHelper.settings;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return const Color(0xFFFF6B35);
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(
              title: 'Notifications',
              trailing: unreadCount > 0
                  ? TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Mark all read',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFFFF6B35),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),

            // Notifications List
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return AnimatedListItem(
                          index: index,
                          child: _buildNotificationItem(_notifications[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIconsHelper.bell,
            size: Sizes.s80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: Sizes.s24),
          Text(
            'No notifications',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s8),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: Sizes.s12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Sizes.s20),
        child: const Icon(
          TablerIconsHelper.trash,
          color: Colors.white,
          size: Sizes.s24,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Theme.of(context).cardColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: Sizes.s12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Theme.of(context).cardColor
                : Theme.of(context).cardColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(Sizes.s16),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? Colors.grey.shade700 : Colors.grey.shade200)
                  : iconColor.withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: Sizes.s8,
                offset: const Offset(0, Sizes.s2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: Sizes.s48,
                  height: Sizes.s48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Sizes.s12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: iconColor,
                    size: Sizes.s24,
                  ),
                ),
                const SizedBox(width: Sizes.s12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: Sizes.s8,
                              height: Sizes.s8,
                              decoration: BoxDecoration(
                                color: iconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Sizes.s4),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Sizes.s8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: AppTextStyles.captionTiny.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: Sizes.s10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
