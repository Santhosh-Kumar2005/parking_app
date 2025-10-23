// backend/models/Reservation.js
const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
  spotId: { type: mongoose.Schema.Types.ObjectId, ref: 'ParkingSpot', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  vehicleNumber: { type: String, required: true },
  parkingTimestamp: { type: Date, default: Date.now },
  leavingTimestamp: { type: Date },
  parkingCost: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('Reservation', reservationSchema);