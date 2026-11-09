
enum MeasurementArm {
  left,
  right,
}

class Measurement {
  final String id;
  final String userId;

  final int systolic;
  final int diastolic;
  final int? pulse;

  final MeasurementArm arm;
  final DateTime measuredAt;

  const Measurement({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.arm,
    required this.measuredAt,
  });

  /// Converts this measurement into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'arm': arm.name,
      'measured_at': measuredAt.toIso8601String(),
    };
  }

  /// Creates a Measurement from a database record.
  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int?,
      arm: MeasurementArm.values.byName(map['arm'] as String),
      measuredAt: DateTime.parse(map['measured_at'] as String),
    );
  }
}
