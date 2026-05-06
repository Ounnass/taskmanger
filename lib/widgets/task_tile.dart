import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _statusColor(context).withValues(alpha: 0.16),
                    child: Icon(_statusIcon, color: _statusColor(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    task.isSynced
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: task.isSynced ? colorScheme.primary : colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniChip(
                    icon: Icons.flag_outlined,
                    label: _statusLabel(task.status),
                    color: _statusColor(context),
                  ),
                  _MiniChip(
                    icon: Icons.calendar_month,
                    label: task.date,
                    color: colorScheme.primary,
                  ),
                  _MiniChip(
                    icon: Icons.person_outline,
                    label: 'User ${task.userId}',
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _statusIcon {
    switch (task.status) {
      case 'done':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.timelapse;
      case 'pending':
        return Icons.pending_actions;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Terminee';
      case 'in_progress':
        return 'En cours';
      case 'pending':
        return 'Pending';
      default:
        return 'A faire';
    }
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
