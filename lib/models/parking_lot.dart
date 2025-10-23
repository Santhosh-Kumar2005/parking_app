// lib/models/parking_lot.dart (Updated to include lotNumber)
class ParkingLot {
  String? id;
  String? lotNumber; // New: Sequential number (1, 2, 3...)
  String? code; // Formatted code
  String? primeLocationName;
  double? price;
  String? address;
  String? pinCode;
  int? maximumNumberOfSpots;
  String? availability;

  ParkingLot({
    this.id,
    this.lotNumber,
    this.code,
    this.primeLocationName,
    this.price,
    this.address,
    this.pinCode,
    this.maximumNumberOfSpots,
    this.availability,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    final lot = ParkingLot(
      id: json['_id']?.toString(),
      primeLocationName: json['primeLocationName'],
      price: (json['price'] as num?)?.toDouble(),
      address: json['address'],
      pinCode: json['pinCode'],
      maximumNumberOfSpots: json['maximumNumberOfSpots'],
      availability: json['availability'],
    );
    // Compute code if not present
    lot.code = json['code'] ?? 'LOT-${lot.id?.substring(0, 4).toUpperCase() ?? 'N/A'}';
    lot.lotNumber = json['lotNumber']; // From backend if available, else computed in frontend
    return lot;
  }

  Map<String, dynamic> toJson() {
    return {
      'primeLocationName': primeLocationName,
      'price': price,
      'address': address,
      'pinCode': pinCode,
      'maximumNumberOfSpots': maximumNumberOfSpots,
    };
  }
}