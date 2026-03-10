import 'package:flutter/material.dart';
import 'package:downtown/core/di/dependency_injection.dart';
import 'package:downtown/core/middleware/role_guard.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/modules/admin/services/user_management_service.dart';
import 'package:downtown/modules/admin/services/user_export_service.dart';
import 'package:downtown/modules/admin/widgets/user_card.dart';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/routes/route_constants.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserType? _selectedUserType;
  bool _showFilters = false;
  bool? _filterEmailVerified;
  bool? _filterOnline; // For riders
  bool? _filterAvailable; // For riders
  Set<String> _selectedUserIds = {}; // For bulk actions
  bool _isSelectionMode = false;
  List<UserModel> _currentFilteredUsers = []; // For export

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedUserType = null; // All
            break;
          case 1:
            _selectedUserType = UserType.customer;
            break;
          case 2:
            _selectedUserType = UserType.rider;
            break;
          case 3:
            _selectedUserType = UserType.admin;
            break;
        }
      });
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                title: 'User Management',
                showBackButton: false,
                trailing: _isSelectionMode
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedUserIds.clear();
                                _isSelectionMode = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          if (_selectedUserIds.isNotEmpty)
                            TextButton(
                              onPressed: _showBulkActionsDialog,
                              child: Text('Actions (${_selectedUserIds.length})'),
                            ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _exportUsers(),
                            tooltip: 'Export Users',
                          ),
                          IconButton(
                            icon: const Icon(Icons.checklist),
                            onPressed: () {
                              setState(() {
                                _isSelectionMode = true;
                              });
                            },
                            tooltip: 'Select Multiple',
                          ),
                        ],
                      ),
              ),

              // Statistics
              _buildStatistics(),

              // Search Bar and Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name, email, or phone...',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Sizes.s12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Sizes.s8),
                        IconButton(
                          icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: _showFilters
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            foregroundColor: _showFilters
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    // Filters Panel
                    if (_showFilters) ...[
                      const SizedBox(height: Sizes.s8),
                      Container(
                        padding: const EdgeInsets.all(Sizes.s12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Sizes.s12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filters',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: Sizes.s12),
                            // Email Verified Filter
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Email Verified',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                DropdownButton<bool?>(
                                  value: _filterEmailVerified,
                                  items: [
                                    DropdownMenuItem(value: null, child: Text('All')),
                                    DropdownMenuItem(value: true, child: Text('Verified')),
                                    DropdownMenuItem(value: false, child: Text('Unverified')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _filterEmailVerified = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            // Online Filter (for riders)
                            if (_selectedUserType == UserType.rider || _selectedUserType == null) ...[
                              const SizedBox(height: Sizes.s8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Online Status',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  DropdownButton<bool?>(
                                    value: _filterOnline,
                                    items: [
                                      DropdownMenuItem(value: null, child: Text('All')),
                                      DropdownMenuItem(value: true, child: Text('Online')),
                                      DropdownMenuItem(value: false, child: Text('Offline')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _filterOnline = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: Sizes.s8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Availability',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  DropdownButton<bool?>(
                                    value: _filterAvailable,
                                    items: [
                                      DropdownMenuItem(value: null, child: Text('All')),
                                      DropdownMenuItem(value: true, child: Text('Available')),
                                      DropdownMenuItem(value: false, child: Text('Unavailable')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _filterAvailable = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                            // Clear Filters Button
                            const SizedBox(height: Sizes.s12),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterEmailVerified = null;
                                  _filterOnline = null;
                                  _filterAvailable = null;
                                });
                              },
                              icon: Icon(Icons.clear_all, size: Sizes.s16),
                              label: Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Customers'),
                  Tab(text: 'Riders'),
                  Tab(text: 'Admins'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),

              // Users List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersList(userType: null),
                    _buildUsersList(userType: UserType.customer),
                    _buildUsersList(userType: UserType.rider),
                    _buildUsersList(userType: UserType.admin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return FutureBuilder<Map<String, int>>(
      future: UserManagementService.instance.getUserStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(Sizes.s12),
          padding: const EdgeInsets.all(Sizes.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Sizes.s16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Users', stats['totalUsers'] ?? 0),
              _buildStatItem('Customers', stats['totalCustomers'] ?? 0),
              _buildStatItem('Riders', stats['totalRiders'] ?? 0),
              _buildStatItem('Admins', stats['totalAdmins'] ?? 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: Sizes.s4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList({UserType? userType}) {
    return StreamBuilder<List<UserModel>>(
      stream: _searchQuery.isEmpty
          ? UserManagementService.instance.getAllUsers(userType: userType)
          : UserManagementService.instance.searchUsers(_searchQuery, userType: userType),
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
                  'Error loading users',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }

        // Apply filters
        List<UserModel> filteredUsers = snapshot.data ?? [];
        
        // Store filtered users for export
        _currentFilteredUsers = filteredUsers;
        
        if (_filterEmailVerified != null) {
          filteredUsers = filteredUsers.where((user) => 
            user.emailVerified == _filterEmailVerified
          ).toList();
        }
        
        if (_filterOnline != null && (userType == UserType.rider || userType == null)) {
          filteredUsers = filteredUsers.where((user) => 
            user.userType == UserType.rider && user.isOnline == _filterOnline
          ).toList();
        }
        
        if (_filterAvailable != null && (userType == UserType.rider || userType == null)) {
          filteredUsers = filteredUsers.where((user) => 
            user.userType == UserType.rider && user.isAvailable == _filterAvailable
          ).toList();
        }

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: Sizes.s64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: Sizes.s16),
                Text(
                  'No users found',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Sizes.s12),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return AnimatedListItem(
              index: index,
              child: UserCard(
                user: user,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedUserIds.contains(user.id),
                onSelectionChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedUserIds.add(user.id);
                    } else {
                      _selectedUserIds.remove(user.id);
                    }
                  });
                },
                onTap: () {
                  if (!_isSelectionMode) {
                    Navigator.pushNamed(
                      context,
                      Routes.adminUserDetail,
                      arguments: user.id,
                    );
                  }
                },
                onEdit: () {
                  Navigator.pushNamed(
                    context,
                    Routes.adminUserDetail,
                    arguments: user.id,
                  );
                },
                onDelete: () => _showDeleteConfirmation(user),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name ?? user.email}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await UserManagementService.instance.deleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'User deleted successfully' : 'Failed to delete user'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog() {
    if (_selectedUserIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Actions (${_selectedUserIds.length} users)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Selected'),
              onTap: () {
                Navigator.pop(context);
                _showBulkDeleteConfirmation();
              },
            ),
            ListTile(
              leading: Icon(Icons.verified, color: Colors.green),
              title: Text('Mark Email Verified'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateEmailVerification(true);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.orange),
              title: Text('Mark Email Unverified'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateEmailVerification(false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Users'),
        content: Text(
          'Are you sure you want to delete ${_selectedUserIds.length} user(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bulkDeleteUsers();
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

  Future<void> _bulkDeleteUsers() async {
    int successCount = 0;
    int failCount = 0;

    for (String userId in _selectedUserIds) {
      final success = await UserManagementService.instance.deleteUser(userId);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      setState(() {
        _selectedUserIds.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted $successCount user(s)${failCount > 0 ? ', $failCount failed' : ''}',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkUpdateEmailVerification(bool verified) async {
    int successCount = 0;
    int failCount = 0;

    for (String userId in _selectedUserIds) {
      final success = await UserManagementService.instance.updateEmailVerificationStatus(
        userId,
        verified,
      );
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      setState(() {
        _selectedUserIds.clear();
        _isSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated $successCount user(s)${failCount > 0 ? ', $failCount failed' : ''}',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _exportUsers() async {
    if (_currentFilteredUsers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No users to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Exporting users...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Generate filename based on filters
    String filename = 'users_export';
    if (_selectedUserType != null) {
      switch (_selectedUserType!) {
        case UserType.customer:
          filename = 'customers_export';
          break;
        case UserType.rider:
          filename = 'riders_export';
          break;
        case UserType.admin:
          filename = 'admins_export';
          break;
      }
    }

    // Apply filters to current users
    List<UserModel> usersToExport = List.from(_currentFilteredUsers);
    
    if (_filterEmailVerified != null) {
      usersToExport = usersToExport.where((user) => 
        user.emailVerified == _filterEmailVerified
      ).toList();
    }
    
    if (_filterOnline != null) {
      usersToExport = usersToExport.where((user) => 
        user.userType == UserType.rider && user.isOnline == _filterOnline
      ).toList();
    }
    
    if (_filterAvailable != null) {
      usersToExport = usersToExport.where((user) => 
        user.userType == UserType.rider && user.isAvailable == _filterAvailable
      ).toList();
    }

    final success = await UserExportService.instance.exportUsersToCSV(
      usersToExport,
      filename: filename,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Users exported successfully (${usersToExport.length} users)'
                : 'Failed to export users',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
