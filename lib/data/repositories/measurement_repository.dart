
import '../../models/measurement.dart';
import '../sources/local_database.dart';

class MeasurementRepository {
  final LocalDatabase _database;

  MeasurementRepository({
    LocalDatabase? database,
  }) : _database = database ?? LocalDatabase.instance;

  Future<void> saveMeasurement(Measurement measurement) async {
    await _database.insertMeasurement(measurement);
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    final updatedRows = await _database.updateMeasurement(measurement);

    if (updatedRows == 0) {
      throw Exception('The measurement could not be found.');
    }
  }

  Future<List<Measurement>> getMeasurements(String userId) async {
    return _database.getMeasurements(userId);
  }

  Future<List<Measurement>> getMeasurementsInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final measurements = await _database.getMeasurements(userId);

    return measurements.where((measurement) {
      final date = measurement.measuredAt;

      return !date.isBefore(start) && date.isBefore(end);
    }).toList();
  }

  Future<Measurement?> getLatestMeasurement(String userId) async {
    return _database.getLatestMeasurement(userId);
  }

  Future<void> deleteMeasurement(String id) async {
    await _database.deleteMeasurement(id);
  }

  Future<void> deleteAllMeasurements(String userId) async {
    await _database.deleteAllMeasurements(userId);
  }
}
