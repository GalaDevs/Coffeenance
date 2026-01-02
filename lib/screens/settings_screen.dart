import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../models/shop_settings.dart';
import '../models/announcement.dart';
import '../models/activity_log.dart';
import '../services/shop_settings_service.dart';
import '../services/announcement_service.dart';
import '../services/activity_log_service.dart';
import '../theme/app_theme.dart';
import 'supabase_test_screen.dart';
import 'connection_debug_screen.dart';
import 'data_isolation_test_screen.dart';
import 'user_management_screen.dart';
import '../widgets/map_location_picker.dart';

/// Settings Page Screen - Matches settings-page.tsx
/// Shows app settings and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ShopSettings? _shopSettings;
  bool _loadingSettings = true;
  late ShopSettingsService _shopSettingsService;
  late AnnouncementService _announcementService;
  List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _shopSettingsService = ShopSettingsService(Supabase.instance.client);
    _announcementService = AnnouncementService(Supabase.instance.client);
    _loadShopSettings();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser?.role == UserRole.developer) {
      final announcements = await _announcementService.getAllAnnouncements();
      setState(() => _announcements = announcements);
    }
  }

  Future<void> _loadShopSettings() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      setState(() => _loadingSettings = false);
      return;
    }

    // Get admin ID (use current user's ID if admin/developer, or their admin_id if staff/manager)
    final adminId = (currentUser.role == UserRole.admin || currentUser.role == UserRole.developer)
        ? currentUser.id
        : currentUser.adminId ?? currentUser.id;

    try {
      final settings = await _shopSettingsService.getShopSettings(adminId);
      if (settings == null) {
        // Initialize default settings if none exist
        final newSettings =
            await _shopSettingsService.initializeSettings(adminId);
        setState(() {
          _shopSettings = newSettings;
          _loadingSettings = false;
        });
      } else {
        setState(() {
          _shopSettings = settings;
          _loadingSettings = false;
        });
      }
    } catch (e) {
      print('Error loading shop settings: $e');
      setState(() => _loadingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with User Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (currentUser != null)
                      Text(
                        '${currentUser.fullName} • ${currentUser.role.displayName}',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Text(
                        'Manage your preferences',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (currentUser != null)
                CircleAvatar(
                  backgroundColor: _getRoleColor(currentUser.role).withAlpha(51),
                  child: Icon(
                    _getRoleIcon(currentUser.role),
                    color: _getRoleColor(currentUser.role),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Account Section (for authenticated users)
          if (currentUser != null) ...[
            _buildSectionTitle('Account', theme),
            Card(
              child: Column(
                children: [
                  if (authProvider.canManageUsers) ...[
                    ListTile(
                      leading: Icon(
                        Icons.people,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('User Management'),
                      subtitle: const Text('Manage staff and manager accounts'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  // Activity Log (Admin only)
                  if (currentUser.role == UserRole.admin || currentUser.role == UserRole.developer) ...[
                    ListTile(
                      leading: Icon(
                        Icons.history,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Activity Log'),
                      subtitle: const Text('View revenue and expense activity'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showActivityLogDialog(context),
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: const Text('Sign Out'),
                    subtitle: Text('Logged in as ${currentUser.email}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLogoutDialog(context, authProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Appearance Section
          _buildSectionTitle('Appearance', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark color theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Developer-only: Announcements Section
          if (currentUser?.role == UserRole.developer) ...[
            _buildSectionTitle('Announcements', theme),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.campaign_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Create Announcement'),
                    subtitle: const Text('Broadcast message to all users'),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _showCreateAnnouncementDialog(context),
                  ),
                  if (_announcements.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _announcements.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final announcement = _announcements[index];
                        return ListTile(
                          leading: Icon(
                            announcement.isActive 
                                ? Icons.notifications_active 
                                : Icons.notifications_off,
                            color: announcement.isActive 
                                ? Colors.green 
                                : Colors.grey,
                            size: 20,
                          ),
                          title: Text(
                            announcement.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: announcement.isActive 
                                  ? null 
                                  : Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            announcement.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: announcement.isActive 
                                  ? null 
                                  : Colors.grey,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (context) => [
                              if (announcement.announcedAt == null)
                                PopupMenuItem(
                                  value: 'announce',
                                  child: Row(
                                    children: [
                                      Icon(Icons.send, size: 18, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      const Text('Announce Now', style: TextStyle(color: Colors.blue)),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      announcement.isActive 
                                          ? Icons.visibility_off 
                                          : Icons.visibility,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(announcement.isActive ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) => _handleAnnouncementAction(
                              value, 
                              announcement,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Data Management Section
          _buildSectionTitle('Data Management', theme),
          Card(
            child: Column(
              children: [
                // Developer-only: Data Isolation Test
                if (currentUser?.role == UserRole.developer) ...[
                  ListTile(
                    leading: Icon(
                      Icons.security,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Data Isolation Test'),
                    subtitle: const Text('Verify user data separation'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataIsolationTestScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
                // Developer-only: Connection Diagnostics
                if (currentUser?.role == UserRole.developer) ...[
                  ListTile(
                    leading: Icon(
                      Icons.bug_report,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Connection Diagnostics'),
                    subtitle: const Text('Detailed cloud connection testing'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConnectionDebugScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
                // Developer-only: Online/Auto Sync Status
                if (currentUser?.role == UserRole.developer)
                  Consumer<TransactionProvider>(
                    builder: (context, provider, child) {
                      return ListTile(
                        leading: Icon(
                          provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: provider.isOnline ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          provider.isOnline ? 'Online - Auto Sync Active' : 'Offline Mode',
                        ),
                        subtitle: Text(
                          provider.pendingSyncCount > 0
                              ? '${provider.pendingSyncCount} transaction${provider.pendingSyncCount > 1 ? 's' : ''} pending sync'
                              : 'All data synced',
                        ),
                        trailing: provider.pendingSyncCount > 0
                            ? ElevatedButton.icon(
                                onPressed: provider.isSyncing
                                    ? null
                                    : () => provider.syncPendingTransactions(),
                                icon: provider.isSyncing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.sync, size: 18),
                                label: Text(provider.isSyncing ? 'Syncing...' : 'Sync Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              )
                            : Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                              ),
                      );
                    },
                  ),
                if (currentUser?.role == UserRole.developer) const Divider(height: 1),
                // Developer-only: Quick Connection Test
                if (currentUser?.role == UserRole.developer) ...[
                  ListTile(
                    leading: Icon(
                      Icons.cloud_done,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Quick Connection Test'),
                    subtitle: const Text('Simple cloud verification'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupabaseTestScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: Icon(
                    Icons.file_download,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your transaction history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.file_upload,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Remove all transactions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearDataDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Information Section
          _buildSectionTitle('Business Information', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.store,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Shop Name'),
                  subtitle: Text(_loadingSettings
                      ? 'Loading...'
                      : _shopSettings?.shopName ?? 'Cafenance Coffee Shop'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEditShopNameDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Location'),
                  subtitle: Text(_loadingSettings
                      ? 'Loading...'
                      : _shopSettings?.displayLocation ?? 'Not set'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLocationOptions(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Tax Settings'),
                  subtitle: const Text('Configure tax rates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTaxSettings(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle('About', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/GalaDevs Corp Logo navy.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: const Text('Technology'),
                  subtitle: const Text('Crafted by GalaDevs Technology Corp'),
                  trailing: Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                  onTap: () async {
                    final url = Uri.parse('https://www.galadevs.com/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const Divider(height: 1),

              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.headlineMedium,
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.chart1;
      case UserRole.manager:
        return AppColors.chart2;
      case UserRole.staff:
        return AppColors.chart3;
      case UserRole.developer:
        return AppColors.chart4;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.supervisor_account;
      case UserRole.staff:
        return Icons.person;
      case UserRole.developer:
        return Icons.code;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
              if (context.mounted) {
                // Navigate to login screen and clear navigation stack
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon'),
      ),
    );
  }

  void _showEditShopNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _shopSettings?.shopName ?? 'Cafenance Coffee Shop',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shop Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Shop Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shop name cannot be empty')),
                );
                return;
              }

              try {
                final authProvider = context.read<AuthProvider>();
                final currentUser = authProvider.currentUser;
                if (currentUser == null) return;

                final adminId = currentUser.role == UserRole.admin
                    ? currentUser.id
                    : currentUser.adminId ?? currentUser.id;

                final updated = await _shopSettingsService.updateShopName(
                  adminId: adminId,
                  shopName: newName,
                );

                setState(() => _shopSettings = updated);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Shop name updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLocationOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_searching),
              title: const Text('Pick on Map'),
              subtitle: const Text('Select location with map pin'),
              onTap: () {
                Navigator.pop(context);
                _showMapPicker(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Use Current Location'),
              subtitle: const Text('Get GPS coordinates'),
              onTap: () {
                Navigator.pop(context);
                _getCurrentLocation(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_location),
              title: const Text('Enter Address'),
              subtitle: const Text('Type location manually'),
              onTap: () {
                Navigator.pop(context);
                _showEnterAddressDialog(context);
              },
            ),
            if (_shopSettings?.hasLocation == true) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Open in Maps'),
                subtitle: const Text('View on map app'),
                onTap: () {
                  Navigator.pop(context);
                  _openInMaps();
                },
              ),
            ],
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

  Future<void> _showMapPicker(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _shopSettings?.locationLatitude,
          initialLongitude: _shopSettings?.locationLongitude,
          initialAddress: _shopSettings?.locationAddress,
        ),
      ),
    );

    if (result != null && context.mounted) {
      try {
        final authProvider = context.read<AuthProvider>();
        final currentUser = authProvider.currentUser;
        if (currentUser == null) return;

        final adminId = currentUser.role == UserRole.admin
            ? currentUser.id
            : currentUser.adminId ?? currentUser.id;

        final updated = await _shopSettingsService.updateLocation(
          adminId: adminId,
          locationAddress: result['address'] as String?,
          locationLatitude: result['latitude'] as double?,
          locationLongitude: result['longitude'] as double?,
        );

        setState(() => _shopSettings = updated);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating location: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permissions are permanently denied. Please enable them in settings.')),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting current location...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Try to get address from coordinates
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = [place.street, place.locality, place.country]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ');
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Update location in database
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) return;

      final adminId = currentUser.role == UserRole.admin
          ? currentUser.id
          : currentUser.adminId ?? currentUser.id;

      final updated = await _shopSettingsService.updateLocation(
        adminId: adminId,
        locationAddress: address,
        locationLatitude: position.latitude,
        locationLongitude: position.longitude,
      );

      setState(() => _shopSettings = updated);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  void _showEnterAddressDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _shopSettings?.locationAddress ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            hintText: 'Street, City, Country',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final address = controller.text.trim();
              if (address.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address cannot be empty')),
                );
                return;
              }

              try {
                // Try to geocode the address to get coordinates
                double? latitude;
                double? longitude;
                try {
                  List<Location> locations =
                      await locationFromAddress(address);
                  if (locations.isNotEmpty) {
                    latitude = locations.first.latitude;
                    longitude = locations.first.longitude;
                  }
                } catch (e) {
                  print('Could not geocode address: $e');
                }

                final authProvider = context.read<AuthProvider>();
                final currentUser = authProvider.currentUser;
                if (currentUser == null) return;

                final adminId = currentUser.role == UserRole.admin
                    ? currentUser.id
                    : currentUser.adminId ?? currentUser.id;

                final updated = await _shopSettingsService.updateLocation(
                  adminId: adminId,
                  locationAddress: address,
                  locationLatitude: latitude,
                  locationLongitude: longitude,
                );

                setState(() => _shopSettings = updated);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Address updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps() async {
    if (_shopSettings?.hasLocation != true) return;

    final lat = _shopSettings!.locationLatitude!;
    final lng = _shopSettings!.locationLongitude!;

    // Try different map URLs
    final urls = [
      'https://maps.apple.com/?q=$lat,$lng', // Apple Maps
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng', // Google Maps
    ];

    for (final urlString in urls) {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps application')),
      );
    }
  }

  void _showTaxSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TaxSettingsDialog(),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will export all your transaction data to a CSV file that you can open in Excel or any spreadsheet application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportData(context);
            },
            child: const Text('Export to CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Show loading indicator
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing CSV export...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get transaction data
      final transactionProvider = context.read<TransactionProvider>();
      final transactions = transactionProvider.transactions;

      // Create CSV content
      final csvBuffer = StringBuffer();
      
      // Add summary header
      csvBuffer.writeln('Cafenance Transaction Export');
      csvBuffer.writeln('Export Date,${DateTime.now().toString().split('.')[0]}');
      csvBuffer.writeln('Total Transactions,${transactions.length}');
      csvBuffer.writeln('Total Revenue,${transactionProvider.totalRevenue.toStringAsFixed(2)}');
      csvBuffer.writeln('Total Expenses,${transactionProvider.totalTransactions.toStringAsFixed(2)}');
      csvBuffer.writeln('Balance,${transactionProvider.balance.toStringAsFixed(2)}');
      csvBuffer.writeln('');
      
      // Add CSV headers
      csvBuffer.writeln('ID,Date,Type,Category,Description,Amount,Payment Method,Transaction Number,Receipt Number,TIN Number,VAT,Supplier Name,Supplier Address');
      
      // Add transaction data
      for (var t in transactions) {
        final type = t.type.toString().split('.').last;
        csvBuffer.writeln(
          '${t.id},'
          '"${t.date}",'
          '"$type",'
          '"${t.category}",'
          '"${_escapeCsv(t.description)}",'
          '${t.amount.toStringAsFixed(2)},'
          '"${t.paymentMethod}",'
          '"${t.transactionNumber}",'
          '"${t.receiptNumber}",'
          '"${t.tinNumber}",'
          '${t.vat},'
          '"${_escapeCsv(t.supplierName)}",'
          '"${_escapeCsv(t.supplierAddress)}"'
        );
      }

      // Create file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cafenance_export_$timestamp.csv';
      
      // Get Downloads directory (for iOS, use documents directory)
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // macOS or other platforms
        directory = await getDownloadsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      final file = File('${directory.path}/$fileName');
      
      // Write CSV to file
      await file.writeAsString(csvBuffer.toString());

      if (!context.mounted) return;
      
      // Automatically open the file
      final result = await OpenFilex.open(file.path);
      
      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✅ Export Successful!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('File: $fileName'),
              Text('Saved to: ${directory.path}'),
              if (result.message.isNotEmpty)
                Text('Status: ${result.message}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Open Again',
            textColor: Colors.white,
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
      
      // Close the export dialog if it's open
      Navigator.of(context).pop();
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _escapeCsv(String value) {
    // Escape quotes and commas for CSV format
    if (value.contains('"')) {
      return value.replaceAll('"', '""');
    }
    return value;
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This feature will restore your transaction data from a backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Clear All Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete all transactions? This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Verify password with Supabase
                try {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null || user.email == null) {
                    throw Exception('User not logged in');
                  }

                  // Re-authenticate user
                  await Supabase.instance.client.auth.signInWithPassword(
                    email: user.email!,
                    password: password,
                  );

                  // Password is correct, proceed with clearing data
                  if (context.mounted) {
                    Navigator.pop(context);
                    await context.read<TransactionProvider>().clearAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data cleared successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect password. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        ),
      ),
    ).then((_) => passwordController.dispose());
  }

  // Announcement Management Methods
  Future<void> _showCreateAnnouncementDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkController = TextEditingController();
    final theme = Theme.of(context);
    bool announceNow = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.campaign_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Create Announcement'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter announcement title',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter announcement details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'Download Link (Optional)',
                    hintText: 'Enter download URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Announce Now'),
                  subtitle: const Text('Send to all users immediately'),
                  value: announceNow,
                  onChanged: (value) {
                    setState(() => announceNow = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in both title and description'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                print('📝 Creating announcement...');
                print('📝 Title: ${titleController.text.trim()}');
                print('📝 Announce Now: $announceNow');
                
                final authProvider = context.read<AuthProvider>();
                print('📝 Creator ID: ${authProvider.currentUser!.id}');
                
                final result = await _announcementService.createAnnouncement(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  downloadLink: linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                  createdBy: authProvider.currentUser!.id,
                );
                
                print('📝 Announcement created: ${result != null}');

                if (!context.mounted) return;
                
                Navigator.pop(context);
                
                if (result != null) {
                  // If announce now is checked, send to all users
                  if (announceNow) {
                    print('🔔 Announcing to all users...');
                    final success = await _announcementService.announceToAllUsers(
                      announcementId: result.id,
                      title: result.title,
                      description: result.description,
                      downloadLink: result.downloadLink,
                      adminId: authProvider.currentUser!.id,
                    );
                    print('🔔 Announce result: $success');

                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Announcement sent to all users!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Announcement created but failed to send'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Announcement created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  _loadAnnouncements();
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create announcement'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAnnouncementAction(String action, Announcement announcement) async {
    switch (action) {
      case 'announce':
        await _announceToAllUsers(announcement);
        break;
      case 'toggle':
        final success = await _announcementService.toggleAnnouncementStatus(
          announcement.id,
          !announcement.isActive,
        );
        if (success) {
          _loadAnnouncements();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  announcement.isActive 
                      ? 'Announcement deactivated' 
                      : 'Announcement activated',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        break;
      case 'edit':
        _showEditAnnouncementDialog(announcement);
        break;
      case 'delete':
        _showDeleteAnnouncementConfirmation(announcement);
        break;
    }
  }

  Future<void> _announceToAllUsers(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Announce to All Users'),
        content: Text(
          'Send this announcement to all users?\n\n'
          'Title: ${announcement.title}\n\n'
          'This will create notifications and send emails to all team members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      final success = await _announcementService.announceToAllUsers(
        announcementId: announcement.id,
        title: announcement.title,
        description: announcement.description,
        adminId: authProvider.currentUser!.id,
      );

      if (mounted) {
        if (success) {
          _loadAnnouncements();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement sent to all users!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send announcement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditAnnouncementDialog(Announcement announcement) async {
    final titleController = TextEditingController(text: announcement.title);
    final descriptionController = TextEditingController(text: announcement.description);
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Edit Announcement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in both title and description'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final result = await _announcementService.updateAnnouncement(
                id: announcement.id,
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (result != null) {
                  _loadAnnouncements();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAnnouncementConfirmation(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _announcementService.deleteAnnouncement(announcement.id);
      if (success) {
        _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _showActivityLogDialog(BuildContext context) async {
    final activityLogService = ActivityLogService(Supabase.instance.client);
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<ActivityLog>>(
        future: activityLogService.getActivityLogs(limit: 100),
        builder: (context, snapshot) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Activity Log',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track revenue and expense additions by team members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Expanded(
                      child: Center(
                        child: Text('Error loading activity log: ${snapshot.error}'),
                      ),
                    )
                  else if (!snapshot.hasData || snapshot.data!.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No activity recorded yet'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final log = snapshot.data![index];
                          final isRevenue = log.actionType == ActivityAction.addRevenue;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isRevenue 
                                    ? Colors.green.withAlpha(51)
                                    : Colors.red.withAlpha(51),
                                child: Icon(
                                  isRevenue 
                                      ? Icons.arrow_upward_rounded 
                                      : Icons.arrow_downward_rounded,
                                  color: isRevenue ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    log.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(UserRole.fromString(log.userRole))
                                          .withAlpha(51),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      log.roleDisplay,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _getRoleColor(UserRole.fromString(log.userRole)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    log.actionDisplay,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (log.amount != null)
                                    Text(
                                      '₱${log.amount!.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isRevenue ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  if (log.category != null)
                                    Text(
                                      log.category!,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  if (log.description != null)
                                    Text(
                                      log.description!,
                                      style: const TextStyle(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    _formatActivityTime(log.createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Tax Settings Dialog
class TaxSettingsDialog extends StatefulWidget {
  const TaxSettingsDialog({super.key});

  @override
  State<TaxSettingsDialog> createState() => _TaxSettingsDialogState();
}

class _TaxSettingsDialogState extends State<TaxSettingsDialog> {
  late TextEditingController _vatRateController;
  late TextEditingController _tinController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late bool _enableVAT;
  late bool _taxInclusive;
  late bool _zeroRatedEnabled;
  late bool _vatExemptEnabled;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _vatRateController = TextEditingController(
      text: (provider.getTaxSetting('vatRate') ?? 12.0).toString(),
    );
    _tinController = TextEditingController(
      text: provider.getTaxSetting('businessTIN') ?? '',
    );
    _businessNameController = TextEditingController(
      text: provider.getTaxSetting('businessName') ?? '',
    );
    _businessAddressController = TextEditingController(
      text: provider.getTaxSetting('businessAddress') ?? '',
    );
    _enableVAT = provider.getTaxSetting('enableVAT') ?? true;
    _taxInclusive = provider.getTaxSetting('taxInclusive') ?? false;
    _zeroRatedEnabled = provider.getTaxSetting('zeroRatedEnabled') ?? true;
    _vatExemptEnabled = provider.getTaxSetting('vatExemptEnabled') ?? true;
  }

  @override
  void dispose() {
    _vatRateController.dispose();
    _tinController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveTaxSettings() async {
    final provider = context.read<TransactionProvider>();
    final vatRate = double.tryParse(_vatRateController.text) ?? 12.0;

    await provider.updateTaxSettings({
      'vatRate': vatRate,
      'enableVAT': _enableVAT,
      'taxInclusive': _taxInclusive,
      'businessTIN': _tinController.text,
      'businessName': _businessNameController.text,
      'businessAddress': _businessAddressController.text,
      'zeroRatedEnabled': _zeroRatedEnabled,
      'vatExemptEnabled': _vatExemptEnabled,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tax Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VAT Enable Toggle
                    SwitchListTile(
                      title: const Text('Enable VAT'),
                      subtitle: const Text('Apply VAT to transactions'),
                      value: _enableVAT,
                      onChanged: (value) => setState(() => _enableVAT = value),
                    ),
                    const SizedBox(height: 16),

                    // VAT Rate
                    TextField(
                      controller: _vatRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'VAT Rate (%)',
                        helperText: 'Default: 12% for Philippines',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _enableVAT,
                    ),
                    const SizedBox(height: 16),

                    // Tax Inclusive Toggle
                    SwitchListTile(
                      title: const Text('Tax-Inclusive Pricing'),
                      subtitle: const Text('Prices already include VAT'),
                      value: _taxInclusive,
                      onChanged: _enableVAT
                          ? (value) => setState(() => _taxInclusive = value)
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Zero-Rated Toggle
                    SwitchListTile(
                      title: const Text('Allow Zero-Rated Transactions'),
                      subtitle: const Text('0% VAT transactions'),
                      value: _zeroRatedEnabled,
                      onChanged: _enableVAT
                          ? (value) =>
                              setState(() => _zeroRatedEnabled = value)
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // VAT Exempt Toggle
                    SwitchListTile(
                      title: const Text('Allow VAT-Exempt Transactions'),
                      subtitle: const Text('Exempt from VAT'),
                      value: _vatExemptEnabled,
                      onChanged: _enableVAT
                          ? (value) =>
                              setState(() => _vatExemptEnabled = value)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Business Information Section
                    Text(
                      'Business Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _tinController,
                      decoration: const InputDecoration(
                        labelText: 'TIN Number',
                        helperText: 'Tax Identification Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _businessAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveTaxSettings,
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
