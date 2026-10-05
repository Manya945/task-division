class AlertModel {
  final int id;
  final String alertType;
  final String severity;
  final String? plateNumber;
  final String message;
  final String checkpointName;
  final int isRead;
  final String createdAt;

  AlertModel({
    required this.id,
    required this.alertType,
    required this.severity,
    this.plateNumber,
    required this.message,
    required this.checkpointName,
    required this.isRead,
    required this.createdAt,
  });

  bool get isCritical => severity == 'CRITICAL';

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      alertType: json['alert_type'] ?? 'OVERLOAD',
      severity: json['severity'] ?? 'HIGH',
      plateNumber: json['plate_number'],
      message: json['message'] ?? '',
      checkpointName: json['checkpoint_name'] ?? 'Toll Checkpoint',
      isRead: json['is_read'] ?? 0,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
