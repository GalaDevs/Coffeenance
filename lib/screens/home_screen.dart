import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/revenue_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/transaction_modal.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/user_profile.dart';

/// Home Screen with Bottom Navigation
/// Matches page.tsx with BottomNav component
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Initialize NotificationProvider to start listening for realtime updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🏠 HomeScreen: Initializing notification provider...');
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.initialize();
      print('🏠 HomeScreen: Notification provider initialized');
      
      // Show announcement popups if any
      if (mounted) {
        print('🏠 HomeScreen: Checking for announcements to show...');
        await notificationProvider.showAnnouncementPopups(context);
        print('🏠 HomeScreen: Announcement check complete');
        
        // Set callback for new announcements
        print('🏠 HomeScreen: Setting up realtime announcement callback');
        notificationProvider.setAnnouncementCallback((announcement) async {
          print('🔥 REALTIME: New announcement received: ${announcement.title}');
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Text(
                    announcement.message,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed: () async {
                      await notificationProvider.markAsRead(announcement.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          }
        });
      }
    });
  }

  List<Widget> _getScreensForRole(UserRole? role) {
    if (role == UserRole.staff) {
      // Staff sees Dashboard, Revenue, and Expenses (no Settings)
      return const [
        DashboardScreen(),
        RevenueScreen(),
        TransactionsScreen(),
      ];
    } else if (role == UserRole.manager) {
      // Manager sees all except Settings
      return const [
        DashboardScreen(),
        RevenueScreen(),
        TransactionsScreen(),
      ];
    }
    // Admin and Developer see all screens including Settings
    return const [
      DashboardScreen(),
      RevenueScreen(),
      TransactionsScreen(),
      SettingsScreen(),
    ];
  }

  List<_NavItem> _getNavItemsForRole(UserRole? role) {
    if (role == UserRole.staff) {
      // Staff has Dashboard, Revenue, Expenses, and Logout
      return const [
        _NavItem(icon: Icons.dashboard_customize_rounded, label: 'Dashboard'),
        _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Revenue'),
        _NavItem(icon: Icons.swap_horiz_rounded, label: 'Expenses'),
        _NavItem(icon: Icons.logout_rounded, label: 'Logout', isLogout: true),
      ];
    } else if (role == UserRole.manager) {
      // Manager has Dashboard, Revenue, Expenses, and Logout
      return const [
        _NavItem(icon: Icons.dashboard_customize_rounded, label: 'Dashboard'),
        _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Revenue'),
        _NavItem(icon: Icons.swap_horiz_rounded, label: 'Expenses'),
        _NavItem(icon: Icons.logout_rounded, label: 'Logout', isLogout: true),
      ];
    }
    // Admin and Developer have all tabs including Settings
    return const [
      _NavItem(icon: Icons.dashboard_customize_rounded, label: 'Dashboard'),
      _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Revenue'),
      _NavItem(icon: Icons.swap_horiz_rounded, label: 'Expenses'),
      _NavItem(icon: Icons.tune_rounded, label: 'Settings'),
    ];
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _showTransactionModal() {
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    // Determine initial type based on current screen
    TransactionType? initialType;
    if (_currentIndex == 1) {
      // Revenue screen
      initialType = TransactionType.revenue;
    } else if (_currentIndex == 2) {
      // Expenses screen
      initialType = TransactionType.transaction;
    }
    
    TransactionModal.show(context, initialType: initialType);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final userRole = authProvider.userRole;
    
    final screens = _getScreensForRole(userRole);
    final navItems = _getNavItemsForRole(userRole);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Offline mode banner
            if (!transactionProvider.isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transactionProvider.pendingSyncCount > 0
                            ? 'Offline - ${transactionProvider.pendingSyncCount} item${transactionProvider.pendingSyncCount > 1 ? 's' : ''} pending'
                            : 'Offline - Data saved locally',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (transactionProvider.isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            // Sync success banner
            if (transactionProvider.isOnline && transactionProvider.pendingSyncCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transactionProvider.isSyncing
                            ? 'Syncing ${transactionProvider.pendingSyncCount} item${transactionProvider.pendingSyncCount > 1 ? 's' : ''}...'
                            : '${transactionProvider.pendingSyncCount} item${transactionProvider.pendingSyncCount > 1 ? 's' : ''} waiting to sync',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (transactionProvider.isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => transactionProvider.syncPendingTransactions(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text(
                          'Sync Now',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24), // Fixed position from bottom
        child: ScaleTransition(
          scale: _fabScaleAnimation,
          child: SizedBox(
            width: 56, // w-14 (56px)
            height: 56, // h-14 (56px)
            child: FloatingActionButton(
              onPressed: _showTransactionModal,
              elevation: 8,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(
                Icons.add,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        height: 80, // Fixed height matching Next.js h-20 (80px)
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              return _buildNavItem(index, theme, navItems);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme, List<_NavItem> navItems) {
    final navItem = navItems[index];
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: navItem.isLogout ? _handleLogout : () => _onTabChanged(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(
          minWidth: 70, // Increased width to accommodate longer text
          maxWidth: 85,
        ),
        height: 56, // h-14 (56px)
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              navItem.icon,
              size: 24,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2), // mb-1
            Text(
              navItem.label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9, // Slightly smaller to fit better
                fontWeight: FontWeight.w500, // font-medium
                letterSpacing: -0.2, // Tighter letter spacing
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isLogout;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isLogout = false,
  });
}
