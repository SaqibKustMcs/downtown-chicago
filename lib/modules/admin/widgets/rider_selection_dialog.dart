import 'package:flutter/material.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/orders/services/order_service.dart';
import 'package:downtown/modules/rider/services/rider_service.dart';
import 'package:downtown/modules/admin/widgets/rider_list_item.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

/// Reusable dialog for selecting a rider
/// Uses RepaintBoundary and const constructors for performance
class RiderSelectionDialog extends StatefulWidget {
  final String orderId;
  final String? currentRiderId;

  const RiderSelectionDialog({
    super.key,
    required this.orderId,
    this.currentRiderId,
  });

  @override
  State<RiderSelectionDialog> createState() => _RiderSelectionDialogState();
}

class _RiderSelectionDialogState extends State<RiderSelectionDialog> {
  String? _selectedRiderId;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _selectedRiderId = widget.currentRiderId;
  }

  Future<void> _handleAssign() async {
    if (_selectedRiderId == null) return;

    setState(() {
      _isAssigning = true;
    });

    try {
      final success = await OrderService.assignRiderToOrder(
        widget.orderId,
        _selectedRiderId!,
      );

      if (!mounted) return;

      if (success) {
        // Close dialog first, then show snackbar to prevent flickering
        Navigator.of(context).pop(true); // Return true on success
        
        // Show snackbar after a small delay to ensure dialog is closed
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rider assigned successfully'),
                backgroundColor: Color(0xFF4CAF50),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign rider. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Dialog(
        backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.s16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _DialogHeader(
                title: 'Select Rider',
                onClose: () => Navigator.of(context).pop(),
              ),

              // Riders List
              Flexible(
                child: StreamBuilder<List<UserModel>>(
                  stream: RiderService.getAvailableRiders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingIndicator();
                    }

                    if (snapshot.hasError) {
                      return _ErrorWidget(
                        message: 'Error loading riders: ${snapshot.error}',
                      );
                    }

                    final riders = snapshot.data ?? [];

                    if (riders.isEmpty) {
                      return const _EmptyState();
                    }

                    return _RidersList(
                      riders: riders,
                      selectedRiderId: _selectedRiderId,
                      onRiderSelected: (riderId) {
                        setState(() {
                          _selectedRiderId = riderId;
                        });
                      },
                    );
                  },
                ),
              ),

              // Footer Actions
              _DialogFooter(
                isAssigning: _isAssigning,
                canAssign: _selectedRiderId != null,
                onAssign: _handleAssign,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog header widget
class _DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s16),
        child: Row(
          children: [
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
              iconSize: Sizes.s20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading indicator widget
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(Sizes.s32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Error widget
class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: Sizes.s48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: Sizes.s16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: Sizes.s64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: Sizes.s16),
            Text(
              'No available riders',
              style: AppTextStyles.heading3.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: Sizes.s8),
            Text(
              'All riders are currently offline or busy',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Riders list widget
class _RidersList extends StatelessWidget {
  final List<UserModel> riders;
  final String? selectedRiderId;
  final ValueChanged<String> onRiderSelected;

  const _RidersList({
    required this.riders,
    required this.selectedRiderId,
    required this.onRiderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.s16,
        vertical: Sizes.s8,
      ),
      shrinkWrap: true,
      itemCount: riders.length,
      separatorBuilder: (context, index) => const SizedBox(height: Sizes.s8),
      itemBuilder: (context, index) {
        final rider = riders[index];
        return RepaintBoundary(
          child: RiderListItem(
            rider: rider,
            isSelected: selectedRiderId == rider.id,
            onTap: () => onRiderSelected(rider.id),
          ),
        );
      },
    );
  }
}

/// Dialog footer with actions
class _DialogFooter extends StatelessWidget {
  final bool isAssigning;
  final bool canAssign;
  final VoidCallback onAssign;
  final VoidCallback onCancel;

  const _DialogFooter({
    required this.isAssigning,
    required this.canAssign,
    required this.onAssign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(Sizes.s16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sizes.s8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: Sizes.s12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canAssign && !isAssigning ? onAssign : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: Sizes.s12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sizes.s8),
                  ),
                ),
                child: isAssigning
                    ? const SizedBox(
                        width: Sizes.s20,
                        height: Sizes.s20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Assign Rider',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
