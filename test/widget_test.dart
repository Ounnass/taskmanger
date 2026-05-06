import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:task_manager_app/main.dart';
import 'package:task_manager_app/providers/auth_provider.dart';
import 'package:task_manager_app/providers/task_provider.dart';
import 'package:task_manager_app/providers/theme_provider.dart';
import 'package:task_manager_app/providers/user_provider.dart';
import 'package:task_manager_app/services/api_service.dart';
import 'package:task_manager_app/services/database_service.dart';
import 'package:task_manager_app/services/session_service.dart';

void main() {
  testWidgets('shows splash screen', (WidgetTester tester) async {
    final apiService = ApiService();
    final databaseService = DatabaseService.instance;
    final sessionService = SessionService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<DatabaseService>.value(value: databaseService),
          Provider<SessionService>.value(value: sessionService),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              apiService: apiService,
              sessionService: sessionService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => UserProvider(apiService: apiService),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => TaskProvider(
              apiService: apiService,
              databaseService: databaseService,
            ),
          ),
        ],
        child: const TaskManagerApp(),
      ),
    );

    expect(find.text('Task Manager'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });
}
