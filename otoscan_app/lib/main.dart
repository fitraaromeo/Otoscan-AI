import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/main_navigation_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const OtoScanApp(),
    ),
  );
}

class OtoScanApp extends StatelessWidget {
  const OtoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'OtoScan AI - Inspeksi Kendaraan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          home: const MainNavigationShell(),
        );
      },
    );
  }
}
