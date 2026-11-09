
import 'package:flutter/material.dart';

import '../../app/theme_controller.dart';
import '../../data/services/csv_export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CsvExportService _csvExportService = CsvExportService();

  bool _isExporting = false;

  Future<void> _exportData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _csvExportService.exportMeasurements('default');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV export process completed.'),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while exporting data.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerScope.of(context);
    final selectedTheme = themeController.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Text(
            'Customize how BP Tracker looks on your device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 20),

          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: selectedTheme,
              onChanged: (mode) {
                if (mode != null) {
                  themeController.setThemeMode(mode);
                }
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    secondary: const Icon(Icons.light_mode_outlined),
                    title: const Text('Light mode'),
                    subtitle: const Text('Use the light appearance'),
                  ),

                  const Divider(height: 1),

                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark mode'),
                    subtitle: const Text('Use the dark appearance'),
                  ),

                  const Divider(height: 1),

                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    secondary: const Icon(Icons.settings_brightness_outlined),
                    title: const Text('System default'),
                    subtitle: const Text('Follow your device settings'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Data',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export Data'),
              subtitle: Text(
                _isExporting
                    ? 'Preparing your CSV file...'
                    : 'Export all your readings as a CSV file',
              ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting ? null : _exportData,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Card(
            child: const ListTile(
              leading: Icon(Icons.favorite_outline),
              title: Text('BP Tracker'),
              subtitle: Text('Your personal blood pressure companion'),
            ),
          ),
        ],
      ),
    );
  }
}
