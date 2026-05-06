import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/task_filter.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required ApiService apiService,
    required DatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService;

  final ApiService _apiService;
  final DatabaseService _databaseService;

  List<Task> _tasks = [];
  bool isLoading = false;
  bool isOnline = false;
  String searchQuery = '';
  TaskFilter activeFilter = TaskFilter.all;
  int currentPage = 1;
  int pageSize = 8;
  String? errorMessage;

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get filteredTasks {
    final query = searchQuery.toLowerCase();
    if (query.isEmpty) return tasks;
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.status.toLowerCase().contains(query);
    }).toList();
  }

  List<Task> visibleTasksFor(AppUser? user) {
    if (user == null || user.isAdmin) return tasks;
    return _tasks.where((task) => task.userId == user.id).toList();
  }

  List<Task> filteredTasksFor(AppUser? user, {List<AppUser> users = const []}) {
    final visibleTasks = visibleTasksFor(user);
    final query = searchQuery.toLowerCase();
    return visibleTasks.where((task) {
      final matchesFilter = switch (activeFilter) {
        TaskFilter.all => true,
        TaskFilter.pending => task.isPending,
        TaskFilter.completed => task.isCompleted,
        TaskFilter.history => task.isCompleted,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final owner = users
          .where((item) => item.id == task.userId)
          .map((item) => item.name)
          .join(' ')
          .toLowerCase();
      return task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.status.toLowerCase().contains(query) ||
          task.userId.toLowerCase().contains(query) ||
          owner.contains(query);
    }).toList();
  }

  List<Task> paginatedTasksFor(AppUser? user, {List<AppUser> users = const []}) {
    final filtered = filteredTasksFor(user, users: users);
    final start = (currentPage - 1) * pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int totalPagesFor(AppUser? user, {List<AppUser> users = const []}) {
    final count = filteredTasksFor(user, users: users).length;
    if (count == 0) return 1;
    return (count / pageSize).ceil();
  }

  int get totalTasks => _tasks.length;
  int get todoCount =>
      _tasks.where((task) => task.status == 'todo' || task.status == 'pending').length;
  int get progressCount =>
      _tasks.where((task) => task.status == 'in_progress').length;
  int get doneCount => _tasks.where((task) => task.isCompleted).length;

  int totalTasksFor(AppUser? user) => visibleTasksFor(user).length;

  int pendingCountFor(AppUser? user) => visibleTasksFor(user)
      .where((task) => task.isPending)
      .length;

  int progressCountFor(AppUser? user) =>
      visibleTasksFor(user).where((task) => task.status == 'in_progress').length;

  int doneCountFor(AppUser? user) =>
      visibleTasksFor(user).where((task) => task.isCompleted).length;

  Task? findById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> loadTasks() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      isOnline = await _apiService.hasConnection();
      if (isOnline) {
        await syncPendingTasks();
        final remoteTasks = await _apiService.getTasks();
        await _databaseService.upsertTasks(remoteTasks);
        _tasks = remoteTasks;
      } else {
        _tasks = await _databaseService.getTasks();
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      _tasks = await _databaseService.getTasks();
      isOnline = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    await _saveTask(task.copyWith(id: 'local_${DateTime.now().microsecondsSinceEpoch}'));
  }

  Future<void> updateTask(Task task) async {
    await _saveTask(task);
  }

  Future<void> deleteTask(Task task) async {
    errorMessage = null;
    try {
      isOnline = await _apiService.hasConnection();
      if (isOnline && task.id != null && !task.id!.startsWith('local_')) {
        await _apiService.deleteTask(task.id!);
      }
      if (task.id != null) {
        await _databaseService.deleteTask(task.id!);
      }
      _tasks.removeWhere((item) => item.id == task.id);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> syncPendingTasks() async {
    final pendingTasks = await _databaseService.getUnsyncedTasks();
    for (final task in pendingTasks) {
      final syncedTask = task.id != null && task.id!.startsWith('local_')
          ? await _apiService.createTask(task)
          : await _apiService.updateTask(task);
      if (task.id != syncedTask.id && task.id != null) {
        await _databaseService.deleteTask(task.id!);
      }
      await _databaseService.upsertTask(syncedTask);
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    currentPage = 1;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    activeFilter = filter;
    currentPage = 1;
    notifyListeners();
  }

  void nextPage(AppUser? user, {List<AppUser> users = const []}) {
    final totalPages = totalPagesFor(user, users: users);
    if (currentPage < totalPages) {
      currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      currentPage--;
      notifyListeners();
    }
  }

  void resetPaging() {
    currentPage = 1;
    notifyListeners();
  }

  Future<void> _saveTask(Task task) async {
    errorMessage = null;
    try {
      isOnline = await _apiService.hasConnection();
      final savedTask = isOnline
          ? (task.id != null && !task.id!.startsWith('local_')
              ? await _apiService.updateTask(task)
              : await _apiService.createTask(task))
          : task.copyWith(isSynced: false);

      await _databaseService.upsertTask(savedTask);
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        _tasks[index] = savedTask;
      } else {
        _tasks.insert(0, savedTask);
      }
      await NotificationService.instance.showTaskSaved(savedTask.title);
    } catch (error) {
      final offlineTask = task.copyWith(isSynced: false);
      await _databaseService.upsertTask(offlineTask);
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        _tasks[index] = offlineTask;
      } else {
        _tasks.insert(0, offlineTask);
      }
      isOnline = false;
      errorMessage = 'Mode offline: la tache sera synchronisee plus tard.';
    }
    notifyListeners();
  }
}
