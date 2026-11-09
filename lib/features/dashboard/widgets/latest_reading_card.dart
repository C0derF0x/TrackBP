
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/measurement.dart';

class LatestReadingCard extends StatelessWidget {
  final Measurement? measurement;

  const LatestReadingCard({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    final reading = measurement;

    if (reading == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE8EEF2),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.history,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your recent readings will appear here.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final date = reading.measuredAt;
    final dateText =
        '${_monthName(date.month)} ${date.day}, ${date.year}';

    final time = TimeOfDay.fromDateTime(date);
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    final arm = reading.arm == MeasurementArm.left
        ? 'Left arm'
        : 'Right arm';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EEF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: AppTheme.primary,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest reading',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$dateText · $hour:$minute $period',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  reading.pulse == null
                      ? arm
                      : '$arm · ${reading.pulse} BPM',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '${reading.systolic}/${reading.diastolic}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}
