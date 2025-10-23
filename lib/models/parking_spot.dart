// lib/models/parking_spot.dart
class ParkingSpot {
  final String id;
  final String lotId;
  final String status; // 'A' available, 'O' occupied
  final String? label; // Computed like 'A-1'

  ParkingSpot({
    required this.id,
    required this.lotId,
    required this.status,
    this.label,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['_id'] ?? '',
      lotId: json['lotId'] ?? '',
      status: json['status'] ?? 'A',
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lotId': lotId,
      'status': status,
    };
  }
}