import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _preferenceKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // Load the previously saved theme.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_preferenceKey);

    switch (savedMode) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      case 'light':
      default:
        _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  // Change the theme and save the selection.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    String value;

    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
    }

    await prefs.setString(_preferenceKey, value);
  }
}

// Makes the theme controller accessible to all screens.
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();

    assert(scope != null, 'ThemeControllerScope not found in widget tree.');

    return scope!.notifier!;
  }
}