import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin == true;
    if (isAdmin) {
      return NavigationBar(
        selectedIndex: currentIndex.clamp(0, 3),
        onDestinationSelected: (index) => _goAdmin(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      );
    }
    return NavigationBar(
      selectedIndex: currentIndex.clamp(0, 3),
      onDestinationSelected: (index) => _goUser(context, index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.list_alt), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }

  void _goAdmin(BuildContext context, int index) {
    if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.settings);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.adminDashboard,
        arguments: index,
      );
    }
  }

  void _goUser(BuildContext context, int index) {
    switch (index) {
      case 0:
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.home, arguments: index);
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.profile);
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.settings);
    }
  }
}
