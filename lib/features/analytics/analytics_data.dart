
import '../../models/measurement.dart';

enum AnalyticsPeriod {
  last7Days,
  last30Days,
  last12Months,
  customDay,
}

extension AnalyticsPeriodDetails on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.last7Days:
        return '7 Days';
      case AnalyticsPeriod.last30Days:
        return '30 Days';
      case AnalyticsPeriod.last12Months:
        return '12 Months';
      case AnalyticsPeriod.customDay:
        return 'Custom Day';
    }
  }

  DateTime getStartDate(DateTime now) {
    switch (this) {
      case AnalyticsPeriod.last7Days:
        final today = DateTime(now.year, now.month, now.day);
        return today.subtract(const Duration(days: 6));

      case AnalyticsPeriod.last30Days:
        final today = DateTime(now.year, now.month, now.day);
        return today.subtract(const Duration(days: 29));

      case AnalyticsPeriod.last12Months:
        return DateTime(now.year, now.month - 11, 1);

      case AnalyticsPeriod.customDay:
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime getEndDate(DateTime now) {
    switch (this) {
      case AnalyticsPeriod.last7Days:
      case AnalyticsPeriod.last30Days:
      case AnalyticsPeriod.customDay:
        return DateTime(now.year, now.month, now.day + 1);

      case AnalyticsPeriod.last12Months:
        return DateTime(now.year, now.month + 1, 1);
    }
  }
}

class TrendPoint {
  final DateTime date;
  final double systolic;
  final double diastolic;
  final double? pulse;

  const TrendPoint({
    required this.date,
    required this.systolic,
    required this.diastolic,
    this.pulse,
  });
}

class AnalyticsData {
  final int readingCount;

  final double? averageSystolic;
  final double? averageDiastolic;
  final double? averagePulse;

  final List<TrendPoint> trendPoints;

  const AnalyticsData({
    required this.readingCount,
    required this.averageSystolic,
    required this.averageDiastolic,
    required this.averagePulse,
    required this.trendPoints,
  });

  factory AnalyticsData.fromMeasurements(
    List<Measurement> measurements,
    AnalyticsPeriod period,
  ) {
    if (measurements.isEmpty) {
      return const AnalyticsData(
        readingCount: 0,
        averageSystolic: null,
        averageDiastolic: null,
        averagePulse: null,
        trendPoints: [],
      );
    }

    final systolicTotal = measurements.fold<int>(
      0,
      (total, reading) => total + reading.systolic,
    );

    final diastolicTotal = measurements.fold<int>(
      0,
      (total, reading) => total + reading.diastolic,
    );

    final pulseReadings = measurements
        .where((reading) => reading.pulse != null)
        .toList();

    final pulseTotal = pulseReadings.fold<int>(
      0,
      (total, reading) => total + reading.pulse!,
    );

    final averageSystolic = systolicTotal / measurements.length;
    final averageDiastolic = diastolicTotal / measurements.length;

    final averagePulse = pulseReadings.isEmpty
        ? null
        : pulseTotal / pulseReadings.length;

    // Custom Day: preserve every individual reading and its exact time.
    if (period == AnalyticsPeriod.customDay) {
      final sortedMeasurements = [...measurements]
        ..sort(
          (a, b) => a.measuredAt.compareTo(b.measuredAt),
        );

      final trendPoints = sortedMeasurements.map((reading) {
        return TrendPoint(
          date: reading.measuredAt,
          systolic: reading.systolic.toDouble(),
          diastolic: reading.diastolic.toDouble(),
          pulse: reading.pulse?.toDouble(),
        );
      }).toList();

      return AnalyticsData(
        readingCount: measurements.length,
        averageSystolic: averageSystolic,
        averageDiastolic: averageDiastolic,
        averagePulse: averagePulse,
        trendPoints: trendPoints,
      );
    }

    // Existing behaviour: group readings by day or month.
    final Map<DateTime, List<Measurement>> groupedReadings = {};

    for (final reading in measurements) {
      final date = reading.measuredAt;

      final DateTime bucketDate;

      if (period == AnalyticsPeriod.last12Months) {
        bucketDate = DateTime(date.year, date.month);
      } else {
        bucketDate = DateTime(date.year, date.month, date.day);
      }

      groupedReadings.putIfAbsent(bucketDate, () => []);
      groupedReadings[bucketDate]!.add(reading);
    }

    final trendPoints = groupedReadings.entries.map((entry) {
      final readings = entry.value;

      final bucketSystolicTotal = readings.fold<int>(
        0,
        (total, reading) => total + reading.systolic,
      );

      final bucketDiastolicTotal = readings.fold<int>(
        0,
        (total, reading) => total + reading.diastolic,
      );

      final bucketPulseReadings = readings
          .where((reading) => reading.pulse != null)
          .toList();

      final bucketPulseTotal = bucketPulseReadings.fold<int>(
        0,
        (total, reading) => total + reading.pulse!,
      );

      return TrendPoint(
        date: entry.key,
        systolic: bucketSystolicTotal / readings.length,
        diastolic: bucketDiastolicTotal / readings.length,
        pulse: bucketPulseReadings.isEmpty
            ? null
            : bucketPulseTotal / bucketPulseReadings.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return AnalyticsData(
      readingCount: measurements.length,
      averageSystolic: averageSystolic,
      averageDiastolic: averageDiastolic,
      averagePulse: averagePulse,
      trendPoints: trendPoints,
    );
  }
}
