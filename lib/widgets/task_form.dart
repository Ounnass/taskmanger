import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import 'confirm_action_dialog.dart';

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    this.initialTask,
    required this.userId,
    this.availableUsers = const [],
    required this.onSubmit,
  });

  final Task? initialTask;
  final String userId;
  final List<AppUser> availableUsers;
  final Future<void> Function(Task task) onSubmit;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late String _status;
  late String _selectedUserId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _date = DateTime.tryParse(task?.date ?? '') ?? DateTime.now();
    _status = task?.status ?? 'pending';
    _selectedUserId = task?.userId ?? widget.userId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Titre obligatoire' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.notes),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Description obligatoire'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Statut',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
              DropdownMenuItem(value: 'done', child: Text('Terminee')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'pending'),
          ),
          if (widget.availableUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Utilisateur',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: widget.availableUsers
                  .map(
                    (user) => DropdownMenuItem(
                      value: user.id ?? widget.userId,
                      child: Text('${user.name} (${user.role})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedUserId = value);
              },
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: const Text('Date'),
            subtitle: Text(_date.toIso8601String().substring(0, 10)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final task = Task(
      id: widget.initialTask?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _date.toIso8601String().substring(0, 10),
      userId: _selectedUserId,
      status: _status,
      isSynced: widget.initialTask?.isSynced ?? false,
    );
    final isUpdate = widget.initialTask != null;
    final confirmed = await showConfirmActionDialog(
      context: context,
      title: isUpdate ? 'Update task?' : 'Create task?',
      message: isUpdate
          ? 'Confirm updating "${task.title}" with the new values.'
          : 'Confirm creating "${task.title}" and assigning it to user ${task.userId}.',
      confirmLabel: isUpdate ? 'Update' : 'Create',
      icon: isUpdate ? Icons.edit_outlined : Icons.add_task,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isSaving = true);
    await widget.onSubmit(task);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }
}
