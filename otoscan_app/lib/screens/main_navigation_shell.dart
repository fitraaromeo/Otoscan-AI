import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'user_management_screen.dart';
import 'vehicle_management_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final GlobalKey<UserManagementScreenState> _userScreenKey =
      GlobalKey<UserManagementScreenState>();
  final GlobalKey<VehicleManagementScreenState> _vehicleScreenKey =
      GlobalKey<VehicleManagementScreenState>();

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkCard2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 10),
            Text('Confirm Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of OtoScan AI?',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context);
    final isAdmin = appState.isAdmin;

    // Dynamically build navigation items and pages based on user role
    final List<NavItemData> navItems = [
      NavItemData(label: 'Inspection', iconPath: 'assets/icons/inspect.png'),
      if (isAdmin) NavItemData(label: 'Client', iconPath: 'assets/icons/user.png'),
      NavItemData(label: 'Vehicle', iconPath: 'assets/icons/car.png'),
      if (!isAdmin) NavItemData(label: 'Profile', iconData: Icons.person_rounded),
    ];

    final List<Widget> pages = [
      const DashboardScreen(),
      if (isAdmin) UserManagementScreen(key: _userScreenKey),
      VehicleManagementScreen(key: _vehicleScreenKey),
      if (!isAdmin) const ProfileScreen(),
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 4,
            top: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131924) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 80 : 25),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(navItems.length, (index) {
              final isSelected = index == _currentIndex;
              final item = navItems[index];

              final Color iconColor = isSelected
                  ? (isDark ? const Color(0xFF1E2430) : Colors.white)
                  : (isDark
                      ? Colors.white.withAlpha(220)
                      : const Color(0xFF374151));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (isAdmin && index == 1) {
                    _userScreenKey.currentState?.refreshData();
                  } else if ((isAdmin && index == 2) || (!isAdmin && index == 1)) {
                    _vehicleScreenKey.currentState?.refreshData();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: isSelected
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                      : const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1E2430))
                        : (isDark
                            ? Colors.white.withAlpha(12)
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.iconPath != null)
                        Image.asset(
                          item.iconPath!,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          colorBlendMode: BlendMode.srcIn,
                          color: iconColor,
                        )
                      else if (item.iconData != null)
                        Icon(
                          item.iconData,
                          size: 20,
                          color: iconColor,
                        ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF1E2430)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class NavItemData {
  final String label;
  final String? iconPath;
  final IconData? iconData;

  NavItemData({required this.label, this.iconPath, this.iconData});
}

