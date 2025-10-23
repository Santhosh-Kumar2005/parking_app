// backend/models/ParkingSpot.js
const mongoose = require('mongoose');

const parkingSpotSchema = new mongoose.Schema({
  lotId: { type: mongoose.Schema.Types.ObjectId, ref: 'ParkingLot', required: true },
  status: { type: String, enum: ['A', 'O'], default: 'A' },
  spotIndex: { type: Number, default: 0, min: 1 }, // Enforce min 1
  label: { type: String, required: true }, // e.g., "A-1"
}, { timestamps: true });

// Unique index to prevent duplicate spotIndex per lot
parkingSpotSchema.index({ lotId: 1, spotIndex: 1 }, { unique: true });

module.exports = mongoose.model('ParkingSpot', parkingSpotSchema);