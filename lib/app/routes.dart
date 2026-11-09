
import 'package:flutter/material.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/measurements/add_measurement_screen.dart';
import '../features/measurements/measurement_history_screen.dart';
import '../features/profiles/profile_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const DashboardScreen(),
      '/add-measurement': (context) => const AddMeasurementScreen(),
      '/history': (context) => const MeasurementHistoryScreen(),
      '/analytics': (context) => const AnalyticsScreen(),
      '/profile': (context) => const ProfileScreen(),
      '/settings': (context) => const SettingsScreen(),
    };
  }
}
