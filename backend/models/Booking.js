// ============================================
// File: backend/models/Booking.js
// UPDATED WITH LIFT ASSIGNMENT FIELDS
// ============================================

const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  bookingId: {
    type: String,
    required: true,
    unique: true,
  },
  userId: {
    type: String,
    required: true,
  },
  vehicleNumber: {
    type: String,
    required: true,
  },
  vehicleType: {
    type: String,
    enum: ['CAR', 'BIKE'],
    default: 'CAR',
  },
  blockId: {
    type: String,
    required: true,
  },
  slotNumber: {
    type: String,
    required: true,
  },
  floor: {
    type: String,
    default: '2',
  },
  // ============================================
  // NEW: LIFT ASSIGNMENT FIELDS
  // ============================================
  assignedLift: {
    type: String,
    default: null,
  },
  liftNumber: {
    type: Number,
    default: null,
  },
  // ============================================
  status: {
    type: String,
    enum: ['payment_pending', 'paid', 'parked', 'completed', 'cancelled'],
    default: 'payment_pending',
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed'],
    default: 'pending',
  },
  transactionId: {
    type: String,
  },
  bookingTime: {
    type: Date,
    default: Date.now,
  },
  entryTime: {
    type: Date,
  },
  exitTime: {
    type: Date,
  },
  parkingCost: {
    type: Number,
    default: 0,
  },
}, {
  timestamps: true,
});

// Index for faster queries
bookingSchema.index({ userId: 1, status: 1 });
bookingSchema.index({ vehicleNumber: 1, status: 1 });
bookingSchema.index({ blockId: 1, status: 1 });
bookingSchema.index({ assignedLift: 1 }); // NEW INDEX

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;