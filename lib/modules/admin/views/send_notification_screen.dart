import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/services/push_notification_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/notifications/models/notification_model.dart';
import 'package:downtown/modules/notifications/services/notification_service.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  NotificationTarget _selectedTarget = NotificationTarget.all;
  bool _isSending = false;
  int _recipientCount = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            TopNavigationBar(title: 'Send Notification', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Target Selection
                      _buildTargetSelection(),
                      const SizedBox(height: Sizes.s24),

                      // Recipient Count
                      if (_recipientCount > 0)
                        Container(
                          padding: const EdgeInsets.all(Sizes.s12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Sizes.s12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, color: Theme.of(context).colorScheme.primary, size: Sizes.s20),
                              const SizedBox(width: Sizes.s8),
                              Text(
                                'Recipients: $_recipientCount',
                                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: Sizes.s24),

                      // Title Field
                      Text(
                        'Title',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: Sizes.s8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter notification title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                          prefixIcon: Icon(TablerIconsHelper.edit, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),
                      const SizedBox(height: Sizes.s24),

                      // Message Field
                      Text(
                        'Message',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: Sizes.s8),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter notification message',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                          prefixIcon: Icon(TablerIconsHelper.bell, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                        maxLines: 5,
                        maxLength: 500,
                      ),
                      const SizedBox(height: Sizes.s32),

                      // Send Button
                      SizedBox(
                        height: Sizes.s56,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _handleSendNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
                            elevation: 0,
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: Sizes.s20,
                                  height: Sizes.s20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(TablerIconsHelper.bell, color: Colors.white, size: Sizes.s20),
                                    const SizedBox(width: Sizes.s8),
                                    Text('Send Notification', style: AppTextStyles.buttonLargeBold.copyWith(color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: Sizes.s8),
        DropdownButtonFormField<NotificationTarget>(
          value: _selectedTarget,
          decoration: InputDecoration(
            hintText: 'Select target audience',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(Sizes.s12)),
            prefixIcon: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s16),
          ),
          items: [
            DropdownMenuItem(
              value: NotificationTarget.all,
              child: Row(
                children: [
                  Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: Sizes.s20),
                  const SizedBox(width: Sizes.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('All Users', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Send to all riders and customers', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: NotificationTarget.riders,
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: Theme.of(context).colorScheme.primary, size: Sizes.s20),
                  const SizedBox(width: Sizes.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Riders Only', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Send to all riders', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: NotificationTarget.customers,
              child: Row(
                children: [
                  Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: Sizes.s20),
                  const SizedBox(width: Sizes.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Customers Only', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Send to all customers', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: NotificationTarget.both,
              child: Row(
                children: [
                  Icon(Icons.group, color: Theme.of(context).colorScheme.primary, size: Sizes.s20),
                  const SizedBox(width: Sizes.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Riders & Customers', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text('Send to both riders and customers', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTarget = value;
              });
              _updateRecipientCount();
            }
          },
        ),
      ],
    );
  }

  Future<void> _updateRecipientCount() async {
    try {
      int count = 0;
      final usersRef = FirebaseService.firestore.collection('users');

      switch (_selectedTarget) {
        case NotificationTarget.all:
          // Get all users (no filter)
          final snapshot = await usersRef.get();
          count = snapshot.docs.length;
          break;
        case NotificationTarget.riders:
          final snapshot = await usersRef.where('userType', isEqualTo: 'rider').get();
          count = snapshot.docs.length;
          break;
        case NotificationTarget.customers:
          final snapshot = await usersRef.where('userType', isEqualTo: 'customer').get();
          count = snapshot.docs.length;
          break;
        case NotificationTarget.both:
          final snapshot = await usersRef.where('userType', whereIn: ['rider', 'customer']).get();
          count = snapshot.docs.length;
          break;
      }

      if (mounted) {
        setState(() {
          _recipientCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error counting recipients: $e');
    }
  }

  Future<void> _handleSendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      // Get target user IDs
      final userIds = await _getTargetUserIds();

      if (userIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No users found for selected target'), backgroundColor: Colors.orange));
        }
        return;
      }

      // Send notification to each user
      int successCount = 0;
      int failCount = 0;

      for (final userId in userIds) {
        try {
          // Create in-app notification in Firestore
          await NotificationService.createInAppNotification(userId: userId, title: title, body: message, type: NotificationType.general);

          // Send push notification (will show local notification on user's device)
          await NotificationService.sendPushNotification(userId: userId, title: title, body: message, data: {'type': 'general', 'adminNotification': 'true'});

          successCount++;
        } catch (e) {
          debugPrint('Error sending notification to user $userId: $e');
          failCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to $successCount user(s)${failCount > 0 ? '. $failCount failed.' : ''}'),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending notification'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<List<String>> _getTargetUserIds() async {
    final usersRef = FirebaseService.firestore.collection('users');
    final List<String> userIds = [];

    try {
      QuerySnapshot snapshot;

      switch (_selectedTarget) {
        case NotificationTarget.all:
          // Get all users (no filter)
          snapshot = await usersRef.get();
          break;
        case NotificationTarget.riders:
          snapshot = await usersRef.where('userType', isEqualTo: 'rider').get();
          break;
        case NotificationTarget.customers:
          snapshot = await usersRef.where('userType', isEqualTo: 'customer').get();
          break;
        case NotificationTarget.both:
          snapshot = await usersRef.where('userType', whereIn: ['rider', 'customer']).get();
          break;
      }

      userIds.addAll(snapshot.docs.map((doc) => doc.id));
    } catch (e) {
      debugPrint('Error fetching user IDs: $e');
    }

    return userIds;
  }

  @override
  void initState() {
    super.initState();
    // Update recipient count when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRecipientCount();
    });
  }
}

enum NotificationTarget { all, riders, customers, both }
