class Violation {
  final int id;
  final String challanNumber;
  final String plateNumber;
  final String vehicleType;
  final double measuredWeightKg;
  final double permittedWeightKg;
  final double excessWeightKg;
  final double fineAmount;
  final String status;
  final String checkpointName;
  final String? imagePath;
  final String createdAt;

  Violation({
    required this.id,
    required this.challanNumber,
    required this.plateNumber,
    required this.vehicleType,
    required this.measuredWeightKg,
    required this.permittedWeightKg,
    required this.excessWeightKg,
    required this.fineAmount,
    required this.status,
    required this.checkpointName,
    this.imagePath,
    required this.createdAt,
  });

  bool get isPaid => status == 'PAID';

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      id: json['id'] ?? 0,
      challanNumber: json['challan_number'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'Truck',
      measuredWeightKg: (json['measured_weight_kg'] ?? 0.0).toDouble(),
      permittedWeightKg: (json['permitted_weight_kg'] ?? 0.0).toDouble(),
      excessWeightKg: (json['excess_weight_kg'] ?? 0.0).toDouble(),
      fineAmount: (json['fine_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'PENDING',
      checkpointName: json['checkpoint_name'] ?? 'Checkpoint',
      imagePath: json['image_path'],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
