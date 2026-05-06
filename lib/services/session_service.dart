import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionService {
  static const _idKey = 'session_user_id';
  static const _nameKey = 'session_user_name';
  static const _emailKey = 'session_user_email';
  static const _passwordKey = 'session_user_password';
  static const _roleKey = 'session_user_role';
  static const _onboardingSeenKey = 'onboarding_seen';

  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, user.id ?? '');
    await prefs.setString(_nameKey, user.name);
    await prefs.setString(_emailKey, user.email);
    await prefs.setString(_passwordKey, user.password);
    await prefs.setString(_roleKey, user.role);
  }

  Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (email == null || email.isEmpty) return null;
    return AppUser(
      id: prefs.getString(_idKey),
      name: prefs.getString(_nameKey) ?? '',
      email: email,
      password: prefs.getString(_passwordKey) ?? '',
      role: prefs.getString(_roleKey) ?? 'user',
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_roleKey);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
