
import 'package:flutter/material.dart';

import '../../data/repositories/measurement_repository.dart';
import '../../models/measurement.dart';
import '../measurements/add_measurement_screen.dart';
import '../measurements/measurement_history_screen.dart';
import 'widgets/bp_summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MeasurementRepository _repository = MeasurementRepository();

  static const String _userId = 'default';

  List<Measurement> _measurements = [];
  bool _isLoading = true;

  Measurement? get _latestMeasurement {
    if (_measurements.isEmpty) return null;
    return _measurements.first;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning 👋';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon 👋';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening 👋';
    } else {
      return 'Good night 👋';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    try {
      final measurements = await _repository.getMeasurements(_userId);

      if (!mounted) return;

      setState(() {
        _measurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load readings: $e'),
        ),
      );
    }
  }

  Future<void> _addMeasurement() async {
    final result = await Navigator.push<Measurement>(
      context,
      MaterialPageRoute<Measurement>(
        builder: (context) => const AddMeasurementScreen(),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _loadMeasurements();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeasurementHistoryScreen(),
      ),
    );

    if (!mounted) return;

    await _loadMeasurements();
  }

  void _openAnalytics() {
    Navigator.pushNamed(context, '/analytics');
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return TimeOfDay.fromDateTime(date).format(context);
  }

  Widget _buildRecentReading(Measurement measurement) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final arm = measurement.arm == MeasurementArm.left
        ? 'Left arm'
        : 'Right arm';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite_outline,
              color: colors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(measurement.measuredAt)}'
                  ' · ${_formatTime(measurement.measuredAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  arm,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${measurement.systolic}/${measurement.diastolic}',
                style: theme.textTheme.titleLarge,
              ),
              if (measurement.pulse != null)
                Text(
                  '${measurement.pulse} BPM',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_measurements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              color: colors.secondary,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'No recent activity',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Your saved readings will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final recentMeasurements = _measurements.take(3);

    return Column(
      children: recentMeasurements.map(_buildRecentReading).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeasurement,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getGreeting(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 25,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: _openAnalytics,
                    tooltip: 'Analytics',
                    icon: const Icon(
                      Icons.analytics_outlined,
                      size: 25,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: _openSettings,
                    tooltip: 'Settings',
                    icon: const Icon(
                      Icons.settings_outlined,
                      size: 25,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Here is your health overview.',
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 28),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(35),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                BPSummaryCard(
                  measurement: _latestMeasurement,
                ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 19,
                    ),
                  ),
                  TextButton(
                    onPressed: _openHistory,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View all'),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (!_isLoading) _buildRecentActivity(),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
