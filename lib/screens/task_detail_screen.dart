import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_header.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskId = ModalRoute.of(context)?.settings.arguments as String?;
    final task = taskId == null ? null : context.watch<TaskProvider>().findById(taskId);
    final authUser = context.watch<AuthProvider>().currentUser;
    final isAdmin = authUser?.isAdmin ?? false;
    final isOwner = task?.userId == authUser?.id;
    final canReadTask = task != null && (isAdmin || task.userId == authUser?.id);

    if (task == null || !canReadTask) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.search_off,
          title: 'Task not found',
          message: 'This task does not exist or access is denied.',
        ),
      );
    }

    final owner = context.watch<UserProvider>().findById(task.userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Edit task',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.editTask,
                arguments: task.id,
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete task',
              onPressed: () => _confirmDelete(context, task),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: isAdmin ? 2 : 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientHeader(
            title: task.title,
            subtitle: owner == null
                ? 'Assigned to user ${task.userId}'
                : 'Assigned to ${owner.name}',
            icon: _statusIcon(task),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.tag, label: 'Task ID ${task.id ?? 'local'}'),
              _InfoChip(icon: Icons.person_outline, label: 'User ID ${task.userId}'),
              _InfoChip(icon: Icons.flag_outlined, label: _statusLabel(task.status)),
              _InfoChip(icon: Icons.calendar_month, label: task.date),
              _InfoChip(
                icon: task.isSynced ? Icons.cloud_done : Icons.cloud_off,
                label: task.isSynced ? 'Synced' : 'Local only',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(task.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  title: 'Owner',
                  value: owner == null ? 'Unknown user' : '${owner.name} (${owner.email})',
                  onTap: isAdmin && owner?.id != null
                      ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.userDetail,
                            arguments: owner!.id,
                          )
                      : null,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.sync_alt,
                  title: 'Sync status',
                  value: task.isSynced
                      ? 'Saved on API and local cache'
                      : 'Waiting for next online sync',
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.history,
                  title: 'History',
                  value: task.isCompleted
                      ? 'Completed task, visible in history'
                      : 'Active task, not archived yet',
                ),
              ],
            ),
          ),
          if (isOwner && !isAdmin) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choisir le statut',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: task.status == 'in_progress'
                                ? null
                                : () => _changeStatus(
                                      context,
                                      task,
                                      'in_progress',
                                      'En cours',
                                    ),
                            icon: const Icon(Icons.timelapse),
                            label: const Text('En cours'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: task.isCompleted
                                ? null
                                : () => _changeStatus(
                                      context,
                                      task,
                                      'completed',
                                      'Completed',
                                    ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Completed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.editTask,
                      arguments: task.id,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, task),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Delete task?',
      message: 'Delete "${task.title}" locally and from API if online?',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<TaskProvider>().deleteTask(task);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _changeStatus(
    BuildContext context,
    Task task,
    String status,
    String label,
  ) async {
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: 'Changer statut?',
      message: 'Confirmer le changement de "${task.title}" vers $label.',
      confirmLabel: 'Update',
      icon: Icons.flag_outlined,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<TaskProvider>().updateTask(task.copyWith(status: status));
  }

  IconData _statusIcon(Task task) {
    if (task.isCompleted) return Icons.check_circle_outline;
    if (task.status == 'in_progress') return Icons.timelapse;
    return Icons.pending_actions;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
      case 'done':
        return 'Completed';
      case 'in_progress':
        return 'In progress';
      case 'pending':
      case 'todo':
        return 'Pending';
      default:
        return status;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
