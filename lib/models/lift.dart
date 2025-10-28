class Lift {
  final String id;
  final String liftId;
  final String blockId;
  final int liftNumber;
  final String status;
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
    print('🔍 Parsing Lift from JSON: $json');

    try {
      return Lift(
        id: json['_id']?.toString() ?? '',
        liftId: json['liftId']?.toString() ?? '',
        blockId: json['blockId']?.toString() ?? '',
        liftNumber: json['liftNumber'] is int
            ? json['liftNumber']
            : int.tryParse(json['liftNumber']?.toString() ?? '0') ?? 0,
        status: json['status']?.toString() ?? 'available',
        currentBookingId: json['currentBookingId']?.toString(),
        currentVehicleNumber: json['currentVehicleNumber']?.toString(),
        assignedAt: json['assignedAt'] != null
            ? DateTime.tryParse(json['assignedAt'].toString())
            : null,
        releasedAt: json['releasedAt'] != null
            ? DateTime.tryParse(json['releasedAt'].toString())
            : null,
        sensorStatus: json['sensorStatus'] == true,
        floor: json['floor']?.toString() ?? 'Ground',
        lastActivity: json['lastActivity'] != null
            ? DateTime.tryParse(json['lastActivity'].toString()) ??
                  DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing Lift: $e');
      rethrow;
    }
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
