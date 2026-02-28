import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: For a real app, you need to provide actual Supabase credentials here.
  // We use placeholder credentials to allow the app to compile and run the UI.
  try {
    await Supabase.initialize(
      url: 'https://ekgvfzedttwqlnszopfc.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrZ3ZmemVkdHR3cWxuc3pvcGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwMjcwNTIsImV4cCI6MjA4NzYwMzA1Mn0.6pm0-6eRgPQ1TtVNMeutoTLm16r9kQZQy4qvit0SoX8',
    );
  } catch (e) {
    debugPrint('Supabase init skipped/failed: $e');
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'TaskMate',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
