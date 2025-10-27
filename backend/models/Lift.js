// ============================================
// File: backend/models/Lift.js
// LIFT MANAGEMENT MODEL
// ============================================

const mongoose = require('mongoose');

const liftSchema = new mongoose.Schema({
  liftId: {
    type: String,
    required: true,
    unique: true,
  },
  blockId: {
    type: String,
    required: true,
    enum: ['BLOCK-A', 'BLOCK-B', 'BLOCK-C', 'BLOCK-D'],
  },
  liftNumber: {
    type: Number,
    required: true,
    enum: [1, 2],
  },
  status: {
    type: String,
    enum: ['available', 'occupied', 'in_transit', 'maintenance'],
    default: 'available',
  },
  currentBookingId: {
    type: String,
    default: null,
  },
  currentVehicleNumber: {
    type: String,
    default: null,
  },
  assignedAt: {
    type: Date,
    default: null,
  },
  releasedAt: {
    type: Date,
    default: null,
  },
  sensorStatus: {
    type: Boolean,
    default: false, // false = no car, true = car present
  },
  floor: {
    type: String,
    default: 'Ground',
  },
  lastActivity: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Index for faster queries
liftSchema.index({ blockId: 1, status: 1 });
liftSchema.index({ liftId: 1 });

const Lift = mongoose.model('Lift', liftSchema);

module.exports = Lift;