
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/measurement.dart';

class BPSummaryCard extends StatelessWidget {
  final Measurement? measurement;

  const BPSummaryCard({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    final reading = measurement;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: reading == null
          ? _buildEmptyState()
          : _buildReading(reading),
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BLOOD PRESSURE OVERVIEW',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 24),
        Icon(
          Icons.monitor_heart_outlined,
          color: Colors.white,
          size: 38,
        ),
        SizedBox(height: 14),
        Text(
          'No readings yet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Add your first blood pressure reading to get started.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildReading(Measurement reading) {
    final time = TimeOfDay.fromDateTime(
      reading.measuredAt,
    ).formatFromTimeOfDay();

    final arm = reading.arm == MeasurementArm.left
        ? 'Left arm'
        : 'Right arm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LATEST BLOOD PRESSURE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${reading.systolic}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 9),
              child: Text(
                ' / ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 25,
                ),
              ),
            ),
            Text(
              '${reading.diastolic}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'mmHg',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Systolic                 Diastolic',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 18),

        const Divider(color: Colors.white30),

        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(
              Icons.access_time,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              '$time  ·  $arm',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension on TimeOfDay {
  String formatFromTimeOfDay() {
    final hour = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final minuteText = minute.toString().padLeft(2, '0');
    final period = this.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minuteText $period';
  }
}
