import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session_service.dart';
import '../utils/app_routes.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.dashboard_customize_outlined,
      title: 'Dashboard intelligent',
      description: 'Suivez vos taches, utilisateurs, statistiques et progression depuis une seule interface moderne.',
    ),
    _OnboardingPage(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Roles Admin et User',
      description: 'Admin gere tout. User voit seulement ses taches avec recherche, historique et filtres.',
    ),
    _OnboardingPage(
      icon: Icons.cloud_sync_outlined,
      title: 'Offline first',
      description: 'Les taches restent accessibles hors ligne et se synchronisent automatiquement au retour du reseau.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const AppLogo(size: 54),
                    const SizedBox(width: 12),
                    Text('Task Manager', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _index = value),
                    children: _pages,
                  ),
                ),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: i == _index ? 28 : 9,
                          height: 9,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: i == _index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _index == _pages.length - 1
                          ? _finish
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              ),
                      icon: Icon(_index == _pages.length - 1
                          ? Icons.check
                          : Icons.arrow_forward),
                      label: Text(_index == _pages.length - 1 ? 'Start' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await context.read<SessionService>().setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.tertiary]),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.24),
                blurRadius: 36,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Icon(icon, size: 92, color: Colors.white),
        ),
        const SizedBox(height: 34),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.55,
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
