import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
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

  void _handleLogout() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    ];

    final List<Widget> pages = [
      const DashboardScreen(),
      if (isAdmin) UserManagementScreen(key: _userScreenKey),
      VehicleManagementScreen(key: _vehicleScreenKey),
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'OtoScan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Role & Profile Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.accent.withAlpha(30)
                  : AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAdmin
                    ? AppColors.accent.withAlpha(100)
                    : AppColors.primary.withAlpha(100),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 14,
                  color: isAdmin ? AppColors.accent : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  appState.userDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isAdmin ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    appState.userRoleBadge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.darkStatusFailed, size: 20),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.darkSurfaceCard,
                  title: const Text('Konfirmasi Logout', style: TextStyle(color: Colors.white)),
                  content: const Text('Apakah Anda yakin ingin keluar dari sistem?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkStatusFailed,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 4,
            top: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                      : const EdgeInsets.all(12),
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
                      Image.asset(
                        item.iconPath,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        colorBlendMode: BlendMode.srcIn,
                        color: isSelected
                            ? (isDark ? const Color(0xFF1E2430) : Colors.white)
                            : (isDark
                                  ? Colors.white.withAlpha(220)
                                  : const Color(0xFF374151)),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF1E2430)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
  final String iconPath;

  NavItemData({required this.label, required this.iconPath});
}
