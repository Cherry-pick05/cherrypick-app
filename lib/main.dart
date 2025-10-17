import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/trip_provider.dart';
import 'providers/packing_provider.dart';
import 'screens/luggage_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/recommendations_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CherryPickApp());
}

class CherryPickApp extends StatelessWidget {
  const CherryPickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => PackingProvider()),
      ],
      child: MaterialApp.router(
        title: 'Cherry Pick',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/luggage',
  routes: [
    GoRoute(
      path: '/luggage',
      builder: (context, state) => const LuggageScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/checklist',
      builder: (context, state) => const ChecklistScreen(),
    ),
    GoRoute(
      path: '/recommendations',
      builder: (context, state) => const RecommendationsScreen(),
    ),
  ],
);
