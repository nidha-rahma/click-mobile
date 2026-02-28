import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: For a real app, you need to provide actual Supabase credentials here.
  // We use placeholder credentials to allow the app to compile and run the UI.
  try {
    await Supabase.initialize(
      url: 'https://placeholder-project.supabase.co',
      anonKey: 'placeholder-anon-key',
    );
  } catch (e) {
    debugPrint('Supabase init skipped/failed: $e');
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMate',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto detect based on system setting
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
