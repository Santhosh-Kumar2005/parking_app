class ParkingSpot {
  String? id;
  String? lotId;
  String? label;
  String? status;
  String? userId;
  String? vehicleNumber;
  DateTime? parkingTimestamp;
  DateTime? leavingTimestamp;
  double? parkingCost;

  ParkingSpot({
    this.id,
    this.lotId,
    this.label,
    this.status,
    this.userId,
    this.vehicleNumber,
    this.parkingTimestamp,
    this.leavingTimestamp,
    this.parkingCost,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      lotId: json['lotId']?.toString(),
      label: json['label']?.toString(),
      status: json['status']?.toString() ?? 'Available',
      userId: json['userId']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      parkingTimestamp: json['parkingTimestamp'] != null
          ? DateTime.tryParse(json['parkingTimestamp'].toString())
          : null,
      leavingTimestamp: json['leavingTimestamp'] != null
          ? DateTime.tryParse(json['leavingTimestamp'].toString())
          : null,
      parkingCost: (json['parkingCost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'lotId': lotId,
      'label': label,
      'status': status,
      'userId': userId,
      'vehicleNumber': vehicleNumber,
      'parkingTimestamp': parkingTimestamp?.toIso8601String(),
      'leavingTimestamp': leavingTimestamp?.toIso8601String(),
      'parkingCost': parkingCost,
    };
  }
}
