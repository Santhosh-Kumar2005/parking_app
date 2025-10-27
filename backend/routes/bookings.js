// ============================================
// File: backend/routes/bookings.js
// FIXED - Removed unused Reservation import
// ============================================

const express = require('express');
const router = express.Router();
const Booking = require('../models/Booking');
const ParkingLot = require('../models/ParkingLot');

// ============================================
// GET ALL BOOKINGS
// ============================================
router.get('/', async (req, res) => {
  try {
    const bookings = await Booking.find().sort({ bookingTime: -1 });
    res.json({
      success: true,
      bookings: bookings
    });
  } catch (error) {
    console.error('Error fetching bookings:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// GET PARKING STATISTICS (REAL-TIME)
// ============================================
router.get('/parking-stats', async (req, res) => {
  try {
    // Count active bookings (payment_pending, paid, parked)
    const activeBookings = await Booking.countDocuments({
      status: { $in: ['payment_pending', 'paid', 'parked'] }
    });
    
    // Calculate totals
    const totalSlots = 160;
    const occupiedSlots = activeBookings;
    const availableSlots = totalSlots - occupiedSlots;
    
    // Get block-wise breakdown
    const blockStats = await Booking.aggregate([
      {
        $match: { 
          status: { $in: ['payment_pending', 'paid', 'parked'] } 
        }
      },
      {
        $group: {
          _id: '$blockId',
          count: { $sum: 1 }
        }
      }
    ]);
    
    res.json({
      success: true,
      stats: {
        total: totalSlots,
        occupied: occupiedSlots,
        available: availableSlots,
        blocks: blockStats
      }
    });
    
  } catch (error) {
    console.error('Error fetching parking stats:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// GET USER'S ACTIVE BOOKINGS
// ============================================
router.get('/user/:userId', async (req, res) => {
  try {
    const bookings = await Booking.find({
      userId: req.params.userId,
      status: { $in: ['payment_pending', 'paid', 'parked'] }
    }).sort({ bookingTime: -1 });
    
    res.json({
      success: true,
      bookings: bookings
    });
  } catch (error) {
    console.error('Error fetching user bookings:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// CREATE NEW BOOKING
// ============================================
router.post('/', async (req, res) => {
  try {
    const { userId, vehicleNumber, blockId, slotNumber, floor } = req.body;
    
    // Validate required fields
    if (!userId || !vehicleNumber || !blockId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }
    
    // Check if vehicle already has active booking
    const existingBooking = await Booking.findOne({
      vehicleNumber: vehicleNumber,
      status: { $in: ['payment_pending', 'paid', 'parked'] }
    });
    
    if (existingBooking) {
      return res.status(400).json({
        success: false,
        message: 'Vehicle already has an active booking'
      });
    }
    
    // Check available slots
    const blockBookings = await Booking.countDocuments({
      blockId: blockId,
      status: { $in: ['payment_pending', 'paid', 'parked'] }
    });
    
    if (blockBookings >= 40) {
      return res.status(400).json({
        success: false,
        message: 'No available slots in this block'
      });
    }
    
    // Generate unique booking ID
    const bookingId = 'BK' + Date.now() + Math.floor(Math.random() * 1000);
    
    // Create booking
    const booking = new Booking({
      bookingId: bookingId,
      userId: userId,
      vehicleNumber: vehicleNumber.toUpperCase(),
      blockId: blockId,
      slotNumber: slotNumber || 'AUTO-' + (blockBookings + 1),
      floor: floor || '2',
      status: 'payment_pending',
      bookingTime: new Date(),
      paymentStatus: 'pending'
    });
    
    await booking.save();
    
    res.status(201).json({
      success: true,
      booking: booking,
      message: 'Booking created successfully'
    });
    
  } catch (error) {
    console.error('Booking creation error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// UPDATE PAYMENT STATUS
// ============================================
router.put('/:id/payment', async (req, res) => {
  try {
    const { paymentStatus, transactionId } = req.body;
    
    const booking = await Booking.findById(req.params.id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Update payment status
    booking.paymentStatus = paymentStatus;
    
    if (paymentStatus === 'paid') {
      booking.status = 'paid';
      booking.entryTime = new Date();
      if (transactionId) {
        booking.transactionId = transactionId;
      }
    }
    
    await booking.save();
    
    res.json({
      success: true,
      booking: booking,
      message: 'Payment updated successfully'
    });
    
  } catch (error) {
    console.error('Payment update error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// RELEASE/EXIT PARKING
// ============================================
router.post('/:id/release', async (req, res) => {
  try {
    const { vehicleType } = req.body; // 'CAR' or 'BIKE'
    
    const booking = await Booking.findById(req.params.id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    if (booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Booking already completed'
      });
    }
    
    // Calculate parking duration
    const entryTime = new Date(booking.entryTime || booking.bookingTime);
    const exitTime = new Date();
    const durationInHours = (exitTime - entryTime) / (1000 * 60 * 60);
    
    // Base charges (1 hour)
    const baseCharge = vehicleType === 'CAR' ? 50 : 25;
    const extensionRate = vehicleType === 'CAR' ? 30 : 15; // per 30 mins
    
    let totalCost = baseCharge;
    
    // Calculate extension charges if duration > 1 hour
    if (durationInHours > 1) {
      const extraTime = durationInHours - 1; // Hours beyond first hour
      const extraSlots = Math.ceil(extraTime * 2); // Convert to 30-min slots
      totalCost += extraSlots * extensionRate;
    }
    
    // Update booking
    booking.status = 'completed';
    booking.exitTime = exitTime;
    booking.parkingCost = totalCost;
    booking.vehicleType = vehicleType;
    
    await booking.save();
    
    res.json({
      success: true,
      booking: booking,
      cost: totalCost,
      duration: durationInHours.toFixed(2),
      message: 'Parking released successfully'
    });
    
  } catch (error) {
    console.error('Release error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// UPDATE BOOKING (Status updates)
// ============================================
router.put('/:id', async (req, res) => {
  try {
    const { status, paymentStatus, entryTime, exitTime } = req.body;
    
    const booking = await Booking.findById(req.params.id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Update fields
    if (status) booking.status = status;
    if (paymentStatus) booking.paymentStatus = paymentStatus;
    if (entryTime) booking.entryTime = entryTime;
    if (exitTime) booking.exitTime = exitTime;
    
    await booking.save();
    
    res.json({
      success: true,
      booking: booking,
      message: 'Booking updated successfully'
    });
    
  } catch (error) {
    console.error('Booking update error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// CANCEL BOOKING (Releases slot)
// ============================================
router.delete('/:id', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Only release slot if booking was active
    if (['payment_pending', 'paid', 'parked'].includes(booking.status)) {
      // Update status to cancelled
      booking.status = 'cancelled';
      await booking.save();
    }
    
    res.json({
      success: true,
      message: 'Booking cancelled and slot released'
    });
    
  } catch (error) {
    console.error('Booking cancellation error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// ============================================
// COMPLETE BOOKING (After vehicle exits)
// ============================================
router.post('/:id/complete', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Update booking status
    booking.status = 'completed';
    booking.exitTime = new Date();
    await booking.save();
    
    res.json({
      success: true,
      booking: booking,
      message: 'Booking completed and slot released'
    });
    
  } catch (error) {
    console.error('Booking completion error:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

module.exports = router;