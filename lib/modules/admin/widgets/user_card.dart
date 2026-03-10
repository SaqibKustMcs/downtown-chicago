import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:downtown/core/firebase/firebase_service.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:intl/intl.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const UserCard({super.key, required this.user, this.onTap, this.onDelete, this.onEdit, this.isSelectionMode = false, this.isSelected = false, this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.s12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.s16),
        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: isSelectionMode
            ? () {
                if (onSelectionChanged != null) {
                  onSelectionChanged!(!isSelected);
                }
              }
            : onTap,
        borderRadius: BorderRadius.circular(Sizes.s16),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(Sizes.s16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(Sizes.s16),
            child: Row(
              children: [
                // Selection Checkbox
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: Sizes.s12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        if (onSelectionChanged != null) {
                          onSelectionChanged!(value ?? false);
                        }
                      },
                    ),
                  ),
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: Sizes.s28,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl!) : null,
                      child: user.photoUrl == null ? Icon(TablerIconsHelper.user, color: Theme.of(context).colorScheme.primary, size: Sizes.s28) : null,
                    ),
                    // Online indicator for riders
                    if (user.userType == UserType.rider && user.isOnline == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: Sizes.s16,
                          height: Sizes.s16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: Sizes.s16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and User Type Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name ?? 'No Name',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Sizes.s8),
                          _buildUserTypeBadge(context),
                        ],
                      ),
                      const SizedBox(height: Sizes.s4),

                      // Email
                      Text(
                        user.email,
                        style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Phone (if available)
                      if (user.phoneNumber != null) ...[
                        const SizedBox(height: Sizes.s4),
                        Row(
                          children: [
                            Icon(TablerIconsHelper.phone, size: Sizes.s14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: Sizes.s4),
                            Text(user.phoneNumber!, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      ],

                      // Status Indicators
                      const SizedBox(height: Sizes.s8),
                      Wrap(
                        spacing: Sizes.s8,
                        runSpacing: Sizes.s4,
                        children: [
                          if (!user.emailVerified) _buildStatusChip(context, 'Unverified', Colors.orange, TablerIconsHelper.mail),
                          if (user.userType == UserType.rider) ...[
                            if (user.isAvailable == true) _buildStatusChip(context, 'Available', Colors.green, TablerIconsHelper.check),
                            if (user.isOnline == false) _buildStatusChip(context, 'Offline', Colors.grey, TablerIconsHelper.x),
                          ],
                        ],
                      ),

                      // Activity Indicators
                      if (user.createdAt != null) ...[
                        const SizedBox(height: Sizes.s8),
                        Row(
                          children: [
                            Icon(TablerIconsHelper.calendar, size: Sizes.s12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                            const SizedBox(width: Sizes.s4),
                            Text(
                              'Joined ${DateFormat('MMM yyyy').format(user.createdAt!)}',
                              style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            const SizedBox(width: Sizes.s12),
                            _buildOrderCountBadge(context, user.id),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions (hide in selection mode)
                if (!isSelectionMode && (onEdit != null || onDelete != null))
                  PopupMenuButton<String>(
                    icon: Icon(TablerIconsHelper.dotsVertical, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(TablerIconsHelper.edit, size: Sizes.s18, color: Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: Sizes.s8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(TablerIconsHelper.trash, size: Sizes.s18, color: Colors.red),
                              const SizedBox(width: Sizes.s8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeBadge(BuildContext context) {
    Color badgeColor;
    String label;

    switch (user.userType) {
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
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: badgeColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.s8, vertical: Sizes.s4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(Sizes.s12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Sizes.s12, color: color),
          const SizedBox(width: Sizes.s4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCountBadge(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore.collection('orders').where('customerId', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        final orderCount = snapshot.data?.docs.length ?? 0;
        if (orderCount == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIconsHelper.shoppingBag, size: Sizes.s12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: Sizes.s4),
            Text('$orderCount orders', style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        );
      },
    );
  }
}
