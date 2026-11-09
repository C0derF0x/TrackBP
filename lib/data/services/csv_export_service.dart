
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/measurement.dart';
import '../repositories/measurement_repository.dart';

class CsvExportService {
  final MeasurementRepository _repository;

  CsvExportService({
    MeasurementRepository? repository,
  }) : _repository = repository ?? MeasurementRepository();

  Future<File> exportMeasurements(String userId) async {
    // Fetch every saved measurement for this user.
    final measurements = await _repository.getMeasurements(userId);

    if (measurements.isEmpty) {
      throw StateError('There are no measurements to export.');
    }

    // Sort readings from newest to oldest.
    measurements.sort(
      (a, b) => b.measuredAt.compareTo(a.measuredAt),
    );

    final rows = <List<dynamic>>[
      [
        'Date',
        'Time',
        'Systolic (mmHg)',
        'Diastolic (mmHg)',
        'Pulse (BPM)',
        'Arm',
      ],
    ];

    for (final measurement in measurements) {
      final dateTime = measurement.measuredAt.toLocal();

      rows.add([
        '${dateTime.year}-'
            '${dateTime.month.toString().padLeft(2, '0')}-'
            '${dateTime.day.toString().padLeft(2, '0')}',
        '${dateTime.hour.toString().padLeft(2, '0')}:'
            '${dateTime.minute.toString().padLeft(2, '0')}',
        measurement.systolic,
        measurement.diastolic,
        measurement.pulse ?? '',
        measurement.arm == MeasurementArm.left ? 'L' : 'R',
      ]);
    }

    // Convert the rows into CSV format.
    final csvContent = csv.encode(rows);

    // Save the CSV in the temporary directory.
    final directory = await getTemporaryDirectory();
    final now = DateTime.now();

    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final file = File(
      '${directory.path}/bp_readings_$timestamp.csv',
    );

    // Add a UTF-8 BOM for better compatibility with spreadsheet apps.
    await file.writeAsBytes(
      utf8.encode('\uFEFF$csvContent'),
      flush: true,
    );

    // Open the native sharing interface.
    await SharePlus.instance.share(
      ShareParams(
        title: 'Export Blood Pressure Data',
        files: [
          XFile(
            file.path,
            mimeType: 'text/csv',
          ),
        ],
      ),
    );

    return file;
  }
}
