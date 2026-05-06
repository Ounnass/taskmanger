import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/gradient_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/user_form_dialog.dart';
import 'settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _sectionIndex = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    final taskProvider = context.read<TaskProvider>();
    Future.microtask(() async {
      await userProvider.loadUsers();
      await taskProvider.loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user?.isAdmin != true) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Access denied',
          message: 'Admin role is required.',
        ),
      );
    }

    return Scaffold(
      drawer: _AdminMenuDrawer(
        currentUser: user,
        selectedIndex: _sectionIndex,
        onSelectSection: (index) {
          Navigator.pop(context);
          setState(() => _sectionIndex = index);
        },
      ),
      appBar: AppBar(
        title: Text(
          switch (_sectionIndex) {
            0 => 'Admin dashboard',
            1 => 'Users',
            2 => 'Tasks',
            _ => 'Settings',
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await context.read<UserProvider>().loadUsers();
              if (context.mounted) {
                await context.read<TaskProvider>().loadTasks();
              }
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sectionIndex,
        onDestinationSelected: (index) {
          setState(() => _sectionIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<UserProvider>().loadUsers();
          if (context.mounted) await context.read<TaskProvider>().loadTasks();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_sectionIndex) {
            0 => const _AdminOverview(key: ValueKey('overview')),
            1 => const _UsersManagement(key: ValueKey('users')),
            2 => const _TasksManagement(key: ValueKey('tasks')),
            _ => const SettingsContent(key: ValueKey('settings')),
          },
        ),
      ),
    );
  }
}

class _AdminMenuDrawer extends StatelessWidget {
  const _AdminMenuDrawer({
    required this.currentUser,
    required this.selectedIndex,
    required this.onSelectSection,
  });

  final AppUser? currentUser;
  final int selectedIndex;
  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelectSection,
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
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.name ?? 'Admin',
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
          icon: Icon(Icons.dashboard_outlined),
          label: Text('Overview'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.people_outline),
          label: Text('Users'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.task_alt),
          label: Text('Tasks'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('Settings'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person_add_alt),
          title: const Text('Ajouter user'),
          onTap: () {
            Navigator.pop(context);
            onSelectSection(1);
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_task),
          title: const Text('Ajouter task'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.addTask),
        ),
        ListTile(
          leading: const Icon(Icons.people_alt_outlined),
          title: const Text('Users screen'),
          onTap: () => Navigator.pushNamed(context, AppRoutes.users),
        ),
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const Text('User home'),
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Refresh data'),
          onTap: () async {
            Navigator.pop(context);
            await context.read<UserProvider>().loadUsers();
            if (context.mounted) {
              await context.read<TaskProvider>().loadTasks();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            final confirmed = await showConfirmActionDialog(
              context: context,
              title: 'Logout?',
              message: 'Confirm logout from the admin session.',
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

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final tasks = context.watch<TaskProvider>();
    final completion = tasks.totalTasks == 0 ? 0.0 : tasks.doneCount / tasks.totalTasks;
    final pending = tasks.todoCount;
    final inProgress = tasks.progressCount;
    final completed = tasks.doneCount;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const GradientHeader(
          title: 'Full control',
          subtitle: 'Manage users, tasks and global progress',
          icon: Icons.admin_panel_settings,
        ),
        const SizedBox(height: 16),
        AnalyticsStatGrid(
          users: users.users.length,
          tasks: tasks.totalTasks,
          pending: pending,
          inProgress: inProgress,
          completed: completed,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatCard(label: 'Users', value: users.users.length, icon: Icons.people),
            const SizedBox(width: 8),
            StatCard(label: 'Tasks', value: tasks.totalTasks, icon: Icons.task_alt),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            StatCard(label: 'Pending', value: tasks.todoCount, icon: Icons.pending_actions),
            const SizedBox(width: 8),
            StatCard(label: 'Done', value: tasks.doneCount, icon: Icons.done_all),
          ],
        ),
        const SizedBox(height: 12),
        StatusDonutChart(
          users: users.users.length,
          totalTasks: tasks.totalTasks,
          pending: pending,
          inProgress: inProgress,
          completed: completed,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProgressRing(
                value: completion,
                label: 'Global completion',
                center: '${(completion * 100).round()}%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MiniLineChart(
                labels: const ['Users', 'Tasks', 'Pend', 'Prog', 'Done'],
                values: [
                  users.users.length,
                  tasks.totalTasks,
                  pending,
                  inProgress,
                  completed,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersManagement extends StatelessWidget {
  const _UsersManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: context.read<UserProvider>().setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search users',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add user',
              onPressed: () => _showUserDialog(context),
              icon: const Icon(Icons.person_add_alt),
            ),
          ],
        ),
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 12),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.filteredUsers.isEmpty)
          const SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.people_outline,
              title: 'No users',
              message: 'No user matches your search.',
            ),
          )
        else
          ...provider.filteredUsers.map(
            (user) => Card(
              child: ListTile(
                leading: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                ),
                title: Text(user.name),
                subtitle: Text('ID ${user.id ?? '-'} - ${user.email}'),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.userDetail,
                  arguments: user.id,
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    Chip(label: Text(user.role)),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _showUserDialog(context, user: user),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteUser(context, user),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showUserDialog(BuildContext context, {AppUser? user}) async {
    final result = await showDialog<AppUser>(
      context: context,
      builder: (_) => UserFormDialog(initialUser: user),
    );
    if (result == null || !context.mounted) return;
    if (user == null) {
      await context.read<UserProvider>().addUser(result);
    } else {
      await context.read<UserProvider>().updateUser(result);
    }
  }

  Future<void> _deleteUser(BuildContext context, AppUser user) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Delete user?',
      message: 'Delete ${user.name} from MockAPI?',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline,
    );
    if (confirmed && context.mounted) {
      await context.read<UserProvider>().deleteUser(user);
    }
  }
}

