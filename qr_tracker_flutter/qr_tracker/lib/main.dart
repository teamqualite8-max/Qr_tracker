// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/scan_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode for industrial handheld use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const QrTrackerApp());
}

class QrTrackerApp extends StatelessWidget {
  const QrTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Part Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    ScanScreen(),
    VerifyScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Verify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
