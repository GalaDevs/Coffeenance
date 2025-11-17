import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/revenue_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/transaction_modal.dart';

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

  final List<Widget> _screens = const [
    DashboardScreen(),
    RevenueScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.attach_money_rounded, label: 'Revenue'),
    _NavItem(icon: Icons.trending_down_rounded, label: 'Transactions'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

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

  void _showTransactionModal() {
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    TransactionModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
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
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(index, theme);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme) {
    final navItem = _navItems[index];
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabChanged(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56, // w-14 (56px)
        height: 56, // h-14 (56px)
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
              style: TextStyle(
                fontSize: 10, // text-xs
                fontWeight: FontWeight.w500, // font-medium
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

  const _NavItem({
    required this.icon,
    required this.label,
  });
}