class _TasksManagement extends StatelessWidget {
  const _TasksManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final users = context.watch<UserProvider>().users;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final visibleTasks = tasks.paginatedTasksFor(currentUser, users: users);
    final filteredTasks = tasks.filteredTasksFor(currentUser, users: users);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: context.read<TaskProvider>().setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search by title or user',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add task',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
              icon: const Icon(Icons.add_task),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilterChipsBar(
          activeFilter: tasks.activeFilter,
          onSelected: context.read<TaskProvider>().setFilter,
        ),
        if (tasks.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(tasks.errorMessage!, style: const TextStyle(color: Colors.orange)),
        ],
        const SizedBox(height: 12),
        if (tasks.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (visibleTasks.isEmpty)
          const SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.task_outlined,
              title: 'No tasks',
              message: 'No task matches your search.',
            ),
          )
        else
          ...visibleTasks.map(
            (task) => _AdminTaskTile(
              task: task,
              owner: _ownerName(users, task.userId),
            ),
          ),
        if (filteredTasks.length > tasks.pageSize)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: tasks.currentPage == 1
                    ? null
                    : context.read<TaskProvider>().previousPage,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Page ${tasks.currentPage}/${tasks.totalPagesFor(currentUser, users: users)}',
              ),
              IconButton(
                onPressed: tasks.currentPage >=
                        tasks.totalPagesFor(currentUser, users: users)
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

  String _ownerName(List<AppUser> users, String userId) {
    for (final user in users) {
      if (user.id == userId) return user.name;
    }
    return 'User $userId';
  }
}

class _AdminTaskTile extends StatelessWidget {
  const _AdminTaskTile({required this.task, required this.owner});

  final Task task;
  final String owner;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TaskTile(
          task: task,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.taskDetail,
            arguments: task.id,
          ),
        ),
        Positioned(
          right: 48,
          top: 10,
          child: Chip(label: Text(owner)),
        ),
      ],
    );
  }
}
