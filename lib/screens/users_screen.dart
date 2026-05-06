import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_header.dart';
import '../widgets/user_form_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProvider>();
    Future.microtask(provider.loadUsers);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<UserProvider>();

    if (auth.currentUser?.isAdmin != true) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Access denied',
          message: 'Only admins can view users.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add user'),
      ),
      body: RefreshIndicator(
        onRefresh: context.read<UserProvider>().loadUsers,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            const GradientHeader(
              title: 'Users directory',
              subtitle: 'Search, inspect and manage accounts',
              icon: Icons.people_alt_outlined,
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: context.read<UserProvider>().setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search by name, email or role',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.filteredUsers.isEmpty)
              const SizedBox(
                height: 320,
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'No users',
                  message: 'No user matches your search.',
                ),
              )
            else
              ...provider.filteredUsers.map(
                (user) => _UserCard(
                  user: user,
                  onOpen: () => Navigator.pushNamed(
                    context,
                    AppRoutes.userDetail,
                    arguments: user.id,
                  ),
                  onEdit: () => _showUserDialog(context, user: user),
                  onDelete: () => _deleteUser(context, user),
                ),
              ),
          ],
        ),
      ),
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
      message: 'Delete ${user.name}?',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline,
    );
    if (confirmed && context.mounted) {
      await context.read<UserProvider>().deleteUser(user);
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUser user;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('ID ${user.id ?? '-'}')),
                        Chip(label: Text(user.role)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
