import 'package:flutter/material.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/widgets/network_image_widget.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Reusable widget for displaying a rider in a list
/// Uses RepaintBoundary for performance optimization
class RiderListItem extends StatelessWidget {
  final UserModel rider;
  final bool isSelected;
  final VoidCallback onTap;

  const RiderListItem({
    super.key,
    required this.rider,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.s12),
        child: Container(
          padding: const EdgeInsets.all(Sizes.s12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rider Avatar
              _RiderAvatar(
                imageUrl: rider.userImage ?? rider.photoUrl,
                isOnline: rider.isOnline ?? false,
              ),
              const SizedBox(width: Sizes.s12),
              
              // Rider Info
              Expanded(
                child: _RiderInfo(
                  name: rider.name ?? 'Unknown Rider',
                  vehicleType: rider.vehicleType,
                  vehicleNumber: rider.vehicleNumber,
                ),
              ),
              
              // Selection Indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: Sizes.s24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rider avatar with online indicator
class _RiderAvatar extends StatelessWidget {
  final String? imageUrl;
  final bool isOnline;

  const _RiderAvatar({
    required this.imageUrl,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          ClipOval(
            child: NetworkImageWidget(
              imageUrl: imageUrl ?? '',
              width: Sizes.s48,
              height: Sizes.s48,
              fit: BoxFit.cover,
              errorIcon: Icons.person,
              errorIconSize: Sizes.s24,
            ),
          ),
          // Online indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: Sizes.s12,
              height: Sizes.s12,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rider information display
class _RiderInfo extends StatelessWidget {
  final String name;
  final String? vehicleType;
  final String? vehicleNumber;

  const _RiderInfo({
    required this.name,
    this.vehicleType,
    this.vehicleNumber,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (vehicleType != null || vehicleNumber != null) ...[
            const SizedBox(height: Sizes.s4),
            Text(
              _getVehicleInfo(),
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _getVehicleInfo() {
    if (vehicleType != null && vehicleNumber != null) {
      return '$vehicleType • $vehicleNumber';
    } else if (vehicleType != null) {
      return vehicleType!;
    } else if (vehicleNumber != null) {
      return vehicleNumber!;
    }
    return 'No vehicle info';
  }
}
