import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

/// User Management Screen - Admin only
/// Create and manage Manager and Staff accounts
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserProfile> _users = [];
  bool _isLoading = true;
  RealtimeChannel? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _usersSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    try {
      final supabase = Supabase.instance.client;
      
      debugPrint('🔌 Setting up realtime subscription for user_profiles...');
      
      // Subscribe to user_profiles table changes with detailed event handling
      _usersSubscription = supabase
          .channel('user_profiles_changes_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_profiles',
            callback: (payload) {
              debugPrint('═══════════════════════════════════════');
              debugPrint('🔄 REALTIME EVENT RECEIVED');
              debugPrint('   Event Type: ${payload.eventType}');
              debugPrint('   Table: ${payload.table}');
              debugPrint('   Schema: ${payload.schema}');
              
              if (payload.newRecord != null) {
                debugPrint('   New Data: ${payload.newRecord}');
              }
              if (payload.oldRecord != null) {
                debugPrint('   Old Data: ${payload.oldRecord}');
              }
              
              debugPrint('   → Triggering user list reload...');
              debugPrint('═══════════════════════════════════════');
              
              // Reload users when any change occurs
              _loadUsers();
            },
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Realtime subscription ACTIVE for user_profiles');
            } else if (status == RealtimeSubscribeStatus.closed) {
              debugPrint('⚠️ Realtime subscription CLOSED');
            } else if (error != null) {
              debugPrint('❌ Realtime subscription ERROR: $error');
            }
          });
      
    } catch (e) {
      debugPrint('❌ Failed to setup realtime subscription: $e');
    }
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    debugPrint('========================================');
    debugPrint('📥 LOAD USERS STARTED');
    debugPrint('========================================');
    
    // Test Supabase connection first
    try {
      final supabase = Supabase.instance.client;
      debugPrint('🔗 Supabase client available');
      debugPrint('🔗 Attempting direct database query...');
      
      // Direct test query
      final testResponse = await supabase
          .from('user_profiles')
          .select('id, email, role')
          .limit(5);
      
      debugPrint('📊 DIRECT QUERY RESULT:');
      debugPrint('   Type: ${testResponse.runtimeType}');
      debugPrint('   Is List: ${testResponse is List}');
      debugPrint('   Data: $testResponse');
      
      if (testResponse is List && testResponse.isNotEmpty) {
        debugPrint('✅ Direct query SUCCESS - found ${testResponse.length} users');
        for (var user in testResponse) {
          debugPrint('   - ${user['email']} (${user['role']})');
        }
      } else {
        debugPrint('⚠️ Direct query returned empty or wrong type');
      }
    } catch (e, stack) {
      debugPrint('❌ Direct query FAILED: $e');
      debugPrint('Stack: $stack');
    }
    
    debugPrint('----------------------------------------');
    debugPrint('📋 Now calling authProvider.getAllUsers()...');
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      // Add a small delay to ensure database has processed any recent changes
      await Future.delayed(const Duration(milliseconds: 300));
      
      final users = await authProvider.getAllUsers();
      
      debugPrint('👥 Loaded ${users.length} users from database');
      for (var user in users) {
        debugPrint('   - ${user.fullName} (${user.email}) - Role: ${user.role.name}, Active: ${user.isActive}');
      }
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
        debugPrint('✅ Users list updated in UI');
        debugPrint('📊 FINAL STATE: _users.length = ${_users.length}');
        debugPrint('📊 Users currently in _users list:');
        for (int i = 0; i < _users.length; i++) {
          debugPrint('   [$i] ${_users[i].email} - ${_users[i].role.name} - Active: ${_users[i].isActive}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading users: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    UserRole selectedRole = UserRole.staff;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New User'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      helperText: 'Min. 6 characters',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, size: 20, color: AppColors.lightPrimary),
                            const SizedBox(width: 8),
                            const Text('Admin (unlimited)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UserRole.manager,
                        child: Row(
                          children: [
                            Icon(Icons.supervisor_account, size: 20, color: AppColors.chart2),
                            const SizedBox(width: 8),
                            const Text('Manager (max 1)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UserRole.staff,
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 20, color: AppColors.chart3),
                            const SizedBox(width: 8),
                            const Text('Staff (max 2)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UserRole.developer,
                        child: Row(
                          children: [
                            Icon(Icons.code, size: 20, color: AppColors.chart4),
                            const SizedBox(width: 8),
                            const Text('Developer (full access)'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Store scaffoldMessenger before async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                // Close the create user dialog first
                Navigator.of(context).pop();

                // Show loading with overlay
                bool isLoading = true;
                BuildContext? loadingDialogContext;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    loadingDialogContext = dialogContext;
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Creating user...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

                try {
                  final authProvider = context.read<AuthProvider>();
                  
                  debugPrint('========================================');
                  debugPrint('🔐 USER CREATION STARTED');
                  debugPrint('📧 Email: ${emailController.text.trim()}');
                  debugPrint('👤 Name: ${nameController.text.trim()}');
                  debugPrint('🎭 Role: ${selectedRole.name}');
                  debugPrint('========================================');
                  
                  final newUser = await authProvider.createUser(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    fullName: nameController.text.trim(),
                    role: selectedRole,
                  ).timeout(
                    const Duration(seconds: 15),
                    onTimeout: () {
                      debugPrint('⏱️ User creation timed out after 15 seconds');
                      return null;
                    },
                  );
                  
                  debugPrint('========================================');
                  debugPrint('📊 CREATE USER RESULT:');
                  debugPrint('   Result: ${newUser != null ? "SUCCESS" : "FAILED"}');
                  if (newUser != null) {
                    debugPrint('   Created User ID: ${newUser.id}');
                    debugPrint('   Created User Email: ${newUser.email}');
                    debugPrint('   Created User Role: ${newUser.role.name}');
                  } else {
                    debugPrint('   Error: ${authProvider.error}');
                  }
                  debugPrint('========================================');

                  // ALWAYS close loading dialog
                  if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
                    try {
                      Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                      isLoading = false;
                    } catch (navError) {
                      debugPrint('⚠️ Could not close loading dialog: $navError');
                    }
                  }

                  if (newUser != null) {
                    debugPrint('✅ User created successfully: ${newUser.email}');
                    
                    debugPrint('🔄 Reloading users list...');
                    // Reload users list to show the new user
                    await _loadUsers();
                    debugPrint('✅ Users list reloaded. Current count: ${_users.length}');
                    debugPrint('📋 Users in list:');
                    for (var user in _users) {
                      debugPrint('   - ${user.email} (${user.role.name})');
                    }
                    
                    if (mounted) {
                      // Show success message
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('✅ User created: ${newUser.email}'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } else {
                    debugPrint('❌ User creation failed');
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('❌ Failed: ${authProvider.error ?? "Unknown error"}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Ensure loading dialog is closed on error
                  debugPrint('❌ Exception during user creation: $e');
                  if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
                    try {
                      Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                      isLoading = false;
                    } catch (navError) {
                      debugPrint('⚠️ Could not close dialog: $navError');
                    }
                  }
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chart1,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store context before async
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              navigator.pop(); // Close delete confirmation dialog

              // Show loading with rootNavigator
              bool isLoading = true;
              BuildContext? loadingDialogContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  loadingDialogContext = dialogContext;
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Deleting user...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );

              try {
                final authProvider = context.read<AuthProvider>();
                final success = await authProvider.deleteUser(user.id).timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    debugPrint('⏱️ User deletion timed out');
                    return false;
                  },
                );

                // Close loading dialog
                if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
                  try {
                    Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                    isLoading = false;
                  } catch (navError) {
                    debugPrint('⚠️ Could not close loading dialog: $navError');
                  }
                }

                if (success) {
                  debugPrint('✅ User deleted successfully, reloading list...');
                  await _loadUsers();
                  
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ User deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  debugPrint('❌ User deletion failed');
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('❌ Failed: ${authProvider.error ?? "Unknown error"}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('❌ Exception during user deletion: $e');
                
                // Ensure loading dialog is closed
                if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
                  try {
                    Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                    isLoading = false;
                  } catch (navError) {
                    debugPrint('⚠️ Could not close dialog: $navError');
                  }
                }
                
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    // Check if user is admin
    if (authProvider.currentUser?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
        ),
        body: const Center(
          child: Text('Access Denied: Admin only'),
        ),
      );
    }

    final managerCount = _users.where((u) => u.role == UserRole.manager && u.isActive).length;
    final staffCount = _users.where((u) => u.role == UserRole.staff && u.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User list refreshed'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Refresh user list',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      // Debug info banner
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Total Users Loaded: ${_users.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Managers',
                              '$managerCount / 1',
                              Icons.supervisor_account,
                              AppColors.chart2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Staff',
                              '$staffCount / 2',
                              Icons.people,
                              AppColors.chart3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Users List
                Expanded(
                  child: _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users yet',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first user',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _loadUsers();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User list refreshed'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return _buildUserCard(context, user);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: AppColors.chart1,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserProfile user) {
    final theme = Theme.of(context);
    final authProvider = context.read<AuthProvider>();
    final isCurrentUser = user.id == authProvider.currentUser?.id;

    Color roleColor;
    IconData roleIcon;
    String roleLabel;
    switch (user.role) {
      case UserRole.admin:
        roleColor = AppColors.chart1;
        roleIcon = Icons.admin_panel_settings;
        roleLabel = 'Admin';
        break;
      case UserRole.manager:
        roleColor = AppColors.chart2;
        roleIcon = Icons.supervisor_account;
        roleLabel = 'Manager';
        break;
      case UserRole.staff:
        roleColor = AppColors.chart3;
        roleIcon = Icons.person;
        roleLabel = 'Staff';
        break;
      case UserRole.developer:
        roleColor = AppColors.chart4;
        roleIcon = Icons.code;
        roleLabel = 'Developer';
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withAlpha(51),
          radius: 24,
          child: Icon(roleIcon, color: roleColor, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.chart1.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.chart1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 14, color: roleColor),
                      const SizedBox(width: 4),
                      Text(
                        roleLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isActive 
                        ? Colors.green.withAlpha(51) 
                        : Colors.grey.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isActive ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: user.isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: user.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: !isCurrentUser
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Login As button for staff/manager
                  if (user.role != UserRole.admin)
                    IconButton(
                      icon: const Icon(Icons.login),
                      color: AppColors.chart1,
                      onPressed: () => _loginAsUser(user),
                      tooltip: 'Login as ${user.fullName}',
                    ),
                  // Delete button
                  if (user.role != UserRole.admin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () => _showDeleteUserDialog(user),
                      tooltip: 'Delete user',
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _loginAsUser(UserProfile user) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login As User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Login as ${user.fullName}?'),
            const SizedBox(height: 8),
            Text(
              'Email: ${user.email}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will be logged out and logged in as this user.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chart1,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login As'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Switching user...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Unfortunately, we can't log in as another user without their password
      // We need to store the password when creating the user or use a different method
      // For now, show an error message explaining this limitation
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (!mounted) return;
      
      // Show password input dialog
      final passwordController = TextEditingController();
      final passwordEntered = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Password for ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the password you created for ${user.email}:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(passwordController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.chart1,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      );

      if (passwordEntered == null || passwordEntered.isEmpty || !mounted) return;

      // Show loading again
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logging in...'),
                ],
              ),
            ),
          ),
        ),
      );

      final authProvider = context.read<AuthProvider>();
      
      // Sign out current user
      await authProvider.signOut();
      
      // Sign in as the selected user
      final success = await authProvider.signIn(
        email: user.email,
        password: passwordEntered,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Logged in as ${user.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Invalid password for ${user.email}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close any open dialogs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
