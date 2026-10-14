import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_nav_bar.dart';

class DashboardShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final roleLabel =
        user?.role == 'Manager' ? 'Manager' : 'Field Worker';

    return Scaffold(
      appBar: AppNavBar(
        title: 'Geoterra Monitoring',
        userName: user?.name ?? 'User',
        userRole: roleLabel,
        onLogout: () => context.read<AuthProvider>().logout(),
        sections: const ['Dashboard', 'Offering', 'Tools', 'Workers'],
        currentIndex: navigationShell.currentIndex,
        onSectionSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
      body: navigationShell,
    );
  }
}
