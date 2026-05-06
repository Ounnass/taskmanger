import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiService apiService,
    required SessionService sessionService,
  })  : _apiService = apiService,
        _sessionService = sessionService;

  final ApiService _apiService;
  final SessionService _sessionService;
  AppUser? currentUser;
  List<AppUser> users = [];
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;

  Future<void> restoreSession() async {
    currentUser = await _sessionService.getUser();
    if (currentUser != null) {
      _rememberCurrentUser();
      unawaited(_refreshUsersSilently());
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _guard(() async {
      currentUser = await _apiService.login(email.trim(), password.trim());
      await _sessionService.saveUser(currentUser!);
      _rememberCurrentUser();
      unawaited(_refreshUsersSilently());
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      currentUser = await _apiService.register(
        name: name.trim(),
        email: email.trim(),
        password: password.trim(),
      );
      await _sessionService.saveUser(currentUser!);
      _rememberCurrentUser();
      unawaited(_refreshUsersSilently());
    });
  }

  Future<void> loadUsers() async {
    try {
      users = await _apiService.getUsers();
      users = _withFallbackUsers(users);
    } catch (_) {
      users = _fallbackUsers;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    users = [];
    await _sessionService.clear();
    notifyListeners();
  }

  Future<void> _refreshUsersSilently() async {
    await loadUsers();
    notifyListeners();
  }

  void _rememberCurrentUser() {
    final user = currentUser;
    if (user == null) return;
    users = _withFallbackUsers([
      ...users.where((item) => item.id != user.id && item.email != user.email),
      user,
    ]);
  }

  Future<bool> _guard(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static const _fallbackUsers = [
    AppUser(
      id: '1',
      name: 'Admin',
      email: 'admin@gmail.com',
      password: 'admin123',
      role: 'admin',
    ),
    AppUser(
      id: '2',
      name: 'Youssef Benali',
      email: 'youssef1@gmail.com',
      password: '123456',
      role: 'user',
    ),
  ];

  static List<AppUser> _withFallbackUsers(List<AppUser> remoteUsers) {
    final merged = [...remoteUsers];
    for (final fallbackUser in _fallbackUsers) {
      final exists = merged.any(
        (user) => user.id == fallbackUser.id || user.email == fallbackUser.email,
      );
      if (!exists) merged.add(fallbackUser);
    }
    return merged;
  }
}
