import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
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

  final List<NavItemData> _navItems = [
    NavItemData(label: 'Inspection', iconPath: 'assets/icons/inspect.png'),
    NavItemData(label: 'Client', iconPath: 'assets/icons/user.png'),
    NavItemData(label: 'Vehicle', iconPath: 'assets/icons/car.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      const DashboardScreen(),
      UserManagementScreen(key: _userScreenKey),
      VehicleManagementScreen(key: _vehicleScreenKey),
    ];

    return Scaffold(
      extendBody:
          true, // Allows body content to extend seamlessly behind floating navbar
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          margin: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 4,
            top: 2,
          ), // Lowered position
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
            children: List.generate(_navItems.length, (index) {
              final isSelected = index == _currentIndex;
              final item = _navItems[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (index == 1) {
                    _userScreenKey.currentState?.refreshData();
                  } else if (index == 2) {
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
