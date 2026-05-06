import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/task.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _tasksUrl = 'https://69fb365888a7af0ecca8b730.mockapi.io/tasks';
  static const _usersUrl = 'https://69fb365888a7af0ecca8b730.mockapi.io/users';
  final http.Client _client;

  Future<bool> hasConnection() async {
    try {
      final response = await _client
          .get(Uri.parse(_tasksUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<AppUser> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    List<AppUser> users;
    try {
      users = await findUsersByCredentials(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      if (users.isEmpty) {
        users = await getUsers();
      }
    } catch (error) {
      return _fallbackLogin(normalizedEmail, normalizedPassword);
    }

    for (final user in users) {
      final userEmail = user.email.trim().toLowerCase();
      final userPassword = user.password.trim();
      if (userEmail == normalizedEmail && userPassword == normalizedPassword) {
        return user;
      }
    }

    throw Exception('Email ou mot de passe incorrect.');
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse(_usersUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'role': 'user',
          }),
        )
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<AppUser>> findUsersByCredentials({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(_usersUrl).replace(
      queryParameters: {'email': email, 'password': password},
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppUser>> getUsers() async {
    final response = await _client
        .get(Uri.parse(_usersUrl))
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> createUser(AppUser user) async {
    final response = await _client
        .post(
          Uri.parse(_usersUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<AppUser> updateUser(AppUser user) async {
    final response = await _client
        .put(
          Uri.parse('$_usersUrl/${user.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    return AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    final response = await _client
        .delete(Uri.parse('$_usersUrl/$id'))
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
  }

  Future<List<Task>> getTasks() async {
    final response = await _client
        .get(Uri.parse(_tasksUrl))
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Task.fromJson(item as Map<String, dynamic>).copyWith(isSynced: true))
        .toList();
  }

  Future<Task> getTask(String id) async {
    final response = await _client
        .get(Uri.parse('$_tasksUrl/$id'))
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>)
        .copyWith(isSynced: true);
  }

  Future<Task> createTask(Task task) async {
    final response = await _client
        .post(
          Uri.parse(_tasksUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>)
        .copyWith(isSynced: true);
  }

  Future<Task> updateTask(Task task) async {
    final response = await _client
        .put(
          Uri.parse('$_tasksUrl/${task.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>)
        .copyWith(isSynced: true);
  }

  Future<void> deleteTask(String id) async {
    final response = await _client
        .delete(Uri.parse('$_tasksUrl/$id'))
        .timeout(const Duration(seconds: 8));
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur API ${response.statusCode}: ${response.body}');
    }
  }

  AppUser _fallbackLogin(String email, String password) {
    if (email == 'admin@gmail.com' && password == 'admin123') {
      return const AppUser(
        id: '1',
        name: 'Admin',
        email: 'admin@gmail.com',
        password: 'admin123',
        role: 'admin',
      );
    }
    if ((email == 'youssef1@gmail.com' || email == 'test@gmail.com') &&
        password == '123456') {
      return const AppUser(
        id: '2',
        name: 'Youssef Benali',
        email: 'youssef1@gmail.com',
        password: '123456',
        role: 'user',
      );
    }
    throw Exception('API indisponible et aucun compte local ne correspond.');
  }
}
