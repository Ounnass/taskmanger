import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/user_form_dialog.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isAdmin == true;
    final userId = ModalRoute.of(context)?.settings.arguments as String?;
    final user = userId == null ? null : context.watch<UserProvider>().findById(userId);

    if (!isAdmin || user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'User not found',
          message: 'The user does not exist or access is denied.',
        ),
      );
    }

    final taskProvider = context.watch<TaskProvider>();
    final userTasks = taskProvider.tasks.where((task) => task.userId == user.id).toList();
    final pendingCount = userTasks.where((task) => task.isPending).length;
    final completedCount = userTasks.where((task) => task.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User details'),
        actions: [
          IconButton(
            tooltip: 'Edit user',
            onPressed: () => _editUser(context, user),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete user',
            onPressed: () => _deleteUser(context, user),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTask),
        icon: const Icon(Icons.add_task),
        label: const Text('Assign task'),
      ),
      body: RefreshIndicator(
        onRefresh: context.read<TaskProvider>().loadTasks,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            GradientHeader(
              title: user.name,
              subtitle: '${user.email} - ${user.role}',
              icon: user.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('ID ${user.id ?? '-'}')),
                Chip(label: Text('Role ${user.role}')),
                Chip(label: Text('Password ${user.password}')),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                StatCard(label: 'Tasks', value: userTasks.length, icon: Icons.task_alt),
                const SizedBox(width: 8),
                StatCard(label: 'Pending', value: pendingCount, icon: Icons.pending_actions),
                const SizedBox(width: 8),
                StatCard(label: 'Done', value: completedCount, icon: Icons.done_all),
              ],
            ),
            const SizedBox(height: 18),
            Text('User tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (userTasks.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyState(
                  icon: Icons.task_outlined,
                  title: 'No tasks',
                  message: 'This user has no assigned tasks yet.',
                ),
              )
            else
              ...userTasks.map(
                (task) => TaskTile(
                  task: task,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.taskDetail,
                    arguments: task.id,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editUser(BuildContext context, AppUser user) async {
    final result = await showDialog<AppUser>(
      context: context,
      builder: (_) => UserFormDialog(initialUser: user),
    );
    if (result != null && context.mounted) {
      await context.read<UserProvider>().updateUser(result);
    }
  }

  Future<void> _deleteUser(BuildContext context, AppUser user) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Delete user?',
      message: 'Delete ${user.name}?',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<UserProvider>().deleteUser(user);
    if (context.mounted) Navigator.pop(context);
  }
}
