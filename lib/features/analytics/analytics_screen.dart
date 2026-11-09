
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/measurement_repository.dart';
import 'analytics_data.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final MeasurementRepository _repository = MeasurementRepository();

  static const String _userId = 'default';

  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.last7Days;

  DateTime _selectedDate = DateTime.now();

  AnalyticsData _analyticsData = const AnalyticsData(
    readingCount: 0,
    averageSystolic: null,
    averageDiastolic: null,
    averagePulse: null,
    trendPoints: [],
  );

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      final DateTime start;
      final DateTime end;

      if (_selectedPeriod == AnalyticsPeriod.customDay) {
        start = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );

        end = start.add(const Duration(days: 1));
      } else {
        start = _selectedPeriod.getStartDate(now);
        end = _selectedPeriod.getEndDate(now);
      }

      final measurements = await _repository.getMeasurementsInRange(
        userId: _userId,
        start: start,
        end: end,
      );

      final data = AnalyticsData.fromMeasurements(
        measurements,
        _selectedPeriod,
      );

      if (!mounted) return;

      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load analytics: $e'),
        ),
      );
    }
  }

  Future<void> _selectCustomDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Select a day to analyse',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _selectedDate = selectedDate;
    });

    await _loadAnalytics();
  }

  String _formatAverage(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthAxisLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return "${months[date.month - 1]} '${date.year % 100}";
  }

  String _formatTimeAxisLabel(DateTime date) {
    return TimeOfDay.fromDateTime(date).format(context);
  }

  Widget _buildPeriodSelector() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedPeriod == period) return;

                setState(() {
                  _selectedPeriod = period;
                });

                _loadAnalytics();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomDateSelector() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 19,
            color: colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selected day',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _selectCustomDate,
            icon: const Icon(
              Icons.edit_calendar_outlined,
              size: 17,
            ),
            label: Text(_formatFullDate(_selectedDate)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final colors = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _buildStatCard(
          title: 'Avg. systolic',
          value: _formatAverage(_analyticsData.averageSystolic),
          unit: 'mmHg',
          icon: Icons.arrow_upward_rounded,
          color: colors.primary,
        ),
        _buildStatCard(
          title: 'Avg. diastolic',
          value: _formatAverage(_analyticsData.averageDiastolic),
          unit: 'mmHg',
          icon: Icons.arrow_downward_rounded,
          color: const Color(0xFF5286C7),
        ),
        _buildStatCard(
          title: 'Avg. pulse',
          value: _formatAverage(_analyticsData.averagePulse),
          unit: 'BPM',
          icon: Icons.favorite_outline,
          color: const Color(0xFFE17C86),
        ),
        _buildStatCard(
          title: 'Total readings',
          value: '${_analyticsData.readingCount}',
          unit: 'entries',
          icon: Icons.analytics_outlined,
          color: const Color(0xFF8B78C5),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required List<BarChartGroupData> barGroups,
    required List<DateTime> bucketDates,
    required List<double> values,
    required String tooltipUnit,
    required List<String> seriesLabels,
    required bool showLegend,
  }) {
    final colors = Theme.of(context).colorScheme;
    final outlineColor = Theme.of(context).dividerColor;

    if (values.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: outlineColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 35,
              color: colors.secondary,
            ),
            const SizedBox(height: 10),
            Text(
              'Not enough data yet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate an independent Y-axis range for each chart.
    final minValue = values.reduce(
      (a, b) => a < b ? a : b,
    );

    final maxValue = values.reduce(
      (a, b) => a > b ? a : b,
    );

    final range = maxValue - minValue;
    final padding = math.max(range * 0.15, 5.0);

    final minY = math.max(
      0,
      ((minValue - padding) / 10).floor() * 10,
    ).toDouble();

    final maxY = (
      ((maxValue + padding) / 10).ceil() * 10
    ).toDouble();

    final yInterval = math.max(
      (maxY - minY) / 4,
      1.0,
    );

    final bucketCount = bucketDates.length;

    final labelInterval = switch (_selectedPeriod) {
      AnalyticsPeriod.last7Days => 1,
      AnalyticsPeriod.last30Days => 5,
      AnalyticsPeriod.last12Months => 2,
      AnalyticsPeriod.customDay => bucketCount > 6 ? 2 : 1,
    };

    final seriesColors = [
      colors.primary,
      const Color(0xFF5286C7),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (showLegend) ...[
            const SizedBox(height: 15),
            Row(
              children: List.generate(seriesLabels.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == seriesLabels.length - 1 ? 0 : 18,
                  ),
                  child: _buildLegendItem(
                    seriesLabels[index],
                    seriesColors[index],
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: minY,
                maxY: maxY,
                alignment: BarChartAlignment.spaceBetween,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: outlineColor,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(
                            value.round().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= bucketCount) {
                          return const SizedBox.shrink();
                        }

                        final isLast = index == bucketCount - 1;

                        if (index != 0 &&
                            !isLast &&
                            index % labelInterval != 0) {
                          return const SizedBox.shrink();
                        }

                        final date = bucketDates[index];

                        final String label;

                        if (_selectedPeriod == AnalyticsPeriod.customDay) {
                          label = _formatTimeAxisLabel(date);
                        } else if (_selectedPeriod ==
                            AnalyticsPeriod.last12Months) {
                          label = _formatMonthAxisLabel(date);
                        } else {
                          label = '${date.day}/${date.month}';
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (
                      group,
                      groupIndex,
                      rod,
                      rodIndex,
                    ) {
                      final index = group.x;

                      if (index < 0 || index >= bucketDates.length) {
                        return null;
                      }

                      final date = bucketDates[index];

                      final String dateLabel;

                      if (_selectedPeriod == AnalyticsPeriod.customDay) {
                        dateLabel =
                            '${_formatFullDate(date)} '
                            '${_formatTimeAxisLabel(date)}';
                      } else if (_selectedPeriod ==
                          AnalyticsPeriod.last12Months) {
                        dateLabel = _formatMonthYear(date);
                      } else {
                        dateLabel = _formatDate(date);
                      }

                      final seriesLabel = seriesLabels[rodIndex];

                      return BarTooltipItem(
                        '$dateLabel\n'
                        '$seriesLabel: '
                        '${rod.toY.toStringAsFixed(1)} $tooltipUnit',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Systolic and diastolic have independent charts and scales.
  Widget _buildBloodPressureChart() {
    final colors = Theme.of(context).colorScheme;
    final points = _analyticsData.trendPoints;

    final isCustomDay = _selectedPeriod == AnalyticsPeriod.customDay;

    final systolicValues = points
        .map((point) => point.systolic)
        .toList();

    final systolicGroups = List.generate(points.length, (index) {
      final point = points[index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: point.systolic,
            color: colors.primary,
            width: points.length > 15 ? 7.0 : 14.0,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final diastolicValues = points
        .map((point) => point.diastolic)
        .toList();

    final diastolicGroups = List.generate(points.length, (index) {
      final point = points[index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: point.diastolic,
            color: const Color(0xFF5286C7),
            width: points.length > 15 ? 7.0 : 14.0,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final dates = points
        .map((point) => point.date)
        .toList();

    return Column(
      children: [
        _buildChartCard(
          title: 'Systolic trend',
          subtitle: isCustomDay
              ? 'Individual systolic readings throughout the day'
              : 'Average systolic pressure over time',
          barGroups: systolicGroups,
          bucketDates: dates,
          values: systolicValues,
          tooltipUnit: 'mmHg',
          seriesLabels: ['Systolic'],
          showLegend: false,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          title: 'Diastolic trend',
          subtitle: isCustomDay
              ? 'Individual diastolic readings throughout the day'
              : 'Average diastolic pressure over time',
          barGroups: diastolicGroups,
          bucketDates: dates,
          values: diastolicValues,
          tooltipUnit: 'mmHg',
          seriesLabels: ['Diastolic'],
          showLegend: false,
        ),
      ],
    );
  }

  Widget _buildPulseChart() {
    final isCustomDay = _selectedPeriod == AnalyticsPeriod.customDay;

    final points = _analyticsData.trendPoints
        .where((point) => point.pulse != null)
        .toList();

    final barGroups = List.generate(points.length, (index) {
      final point = points[index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: point.pulse!,
            color: const Color(0xFFE17C86),
            width: points.length > 15 ? 7.0 : 14.0,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final values = points
        .map((point) => point.pulse!)
        .toList();

    return _buildChartCard(
      title: 'Pulse trend',
      subtitle: isCustomDay
          ? 'Individual pulse readings throughout the day'
          : 'Average recorded pulse for each day or month',
      barGroups: barGroups,
      bucketDates: points.map((point) => point.date).toList(),
      values: values,
      tooltipUnit: 'BPM',
      seriesLabels: ['Pulse'],
      showLegend: false,
    );
  }

  Widget _buildEmptyPeriodMessage() {
    final colors = Theme.of(context).colorScheme;

    final isCustomDay = _selectedPeriod == AnalyticsPeriod.customDay;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            color: colors.secondary,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            isCustomDay
                ? 'No readings on this day'
                : 'No readings in this period',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isCustomDay
                ? 'Choose another date or add a reading to see your daily trends.'
                : 'Add some readings to start seeing your trends and averages.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
          color: colors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your health insights',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review your recorded measurements over time.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPeriodSelector(),

                if (_selectedPeriod == AnalyticsPeriod.customDay)
                  _buildCustomDateSelector(),

                const SizedBox(height: 25),

                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50),
                      child: CircularProgressIndicator(
                        color: colors.primary,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _buildStatistics(),
                  const SizedBox(height: 27),
                  Text(
                    'Trends',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (_analyticsData.readingCount == 0)
                    _buildEmptyPeriodMessage()
                  else ...[
                    _buildBloodPressureChart(),
                    const SizedBox(height: 16),
                    _buildPulseChart(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
