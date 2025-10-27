// ============================================
// File: lib/models/lift.dart
// LIFT MODEL FOR FLUTTER
// ============================================

class Lift {
  final String id;
  final String liftId;
  final String blockId;
  final int liftNumber;
  final String status; // available, occupied, in_transit, maintenance
  final String? currentBookingId;
  final String? currentVehicleNumber;
  final DateTime? assignedAt;
  final DateTime? releasedAt;
  final bool sensorStatus;
  final String floor;
  final DateTime lastActivity;

  Lift({
    required this.id,
    required this.liftId,
    required this.blockId,
    required this.liftNumber,
    required this.status,
    this.currentBookingId,
    this.currentVehicleNumber,
    this.assignedAt,
    this.releasedAt,
    required this.sensorStatus,
    required this.floor,
    required this.lastActivity,
  });

  factory Lift.fromJson(Map<String, dynamic> json) {
    return Lift(
      id: json['_id'] ?? '',
      liftId: json['liftId'] ?? '',
      blockId: json['blockId'] ?? '',
      liftNumber: json['liftNumber'] ?? 0,
      status: json['status'] ?? 'available',
      currentBookingId: json['currentBookingId'],
      currentVehicleNumber: json['currentVehicleNumber'],
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : null,
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'])
          : null,
      sensorStatus: json['sensorStatus'] ?? false,
      floor: json['floor'] ?? 'Ground',
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'liftId': liftId,
      'blockId': blockId,
      'liftNumber': liftNumber,
      'status': status,
      'currentBookingId': currentBookingId,
      'currentVehicleNumber': currentVehicleNumber,
      'assignedAt': assignedAt?.toIso8601String(),
      'releasedAt': releasedAt?.toIso8601String(),
      'sensorStatus': sensorStatus,
      'floor': floor,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied' || status == 'in_transit';
}
