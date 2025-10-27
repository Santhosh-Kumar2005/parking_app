class ParkingLot {
  String? id;
  String? primeLocationName;
  double? price;
  String? address;
  String? pinCode;
  int? maximumNumberOfSpots;
  String? lotNumber; // Sequential number for display
  String? code; // Display code like "LOT-ABC1"

  ParkingLot({
    this.id,
    this.primeLocationName,
    this.price,
    this.address,
    this.pinCode,
    this.maximumNumberOfSpots,
    this.lotNumber,
    this.code,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    return ParkingLot(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      primeLocationName: json['primeLocationName']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      address: json['address']?.toString(),
      pinCode: json['pinCode']?.toString(),
      maximumNumberOfSpots: json['maximumNumberOfSpots'] as int?,
      lotNumber: json['lotNumber']?.toString(),
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'primeLocationName': primeLocationName,
      'price': price,
      'address': address,
      'pinCode': pinCode,
      'maximumNumberOfSpots': maximumNumberOfSpots,
      'lotNumber': lotNumber,
      'code': code,
    };
  }
}
