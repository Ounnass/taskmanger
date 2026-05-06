import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_form.dart';

class EditTaskScreen extends StatelessWidget {
  const EditTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskId = ModalRoute.of(context)?.settings.arguments as String?;
    final task = taskId == null ? null : context.watch<TaskProvider>().findById(taskId);
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = auth.currentUser;
    final userId = currentUser?.id ?? '1';
    final canEdit = task != null && currentUser?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la tache')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: task == null || !canEdit
          ? const EmptyState(
              icon: Icons.search_off,
              title: 'Tache introuvable',
              message: 'Retourne a la liste et reessaie.',
            )
          : TaskForm(
              initialTask: task,
              userId: userId,
              availableUsers: userProvider.users,
              onSubmit: (Task updatedTask) =>
                  context.read<TaskProvider>().updateTask(updatedTask),
            ),
    );
  }
}
