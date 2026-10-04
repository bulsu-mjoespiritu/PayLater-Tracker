import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bill_provider.dart';
import 'providers/theme_controller.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PayLaterTrackerApp());
}

class PayLaterTrackerApp extends StatelessWidget {
  const PayLaterTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Reads saved bills/history/transactions from on-device storage.
        // Starts completely empty on a fresh install — no sample data.
        ChangeNotifierProvider(create: (_) => BillProvider()..loadFromStorage()),
        // Remembers the light / dark mode choice.
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'PayLater Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: const _AppRoot(),
    );
  }
}

/// Shows a brief loading spinner while saved data is being read from disk,
/// then hands off to the real app once it's ready.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final isLoaded = context.watch<BillProvider>().isLoaded;

    if (!isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const MainScreen();
  }
}
