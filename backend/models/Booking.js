// Add these fields to your existing Booking schema
const mongoose = require('mongoose');
const BookingSchema = new mongoose.Schema({
  // ... your existing fields ...
  
  // ADD THESE NEW FIELDS:
  paymentStatus: {
    type: String,
    enum: ['pending', 'completed', 'failed'],
    default: 'pending'
  },
  paymentId: {
    type: String,
    default: null
  },
  orderId: {
    type: String,
    default: null
  },
  paymentAmount: {
    type: Number,
    required: true
  },
  qrCode: {
    type: String, // Will store QR code image as base64
    default: null
  }
});


