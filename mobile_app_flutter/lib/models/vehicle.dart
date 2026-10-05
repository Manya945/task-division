class Vehicle {
  final int id;
  final String plateNumber;
  final String ownerName;
  final String vehicleType;
  final double permittedWeightKg;
  final String? rfidTag;
  final String state;
  final String? fitnessValidUntil;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.ownerName,
    required this.vehicleType,
    required this.permittedWeightKg,
    this.rfidTag,
    required this.state,
    this.fitnessValidUntil,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      plateNumber: json['plate_number'] ?? '',
      ownerName: json['owner_name'] ?? 'Unknown Owner',
      vehicleType: json['vehicle_type'] ?? 'Commercial Vehicle',
      permittedWeightKg: (json['permitted_weight_kg'] ?? 10000.0).toDouble(),
      rfidTag: json['rfid_tag'],
      state: json['state'] ?? 'CG',
      fitnessValidUntil: json['fitness_valid_until'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plate_number': plateNumber,
    'owner_name': ownerName,
    'vehicle_type': vehicleType,
    'permitted_weight_kg': permittedWeightKg,
    'rfid_tag': rfidTag,
    'state': state,
    'fitness_valid_until': fitnessValidUntil,
  };
}
