class WeightRecord {
  final int id;
  final String plateNumber;
  final double measuredWeightKg;
  final double allowedWeightKg;
  final double excessWeightKg;
  final String status;
  final String sensorId;
  final String checkpointName;
  final String timestamp;

  WeightRecord({
    required this.id,
    required this.plateNumber,
    required this.measuredWeightKg,
    required this.allowedWeightKg,
    required this.excessWeightKg,
    required this.status,
    required this.sensorId,
    required this.checkpointName,
    required this.timestamp,
  });

  bool get isOverload => status == 'OVERLOAD';

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['record_id'] ?? json['id'] ?? 0,
      plateNumber: json['plate_number'] ?? '',
      measuredWeightKg: (json['measured_weight_kg'] ?? 0.0).toDouble(),
      allowedWeightKg: (json['allowed_weight_kg'] ?? 10000.0).toDouble(),
      excessWeightKg: (json['excess_weight_kg'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'NORMAL',
      sensorId: json['sensor_id'] ?? 'ESP32_SCALE_01',
      checkpointName: json['checkpoint_name'] ?? 'Checkpoint',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}
