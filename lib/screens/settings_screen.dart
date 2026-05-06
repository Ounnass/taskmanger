import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/gradient_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: const SettingsContent(),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final users = context.watch<UserProvider>();
    final user = auth.currentUser;
    final completed = tasks.doneCountFor(user);
    final total = tasks.totalTasksFor(user);
    final pending = tasks.pendingCountFor(user);
    final inProgress = tasks.progressCountFor(user);
    final progress = total == 0 ? 0.0 : completed / total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const GradientHeader(
          title: 'Workspace settings',
          subtitle: 'Session, sync and account preferences',
          icon: Icons.settings,
        ),
        const SizedBox(height: 16),
        AnalyticsStatGrid(
          users: users.users.length,
          tasks: total,
          pending: pending,
          inProgress: inProgress,
          completed: completed,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProgressRing(
                value: progress,
                label: 'Completion',
                center: '${(progress * 100).round()}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick stats', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _MetricLine(label: 'Total tasks', value: total),
                      _MetricLine(label: 'Pending', value: pending),
                      _MetricLine(label: 'En cours', value: inProgress),
                      _MetricLine(label: 'Completed', value: completed),
                      _MetricLine(label: 'Users loaded', value: users.users.length),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatusDonutChart(
          users: users.users.length,
          totalTasks: total,
          pending: pending,
          inProgress: inProgress,
          completed: completed,
        ),
        const SizedBox(height: 12),
        MiniLineChart(
          labels: const ['All', 'Pend', 'Prog', 'Done'],
          values: [total, pending, inProgress, completed],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user?.name ?? 'Guest'),
                subtitle: Text('${user?.email ?? '-'} - ${user?.role ?? 'none'}'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(tasks.isOnline ? Icons.cloud_done : Icons.cloud_off),
                title: Text(tasks.isOnline ? 'Online sync' : 'Offline mode'),
                subtitle: Text('${tasks.totalTasks} local tasks cached'),
                trailing: IconButton(
                  tooltip: 'Sync now',
                  onPressed: () => context.read<TaskProvider>().loadTasks(),
                  icon: const Icon(Icons.sync),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: themeProvider.isDarkMode,
                onChanged: context.read<ThemeProvider>().setDarkMode,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? 'Dark theme enabled'
                      : 'Light theme enabled',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Local database'),
                subtitle: const Text('SQFlite cache with isSynced flag'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Loaded users'),
                subtitle: Text('${users.users.length} users available'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                subtitle: const Text('Open role based start screen'),
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  user?.isAdmin == true ? AppRoutes.adminDashboard : AppRoutes.home,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  final confirmed = await showConfirmActionDialog(
                    context: context,
                    title: 'Logout?',
                    message: 'Confirm logout from the current session.',
                    confirmLabel: 'Logout',
                    icon: Icons.logout,
                  );
                  if (!confirmed || !context.mounted) return;
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
