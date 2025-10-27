// ============================================
// File: backend/routes/lifts.js
// ALL LIFT ENDPOINTS
// ============================================

const express = require('express');
const router = express.Router();
const Lift = require('../models/Lift');
const Booking = require('../models/Booking');

// ============================================
// 1. INITIALIZE LIFTS (ONE TIME SETUP)
// ============================================
router.post('/initialize', async (req, res) => {
  try {
    // Check if lifts already exist
    const existingLifts = await Lift.find();
    if (existingLifts.length > 0) {
      return res.status(200).json({
        message: 'Lifts already initialized',
        count: existingLifts.length,
        lifts: existingLifts
      });
    }

    // Create 8 lifts (2 per block)
    const blocks = ['BLOCK-A', 'BLOCK-B', 'BLOCK-C', 'BLOCK-D'];
    const liftsToCreate = [];

    blocks.forEach(block => {
      liftsToCreate.push(
        {
          liftId: `${block}-LIFT-1`,
          blockId: block,
          liftNumber: 1,
          status: 'available',
          sensorStatus: false,
          floor: 'Ground',
        },
        {
          liftId: `${block}-LIFT-2`,
          blockId: block,
          liftNumber: 2,
          status: 'available',
          sensorStatus: false,
          floor: 'Ground',
        }
      );
    });

    const createdLifts = await Lift.insertMany(liftsToCreate);
    
    res.status(201).json({
      message: '✅ Lifts initialized successfully',
      count: createdLifts.length,
      lifts: createdLifts
    });
  } catch (error) {
    console.error('Initialize lifts error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 2. GET ALL LIFTS
// ============================================
router.get('/', async (req, res) => {
  try {
    const lifts = await Lift.find().sort({ blockId: 1, liftNumber: 1 });
    res.json({ success: true, lifts });
  } catch (error) {
    console.error('Get lifts error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 3. GET LIFTS BY BLOCK
// ============================================
router.get('/block/:blockId', async (req, res) => {
  try {
    const { blockId } = req.params;
    const lifts = await Lift.find({ blockId }).sort({ liftNumber: 1 });
    
    if (lifts.length === 0) {
      return res.status(404).json({ 
        error: 'No lifts found for this block',
        blockId 
      });
    }
    
    res.json({ success: true, lifts });
  } catch (error) {
    console.error('Get lifts by block error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 4. AUTO-ASSIGN LIFT (MAIN LOGIC)
// ============================================
router.post('/assign', async (req, res) => {
  try {
    const { bookingId, blockId, vehicleNumber } = req.body;

    // Validate inputs
    if (!bookingId || !blockId || !vehicleNumber) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['bookingId', 'blockId', 'vehicleNumber']
      });
    }

    // Check if booking exists
    const booking = await Booking.findOne({ bookingId });
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Check if already assigned
    if (booking.assignedLift) {
      const existingLift = await Lift.findOne({ liftId: booking.assignedLift });
      return res.json({
        assigned: true,
        message: 'Lift already assigned',
        lift: existingLift,
        waitStatus: false
      });
    }

    // Find available lifts for this block
    const availableLifts = await Lift.find({
      blockId,
      status: 'available'
    }).sort({ lastActivity: 1 }); // Oldest first for fair distribution

    // No available lifts - WAIT MODE
    if (availableLifts.length === 0) {
      return res.json({
        assigned: false,
        waitStatus: true,
        message: 'Both lifts occupied. Please wait...',
        lift: null
      });
    }

    // Assign first available lift
    const selectedLift = availableLifts[0];
    selectedLift.status = 'occupied';
    selectedLift.currentBookingId = bookingId;
    selectedLift.currentVehicleNumber = vehicleNumber;
    selectedLift.assignedAt = new Date();
    selectedLift.lastActivity = new Date();
    await selectedLift.save();

    // Update booking
    booking.assignedLift = selectedLift.liftId;
    booking.liftAssignedAt = new Date();
    await booking.save();

    res.json({
      assigned: true,
      waitStatus: false,
      message: `Lift ${selectedLift.liftNumber} assigned successfully`,
      lift: selectedLift
    });

  } catch (error) {
    console.error('Assign lift error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 5. RELEASE LIFT (After vehicle pickup)
// ============================================
router.post('/release', async (req, res) => {
  try {
    const { liftId, bookingId } = req.body;

    if (!liftId) {
      return res.status(400).json({ error: 'liftId is required' });
    }

    const lift = await Lift.findOne({ liftId });
    if (!lift) {
      return res.status(404).json({ error: 'Lift not found' });
    }

    // Release the lift
    lift.status = 'available';
    lift.currentBookingId = null;
    lift.currentVehicleNumber = null;
    lift.releasedAt = new Date();
    lift.lastActivity = new Date();
    lift.sensorStatus = false;
    await lift.save();

    // Update booking if provided
    if (bookingId) {
      const booking = await Booking.findOne({ bookingId });
      if (booking) {
        booking.liftReleasedAt = new Date();
        await booking.save();
      }
    }

    res.json({
      success: true,
      message: 'Lift released successfully',
      lift
    });

  } catch (error) {
    console.error('Release lift error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 6. UPDATE LIFT STATUS (Admin/System)
// ============================================
router.put('/status/:liftId', async (req, res) => {
  try {
    const { liftId } = req.params;
    const { status } = req.body;

    const validStatuses = ['available', 'occupied', 'in_transit', 'maintenance'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        error: 'Invalid status',
        validStatuses
      });
    }

    const lift = await Lift.findOne({ liftId });
    if (!lift) {
      return res.status(404).json({ error: 'Lift not found' });
    }

    lift.status = status;
    lift.lastActivity = new Date();
    await lift.save();

    res.json({
      success: true,
      message: 'Lift status updated',
      lift
    });

  } catch (error) {
    console.error('Update lift status error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 7. UPDATE SENSOR STATUS (Hardware integration)
// ============================================
router.put('/sensor/:liftId', async (req, res) => {
  try {
    const { liftId } = req.params;
    const { sensorStatus, floor } = req.body;

    const lift = await Lift.findOne({ liftId });
    if (!lift) {
      return res.status(404).json({ error: 'Lift not found' });
    }

    if (typeof sensorStatus === 'boolean') {
      lift.sensorStatus = sensorStatus;
    }
    if (floor) {
      lift.floor = floor;
    }
    lift.lastActivity = new Date();
    await lift.save();

    res.json({
      success: true,
      message: 'Sensor status updated',
      lift
    });

  } catch (error) {
    console.error('Update sensor error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 8. GET LIFT BY ID
// ============================================
router.get('/:liftId', async (req, res) => {
  try {
    const { liftId } = req.params;
    const lift = await Lift.findOne({ liftId });
    
    if (!lift) {
      return res.status(404).json({ error: 'Lift not found' });
    }
    
    res.json({ success: true, lift });
  } catch (error) {
    console.error('Get lift error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 9. RESET ALL LIFTS (Admin only - for testing)
// ============================================
router.post('/reset', async (req, res) => {
  try {
    await Lift.updateMany(
      {},
      {
        $set: {
          status: 'available',
          currentBookingId: null,
          currentVehicleNumber: null,
          assignedAt: null,
          releasedAt: null,
          sensorStatus: false,
          floor: 'Ground',
          lastActivity: new Date()
        }
      }
    );

    const lifts = await Lift.find();
    
    res.json({
      success: true,
      message: 'All lifts reset to available',
      count: lifts.length,
      lifts
    });

  } catch (error) {
    console.error('Reset lifts error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;