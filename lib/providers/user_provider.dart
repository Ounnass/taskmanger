import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  List<AppUser> _users = [];
  bool isLoading = false;
  String searchQuery = '';
  String? errorMessage;

  List<AppUser> get users => List.unmodifiable(_users);

  AppUser? findById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  List<AppUser> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return users;
    return _users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query) ||
          (user.id ?? '').contains(query);
    }).toList();
  }

  Future<void> loadUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _users = await _apiService.getUsers();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUser(AppUser user) async {
    await _guard(() async {
      final savedUser = await _apiService.createUser(user);
      _users.insert(0, savedUser);
    });
  }

  Future<void> updateUser(AppUser user) async {
    await _guard(() async {
      final savedUser = await _apiService.updateUser(user);
      final index = _users.indexWhere((item) => item.id == savedUser.id);
      if (index >= 0) {
        _users[index] = savedUser;
      }
    });
  }

  Future<void> deleteUser(AppUser user) async {
    await _guard(() async {
      if (user.id != null) await _apiService.deleteUser(user.id!);
      _users.removeWhere((item) => item.id == user.id);
    });
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
