class Reservation {
  String? id;
  String? lotId;
  String? spotId;
  String? userId;
  String? vehicleNumber;
  DateTime? reservationTime;
  String? status;
  String? paymentStatus;

  Reservation({
    this.id,
    this.lotId,
    this.spotId,
    this.userId,
    this.vehicleNumber,
    this.reservationTime,
    this.status,
    this.paymentStatus,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      lotId: json['lotId']?.toString(),
      spotId: json['spotId']?.toString(),
      userId: json['userId']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      reservationTime: json['reservationTime'] != null
          ? DateTime.tryParse(json['reservationTime'].toString())
          : null,
      status: json['status']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'lotId': lotId,
      'spotId': spotId,
      'userId': userId,
      'vehicleNumber': vehicleNumber,
      'reservationTime': reservationTime?.toIso8601String(),
      'status': status,
      'paymentStatus': paymentStatus,
    };
  }
}
