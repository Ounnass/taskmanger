import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/session_service.dart';
import '../utils/app_routes.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    final auth = context.read<AuthProvider>();
    final hasSeenOnboarding = await context.read<SessionService>().hasSeenOnboarding();
    await auth.restoreSession();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = auth.currentUser;
    Navigator.pushReplacementNamed(
      context,
      !hasSeenOnboarding
          ? AppRoutes.onboarding
          : user == null
          ? AppRoutes.login
          : user.isAdmin
              ? AppRoutes.adminDashboard
              : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 96),
              const SizedBox(height: 22),
              Text(
                'Task Manager',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin, user, analytics, offline sync',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 26),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
