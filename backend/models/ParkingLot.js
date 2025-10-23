// backend/models/ParkingLot.js
const mongoose = require('mongoose');

const parkingLotSchema = new mongoose.Schema({
  primeLocationName: { type: String, required: true },
  price: { type: Number, required: true, default: 0 },
  address: { type: String, required: true },
  pinCode: { type: String, required: true },
  maximumNumberOfSpots: { type: Number, required: true, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('ParkingLot', parkingLotSchema);