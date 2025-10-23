// lib/models/reservation.dart
import 'package:intl/intl.dart';

class Reservation {
  final String? id;
  final String? spotId;
  final String? lotId;
  final String? userId;
  final String? vehicleNumber;
  final DateTime? parkingTimestamp;
  final DateTime? leavingTimestamp;
  final double? parkingCost;
  Reservation({
    this.id,
    this.spotId,
    this.lotId,
    this.userId,
    this.vehicleNumber,
    this.parkingTimestamp,
    this.leavingTimestamp,
    this.parkingCost,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // spotId can be a string, null, or populated object { _id, lotId, spotIndex }
    String? spotId;
    String? lotId;

    final s = json['spotId'];
    if (s is String) {
      spotId = s;
    } else if (s is Map) {
      spotId = (s['_id'] ?? s['id'])?.toString();
      final lotObj = s['lotId'] ?? json['lotId'];
      if (lotObj is String) {
        lotId = lotObj;
      } else if (lotObj is Map) {
        lotId = (lotObj['_id'] ?? lotObj['id'])?.toString();
      }
    } else {
      // fallback to separate lotId field if present
      if (json['lotId'] is String) lotId = json['lotId'];
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      try {
        return double.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Reservation(
      id: (json['_id'] ?? json['id'])?.toString(),
      spotId: spotId ?? json['spotId']?.toString(),
      lotId: lotId ?? (json['lotId']?.toString()),
      userId: (json['userId'] ?? json['user']?['_id'])?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      parkingTimestamp: parseDate(json['parkingTimestamp']),
      leavingTimestamp: parseDate(json['leavingTimestamp']),
      parkingCost: parseDouble(json['parkingCost']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotId': spotId,
      'lotId': lotId,
      'userId': userId,
      'vehicleNumber': vehicleNumber,
      'parkingTimestamp': parkingTimestamp?.toIso8601String(),
      'leavingTimestamp': leavingTimestamp?.toIso8601String(),
      'parkingCost': parkingCost,
    };
  }

  String get formattedParkingTime =>
      parkingTimestamp != null ? parkingTimestamp!.toLocal().toString() : 'N/A';

  String get formattedLeavingTime => leavingTimestamp != null
      ? leavingTimestamp!.toLocal().toString()
      : 'Still Parked';
}
