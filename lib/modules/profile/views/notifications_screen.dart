import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/notifications/models/notification_model.dart';
import 'package:downtown/modules/notifications/services/notification_service.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _authController = DependencyInjection.instance.authController;

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: Text('Please login to view notifications'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<NotificationModel>>(
          stream: NotificationService.getUserNotifications(currentUser.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  TopNavigationBar(
                    title: 'Notifications',
                    showBackButton: true,
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: Sizes.s48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: Sizes.s16),
                          Text(
                            'Error loading notifications',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final notifications = snapshot.data ?? [];
            final unreadCount = notifications.where((n) => !n.isRead).length;

            return Column(
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
                  showBackButton: true,
                ),

                // Notifications List
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sizes.s12,
                            vertical: Sizes.s16,
                          ),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return AnimatedListItem(
                              index: index,
                              child: _buildNotificationItem(notifications[index]),
                            );
                          },
                        ),
                ),
              ],
            );
          },
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

  Widget _buildNotificationItem(NotificationModel notification) {
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
            content: const Text('Notification deleted'),
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
          // Navigate to order detail if it's an order notification
          if (notification.orderId != null) {
            Navigator.pushNamed(
              context,
              Routes.trackOrder,
              arguments: notification.orderId,
            );
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
                        notification.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification.createdAt != null) ...[
                        const SizedBox(height: Sizes.s8),
                        Text(
                          _formatTimestamp(notification.createdAt!),
                          style: AppTextStyles.captionTiny.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                            fontSize: Sizes.s10,
                          ),
                        ),
                      ],
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

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
      case NotificationType.orderAssigned:
      case NotificationType.orderAccepted:
      case NotificationType.orderStatusUpdate:
      case NotificationType.orderUpdated:
      case NotificationType.orderCancelled:
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
      case NotificationType.orderCreated:
      case NotificationType.orderAssigned:
      case NotificationType.orderAccepted:
      case NotificationType.orderStatusUpdate:
      case NotificationType.orderUpdated:
      case NotificationType.orderCancelled:
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

  Future<void> _markAsRead(String notificationId) async {
    final currentUser = _authController.currentUser;
    if (currentUser == null) return;

    await NotificationService.markAsRead(currentUser.id, notificationId);
  }

  Future<void> _markAllAsRead() async {
    final currentUser = _authController.currentUser;
    if (currentUser == null) return;

    await NotificationService.markAllAsRead(currentUser.id);
  }

  Future<void> _deleteNotification(String notificationId) async {
    final currentUser = _authController.currentUser;
    if (currentUser == null) return;

    await NotificationService.deleteNotification(currentUser.id, notificationId);
  }
}
