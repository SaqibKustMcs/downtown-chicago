import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/admin/widgets/user_edit_dialog.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/orders/widgets/order_card.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:downtown/core/firebase/firebase_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _userManagementService = UserManagementService.instance;

  @override
  Widget build(BuildContext context) {
    return RoleGuard.guard(
      context: context,
      requiredRole: UserType.admin,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: StreamBuilder<UserModel?>(
            stream: _userManagementService.getUserStream(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Column(
                  children: [
                    TopNavigationBar(
                      title: 'User Details',
                      showBackButton: true,
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: Sizes.s64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: Sizes.s16),
                            Text(
                              'User not found',
                              style: AppTextStyles.heading3.copyWith(
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

              final user = snapshot.data!;
              return Column(
                children: [
                  TopNavigationBar(
                    title: 'User Details',
                    showBackButton: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Sizes.s16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info Card
                          _buildUserInfoCard(user),
                          const SizedBox(height: Sizes.s16),

                          // Management Actions
                          _buildManagementActions(user),
                          const SizedBox(height: Sizes.s16),

                          // Order History
                          _buildOrderHistorySection(user),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: Sizes.s40,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: user.photoUrl != null
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Icon(
                    TablerIconsHelper.user,
                    color: Theme.of(context).colorScheme.primary,
                    size: Sizes.s40,
                  )
                : null,
          ),
          const SizedBox(height: Sizes.s16),

          // Name
          Text(
            user.name ?? 'No Name',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s8),

          // Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                TablerIconsHelper.mail,
                size: Sizes.s16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: Sizes.s8),
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (!user.emailVerified)
                Padding(
                  padding: const EdgeInsets.only(left: Sizes.s8),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: Sizes.s16,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),

          // Phone
          if (user.phoneNumber != null) ...[
            const SizedBox(height: Sizes.s8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  TablerIconsHelper.phone,
                  size: Sizes.s16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: Sizes.s8),
                Text(
                  user.phoneNumber!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: Sizes.s16),
          const Divider(),
          const SizedBox(height: Sizes.s16),

          // User Type Badge
          _buildUserTypeBadge(user.userType),
          const SizedBox(height: Sizes.s12),

          // Account Info
          _buildInfoRow('Account Created', user.createdAt != null
              ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
              : 'N/A'),
          _buildInfoRow('Last Updated', user.updatedAt != null
              ? DateFormat('MMM dd, yyyy').format(user.updatedAt!)
              : 'N/A'),
          
          // Order Count (for customers)
          if (user.userType == UserType.customer) ...[
            const SizedBox(height: Sizes.s12),
            const Divider(),
            const SizedBox(height: Sizes.s12),
            StreamBuilder<int>(
              stream: _getOrderCountStream(user.id),
              builder: (context, snapshot) {
                final orderCount = snapshot.data ?? 0;
                return _buildInfoRow('Total Orders', orderCount.toString());
              },
            ),
          ],

          // Rider-specific info
          if (user.userType == UserType.rider) ...[
            const SizedBox(height: Sizes.s12),
            const Divider(),
            const SizedBox(height: Sizes.s12),
            _buildInfoRow('Online Status', user.isOnline == true ? 'Online' : 'Offline'),
            _buildInfoRow('Availability', user.isAvailable == true ? 'Available' : 'Unavailable'),
            if (user.vehicleType != null)
              _buildInfoRow('Vehicle Type', user.vehicleType!),
            if (user.vehicleNumber != null)
              _buildInfoRow('Vehicle Number', user.vehicleNumber!),
            if (user.activeOrderId != null)
              _buildInfoRow('Active Order', user.activeOrderId!),
          ],

          // Admin-specific info
          if (user.userType == UserType.admin && user.restaurantId != null) ...[
            const SizedBox(height: Sizes.s12),
            const Divider(),
            const SizedBox(height: Sizes.s12),
            _buildInfoRow('Restaurant ID', user.restaurantId!),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTypeBadge(UserType userType) {
    Color badgeColor;
    String label;

    switch (userType) {
      case UserType.admin:
        badgeColor = Colors.green;
        label = 'Admin';
        break;
      case UserType.rider:
        badgeColor = Colors.blue;
        label = 'Rider';
        break;
      case UserType.customer:
        badgeColor = Colors.orange;
        label = 'Customer';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.s20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementActions(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management Actions',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s16),

          // Edit User Button
          _buildActionButton(
            icon: TablerIconsHelper.edit,
            label: 'Edit User',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => _showEditUserDialog(user),
          ),

          // Email Verification Toggle
          _buildActionButton(
            icon: user.emailVerified ? TablerIconsHelper.mail : TablerIconsHelper.mailOff,
            label: user.emailVerified ? 'Mark Email Unverified' : 'Mark Email Verified',
            color: user.emailVerified ? Colors.orange : Colors.green,
            onTap: () => _toggleEmailVerification(user),
          ),

          // Rider-specific actions
          if (user.userType == UserType.rider) ...[
            _buildActionButton(
              icon: user.isOnline == true ? TablerIconsHelper.toggleRight : TablerIconsHelper.toggleLeft,
              label: user.isOnline == true ? 'Set Offline' : 'Set Online',
              color: user.isOnline == true ? Colors.orange : Colors.green,
              onTap: () => _toggleRiderOnlineStatus(user),
            ),
            _buildActionButton(
              icon: user.isAvailable == true ? TablerIconsHelper.x : TablerIconsHelper.check,
              label: user.isAvailable == true ? 'Set Unavailable' : 'Set Available',
              color: user.isAvailable == true ? Colors.orange : Colors.green,
              onTap: () => _toggleRiderAvailability(user),
            ),
          ],

          // Call User (if phone available)
          if (user.phoneNumber != null)
            _buildActionButton(
              icon: TablerIconsHelper.phone,
              label: 'Call User',
              color: Colors.blue,
              onTap: () => _callUser(user.phoneNumber!),
            ),

          const SizedBox(height: Sizes.s8),
          const Divider(),
          const SizedBox(height: Sizes.s8),

          // Delete User Button
          _buildActionButton(
            icon: TablerIconsHelper.trash,
            label: 'Delete User',
            color: Colors.red,
            onTap: () => _showDeleteConfirmation(user),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sizes.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.s8),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.s12),
          child: Row(
            children: [
              Icon(icon, color: color, size: Sizes.s20),
              const SizedBox(width: Sizes.s12),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order History',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Sizes.s16),
        StreamBuilder<List<OrderModel>>(
          stream: OrderService.getCustomerOrders(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading orders',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(Sizes.s32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Sizes.s16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: Sizes.s64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: Sizes.s16),
                      Text(
                        'No orders found',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Sizes.s12),
                  child: OrderCard(order: order),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showEditUserDialog(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserEditDialog(user: user),
    );

    if (result == true && mounted) {
      // Refresh user data
      setState(() {});
    }
  }

  Future<void> _toggleEmailVerification(UserModel user) async {
    final success = await _userManagementService.updateEmailVerificationStatus(
      user.id,
      !user.emailVerified,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Email verification status updated'
              : 'Failed to update email verification status'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleRiderOnlineStatus(UserModel user) async {
    final success = await _userManagementService.updateRiderOnlineStatus(
      user.id,
      !(user.isOnline ?? false),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Rider online status updated'
              : 'Failed to update rider online status'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleRiderAvailability(UserModel user) async {
    final success = await _userManagementService.updateRiderAvailabilityStatus(
      user.id,
      !(user.isAvailable ?? false),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Rider availability updated'
              : 'Failed to update rider availability'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _callUser(String phoneNumber) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.name ?? user.email}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _userManagementService.deleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'User deleted successfully'
                        : 'Failed to delete user'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Stream<int> _getOrderCountStream(String userId) {
    return FirebaseService.firestore
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
