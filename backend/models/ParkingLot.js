// ============================================
// File: backend/models/ParkingLot.js
// CREATE THIS NEW FILE
// ============================================

const mongoose = require('mongoose');

const parkingLotSchema = new mongoose.Schema({
  blockId: {
    type: String,
    required: true,
    unique: true,
    uppercase: true
  },
  totalSlots: {
    type: Number,
    default: 40,
    min: 0
  },
  availableSlots: {
    type: Number,
    default: 40,
    min: 0,
    max: 40
  },
  occupiedSlots: {
    type: Number,
    default: 0,
    min: 0,
    max: 40
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Ensure slots don't go negative
parkingLotSchema.pre('save', function(next) {
  if (this.availableSlots < 0) this.availableSlots = 0;
  if (this.occupiedSlots < 0) this.occupiedSlots = 0;
  if (this.availableSlots > 40) this.availableSlots = 40;
  if (this.occupiedSlots > 40) this.occupiedSlots = 40;
  next();
});

module.exports = mongoose.model('ParkingLot', parkingLotSchema);