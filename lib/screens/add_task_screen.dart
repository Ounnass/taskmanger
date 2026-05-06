import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_form.dart';

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = auth.currentUser;
    final userId = currentUser?.id ?? '1';
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une tache')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: currentUser?.isAdmin != true
          ? const EmptyState(
              icon: Icons.lock_outline,
              title: 'Access denied',
              message: 'Only admins can create tasks.',
            )
          : TaskForm(
              userId: userId,
              availableUsers: userProvider.users,
              onSubmit: (Task task) => context.read<TaskProvider>().addTask(task),
            ),
    );
  }
}
