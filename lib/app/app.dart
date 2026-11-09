import 'package:flutter/material.dart';

import 'theme.dart';
import 'routes.dart';
import 'theme_controller.dart';

class BPTrackerApp extends StatefulWidget {
  const BPTrackerApp({super.key});

  @override
  State<BPTrackerApp> createState() => _BPTrackerAppState();
}

class _BPTrackerAppState extends State<BPTrackerApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();

    _themeController = ThemeController();
    _themeController.loadTheme();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, child) {
        return ThemeControllerScope(
          controller: _themeController,
          child: MaterialApp(
            title: 'BP Tracker',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeController.themeMode,

            initialRoute: '/',
            routes: AppRoutes.routes,
          ),
        );
      },
    );
  }
}