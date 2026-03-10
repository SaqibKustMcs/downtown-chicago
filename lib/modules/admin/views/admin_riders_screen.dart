import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/admin/widgets/rider_card.dart';
import 'package:downtown/modules/admin/widgets/create_rider_dialog.dart';
import 'package:downtown/modules/admin/widgets/edit_rider_dialog.dart';
import 'package:downtown/modules/admin/widgets/set_password_dialog.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';

class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});

  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFilters = false;
  bool? _filterOnline;
  bool? _filterAvailable;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard.guard(
      context: context,
      requiredRole: UserType.admin,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top Navigation
              TopNavigationBar(
                title: 'Riders Management',
                showBackButton: false,
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showCreateRiderDialog,
                  tooltip: 'Add New Rider',
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(Sizes.s16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search riders by name, email, or phone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.s12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: Sizes.s12),
                    IconButton(
                      icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      tooltip: 'Filters',
                    ),
                  ],
                ),
              ),

              // Filters
              if (_showFilters) _buildFilters(),

              // Riders List
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: UserManagementService.instance.searchUsers(
                    _searchQuery,
                    userType: UserType.rider,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
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
                              'Error loading riders',
                              style: AppTextStyles.heading3.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              snapshot.error.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final riders = snapshot.data ?? [];
                    final filteredRiders = _applyFilters(riders);

                    if (filteredRiders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIconsHelper.truck,
                              size: Sizes.s80,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: Sizes.s24),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No riders found'
                                  : 'No riders yet',
                              style: AppTextStyles.heading2.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: Sizes.s8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try adjusting your search or filters'
                                  : 'Add your first rider to get started',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: Sizes.s24),
                              ElevatedButton.icon(
                                onPressed: _showCreateRiderDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Rider'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Sizes.s24,
                                    vertical: Sizes.s12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(Sizes.s16),
                      itemCount: filteredRiders.length,
                      itemBuilder: (context, index) {
                        final rider = filteredRiders[index];
                        return AnimatedListItem(
                          index: index,
                          child: RiderCard(
                            rider: rider,
                            onTap: () => _navigateToRiderDetail(rider.id),
                            onEdit: () => _showEditRiderDialog(rider),
                            onSetPassword: () => _showSetPasswordDialog(rider),
                            onDelete: () => _showDeleteConfirmation(rider),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateRiderDialog,
          backgroundColor: const Color(0xFFFF6B35),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Rider',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(Sizes.s16),
      margin: const EdgeInsets.symmetric(horizontal: Sizes.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Sizes.s12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Sizes.s16),
          // Online Filter
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'Online',
                  value: _filterOnline,
                  onChanged: (value) {
                    setState(() {
                      _filterOnline = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Available',
                  value: _filterAvailable,
                  onChanged: (value) {
                    setState(() {
                      _filterAvailable = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.s12),
          // Clear Filters Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _filterOnline = null;
                  _filterAvailable = null;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: value != null,
      onSelected: (selected) {
        onChanged(selected ? true : null);
      },
      selectedColor: const Color(0xFFFF6B35).withOpacity(0.2),
      checkmarkColor: const Color(0xFFFF6B35),
    );
  }

  List<UserModel> _applyFilters(List<UserModel> riders) {
    var filtered = riders;

    if (_filterOnline != null) {
      filtered = filtered.where((rider) => rider.isOnline == _filterOnline).toList();
    }

    if (_filterAvailable != null) {
      filtered = filtered.where((rider) => rider.isAvailable == _filterAvailable).toList();
    }

    return filtered;
  }

  Future<void> _showCreateRiderDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateRiderDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider created successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _showEditRiderDialog(UserModel rider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditRiderDialog(rider: rider),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider updated successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _showSetPasswordDialog(UserModel rider) async {
    await showDialog(
      context: context,
      builder: (context) => SetPasswordDialog(rider: rider),
    );
  }

  Future<void> _showDeleteConfirmation(UserModel rider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rider'),
        content: Text('Are you sure you want to delete ${rider.name ?? rider.email}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await UserManagementService.instance.deleteUser(rider.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Rider deleted successfully' : 'Failed to delete rider'),
            backgroundColor: success ? const Color(0xFF4CAF50) : Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToRiderDetail(String riderId) {
    Navigator.pushNamed(context, Routes.adminUserDetail, arguments: riderId);
  }
}
