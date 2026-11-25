import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import 'add_report_screen.dart';
import 'admin_screen.dart';
import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().firebaseUser?.uid;
      if (uid != null) context.read<ReportsProvider>().start(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().appUser?.isAdmin ?? false;
    final pages = <Widget>[
      const MapScreen(),
      const MyReportsScreen(),
      const StatsScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminScreen(),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'الخريطة'),
      const NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'بلاغاتي'),
      const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'إحصائيات'),
      const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
      if (isAdmin)
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'الإدارة'),
    ];
    if (_index >= pages.length) _index = 0;

    return Scaffold(
      body: Stack(children: [
        IndexedStack(index: _index, children: pages),
        const _StatusListener(),
      ]),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddReportScreen()),
              ),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('بلّغ عن مشكلة'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}

class _StatusListener extends StatelessWidget {
  const _StatusListener();

  @override
  Widget build(BuildContext context) {
    final msg = context.watch<ReportsProvider>().takeMessage();
    if (msg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ]),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    return const SizedBox.shrink();
  }
}
