import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import '../utils/task_filter.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/gradient_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_tile.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final taskProvider = context.read<TaskProvider>();
    Future.microtask(taskProvider.loadTasks);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<TaskProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = auth.currentUser;
    final visibleTasks = provider.paginatedTasksFor(
      currentUser,
      users: userProvider.users,
    );
    final allFilteredTasks = provider.filteredTasksFor(
      currentUser,
      users: userProvider.users,
    );
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      drawer: _UserMenuDrawer(
        currentUser: currentUser,
        selectedIndex: _selectedIndex,
        onSelectTab: (index) {
          Navigator.pop(context);
          setState(() => _selectedIndex = index);
          if (index == 0) provider.setFilter(TaskFilter.all);
          if (index == 1) provider.setFilter(TaskFilter.history);
        },
      ),
      appBar: AppBar(
        title: Text(
          switch (_selectedIndex) {
            0 => 'Mes taches',
            1 => 'Historique',
            2 => 'Profil',
            _ => 'Settings',
          },
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Admin dashboard',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.adminDashboard,
              ),
              icon: const Icon(Icons.admin_panel_settings),
            ),
          IconButton(
            tooltip: 'Synchroniser',
            onPressed: provider.isLoading
                ? null
                : () => context.read<TaskProvider>().loadTasks(),
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Profil',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) provider.setFilter(TaskFilter.all);
          if (index == 1) provider.setFilter(TaskFilter.history);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().loadTasks(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_selectedIndex) {
            0 => _TaskListView(
                key: const ValueKey('tasks'),
                provider: provider,
                currentUser: currentUser,
                users: userProvider.users,
                visibleTasks: visibleTasks,
                allFilteredTasks: allFilteredTasks,
              ),
            1 => _TaskListView(
                key: const ValueKey('history'),
                provider: provider,
                currentUser: currentUser,
                users: userProvider.users,
                visibleTasks: visibleTasks,
                allFilteredTasks: allFilteredTasks,
                forceHistory: true,
              ),
            2 => const ProfileContent(key: ValueKey('profile')),
            _ => const SettingsContent(key: ValueKey('settings')),
          },
        ),
      ),
    );
  }
}

class _UserMenuDrawer extends StatelessWidget {
  const _UserMenuDrawer({
    required this.currentUser,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  final AppUser? currentUser;
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelectTab,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.name ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        currentUser?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.list_alt),
          label: Text('Mes taches'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.history),
          label: Text('Historique'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Profile'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('Settings'),
        ),
        const Divider(),
        if (currentUser?.isAdmin == true)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin dashboard'),
            onTap: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.adminDashboard,
            ),
          ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Synchroniser'),
          onTap: () {
            Navigator.pop(context);
            context.read<TaskProvider>().loadTasks();
          },
        ),
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
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView({
    super.key,
    required this.provider,
    required this.currentUser,
    required this.users,
    required this.visibleTasks,
    required this.allFilteredTasks,
    this.forceHistory = false,
  });

  final TaskProvider provider;
  final AppUser? currentUser;
  final List<AppUser> users;
  final List<Task> visibleTasks;
  final List<Task> allFilteredTasks;
  final bool forceHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        GradientHeader(
          title: forceHistory ? 'History' : 'Task manager',
          subtitle: forceHistory
              ? 'Completed tasks archive'
              : 'Search, filter and sync your tasks',
          icon: forceHistory ? Icons.history : Icons.task_alt,
        ),
        const SizedBox(height: 12),
        _ConnectionBanner(isOnline: provider.isOnline),
        const SizedBox(height: 12),
        Row(
          children: [
            StatCard(
              label: 'Total',
              value: provider.totalTasksFor(currentUser),
              icon: Icons.list_alt,
            ),
            const SizedBox(width: 8),
            StatCard(
              label: 'Pending',
              value: provider.pendingCountFor(currentUser),
              icon: Icons.pending_actions,
            ),
            const SizedBox(width: 8),
            StatCard(
              label: 'Done',
              value: provider.doneCountFor(currentUser),
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!forceHistory)
          FilterChipsBar(
            activeFilter: provider.activeFilter,
            onSelected: context.read<TaskProvider>().setFilter,
          ),
        const SizedBox(height: 12),
        TextField(
          onChanged: context.read<TaskProvider>().setSearchQuery,
          decoration: const InputDecoration(
            hintText: 'Search by title or status',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(provider.errorMessage!, style: const TextStyle(color: Colors.orange)),
        ],
        const SizedBox(height: 12),
        if (provider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (visibleTasks.isEmpty)
          const SizedBox(
            height: 320,
            child: EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No tasks',
              message: 'No task matches the current filters.',
            ),
          )
        else
          ...visibleTasks.asMap().entries.map(
                (entry) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 180 + entry.key * 40),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: TaskTile(
                    task: entry.value,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.taskDetail,
                      arguments: entry.value.id,
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 8),
        if (!forceHistory && allFilteredTasks.length > provider.pageSize)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: provider.currentPage == 1
                    ? null
                    : context.read<TaskProvider>().previousPage,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Page ${provider.currentPage}/${provider.totalPagesFor(currentUser, users: users)}',
              ),
              IconButton(
                onPressed: provider.currentPage >=
                        provider.totalPagesFor(currentUser, users: users)
                    ? null
                    : () => context
                        .read<TaskProvider>()
                        .nextPage(currentUser, users: users),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isOnline ? Icons.wifi : Icons.wifi_off, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOnline
                  ? 'Mode online: donnees synchronisees'
                  : 'Mode offline: cache local actif',
            ),
          ),
        ],
      ),
    );
  }
}
