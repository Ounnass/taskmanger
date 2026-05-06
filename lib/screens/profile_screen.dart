import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/confirm_action_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: const ProfileContent(),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                    child: Text(
                      (user?.name.isNotEmpty == true ? user!.name[0] : 'U')
                          .toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Utilisateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'test@gmail.com',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle('Account'),
          _SectionCard(
            children: [
              _ProfileRow(
                icon: Icons.manage_accounts_outlined,
                title: 'Manage Profile',
                value: user?.role ?? 'user',
                onTap: () {},
              ),
              _ProfileRow(
                icon: Icons.badge_outlined,
                title: 'User ID',
                value: user?.id ?? '1',
              ),
              _ProfileRow(
                icon: Icons.lock_outline,
                title: 'Password & Security',
                value: 'Protected',
                onTap: () {},
              ),
              _ProfileRow(
                icon: Icons.notifications_none,
                title: 'Notifications',
                value: tasks.isOnline ? 'Online' : 'Offline',
                onTap: () => context.read<TaskProvider>().loadTasks(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('Task Statistics'),
          _SectionCard(
            children: [
              _ProfileRow(
                icon: Icons.list_alt,
                title: 'Total tasks',
                value: '${tasks.totalTasksFor(user)}',
              ),
              _ProfileRow(
                icon: Icons.pending_actions,
                title: 'Pending',
                value: '${tasks.pendingCountFor(user)}',
              ),
              _ProfileRow(
                icon: Icons.timelapse,
                title: 'En cours',
                value: '${tasks.progressCountFor(user)}',
              ),
              _ProfileRow(
                icon: Icons.done_all,
                title: 'Terminer',
                value: '${tasks.doneCountFor(user)}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('Preferences'),
          _SectionCard(
            children: [
              _ProfileRow(
                icon: Icons.info_outline,
                title: 'About Us',
                value: 'Task Manager',
                onTap: () {},
              ),
              _ProfileRow(
                icon: Icons.contrast,
                title: 'Theme',
                value: theme.isDarkMode ? 'Dark' : 'Light',
                onTap: () => context.read<ThemeProvider>().setDarkMode(
                      !theme.isDarkMode,
                    ),
              ),
              _ProfileRow(
                icon: Icons.language,
                title: 'Language',
                value: 'English',
                onTap: () {},
              ),
            ],
          ),
          if (isAdmin) ...[
            const SizedBox(height: 18),
            _SectionTitle('Admin'),
            _SectionCard(
              children: [
                _ProfileRow(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin dashboard',
                  value: 'Open',
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.adminDashboard,
                  ),
                ),
                _ProfileRow(
                  icon: Icons.people_outline,
                  title: 'Users management',
                  value: '${auth.users.length}',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.users),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _SectionTitle('Support'),
          _SectionCard(
            children: [
              _ProfileRow(
                icon: Icons.help_outline,
                title: 'Help Center',
                value: 'FAQ',
                onTap: () {},
              ),
              _ProfileRow(
                icon: Icons.phone_outlined,
                title: 'Contact Us',
                value: 'Support',
                onTap: () {},
              ),
              _ProfileRow(
                icon: Icons.logout,
                title: 'Logout',
                value: '',
                isDanger: true,
                onTap: () => _logout(context, auth),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Logout?',
      message: 'Confirm logout from the current session.',
      confirmLabel: 'Logout',
      icon: Icons.logout,
    );
    if (!confirmed || !context.mounted) return;
    await auth.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 58),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                color: isDanger
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),
          if (onTap != null) Icon(Icons.arrow_forward, size: 18, color: color),
        ],
      ),
    );
  }
}
