// backend/routes/user.js
const express = require('express');
const jwt = require('jsonwebtoken');
const ParkingSpot = require('../models/ParkingSpot');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const ParkingLot = require('../models/ParkingLot');
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-key-change-this';

// Middleware to check user (JWT)
const isUser = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ message: 'No token, authorization denied' });
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user || user.role !== 'user') return res.status(403).json({ message: 'User access required' });
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token is not valid' });
  }
};

// Public: Get lots (no auth) - same as previous user GET /lots
// backend/routes/user.js (updated GET /lots to auto-create missing spots)
router.get('/lots', async (req, res) => {
  try {
    const { query } = req.query;
    let filter = {};
    if (query) {
      filter.primeLocationName = { $regex: query, $options: 'i' };
    }
    const lots = await ParkingLot.find(filter).lean();

    for (let lot of lots) {
      // Step 1: Get current available count
      let availableSpots = await ParkingSpot.countDocuments({ lotId: lot._id, status: 'A' });

      // Step 2: Idempotent creation - ensure spots 1 to max exist
      const existingIndices = await ParkingSpot.distinct('spotIndex', { lotId: lot._id });
      const missingIndices = [];
      for (let i = 1; i <= lot.maximumNumberOfSpots; i++) {
        if (!existingIndices.includes(i)) {
          missingIndices.push(i);
        }
      }

      if (missingIndices.length > 0) {
        console.log(`Creating ${missingIndices.length} missing spots for lot "${lot.primeLocationName}": indices ${missingIndices.join(', ')}`);
        for (let i of missingIndices) {
          const label = lot.primeLocationName.charAt(0).toUpperCase() + '-' + i;
          const spot = new ParkingSpot({
            lotId: lot._id,
            spotIndex: i,
            status: 'A',
            label: label
          });
          await spot.save(); // Unique index prevents duplicates
        }
        // New spots are 'A', so add to available
        availableSpots += missingIndices.length;
      }

      // Step 3: Cap available at max (safety for any extras)
      const cappedAvailable = Math.min(availableSpots, lot.maximumNumberOfSpots);
      lot.availability = `${cappedAvailable}/${lot.maximumNumberOfSpots}`;

      // Optional: Log extras if total > max
      const totalSpots = await ParkingSpot.countDocuments({ lotId: lot._id });
      if (totalSpots > lot.maximumNumberOfSpots) {
        console.warn(`Lot "${lot.primeLocationName}" has ${totalSpots} spots > max ${lot.maximumNumberOfSpots}; consider manual cleanup.`);
      }
    }

    res.json(lots);
  } catch (err) {
    console.error('GET /lots error:', err);
    res.status(500).json({ message: err.message });
  }
});

// backend/routes/user.js (spots/details section)
router.get('/spots/details', async (req, res) => {
  try {
    const spots = await ParkingSpot.aggregate([
      {
        $lookup: {
          from: 'parkinglots',
          localField: 'lotId',
          foreignField: '_id',
          as: 'lot',
        },
      },
      { $unwind: '$lot' },
      {
        $lookup: {
          from: 'reservations',
          let: { spotId: '$_id' },
          pipeline: [
            {
              $match: {
                $expr: { $eq: ['$spotId', '$$spotId'] },
                leavingTimestamp: { $eq: null },
              },
            },
            { $limit: 1 },
          ],
          as: 'currentReservation',
        },
      },
      { $unwind: { path: '$currentReservation', preserveNullAndEmptyArrays: true } },
      {
        $addFields: {
          status: { $cond: [{ $ifNull: ['$currentReservation', false] }, 'O', 'A'] },
          vehicleNumber: { $ifNull: ['$currentReservation.vehicleNumber', null] },
          label: {
            $concat: [
              { $toUpper: { $substr: ['$lot.primeLocationName', 0, 1] }},
              '-',
              { $toString: { $ifNull: ['$spotIndex', 1] }}, // Fallback to 1 if spotIndex missing
            ],
          },
        },
      },
      {
        $project: {
          _id: 1,
          lotId: '$lot._id',
          status: 1,
          label: 1,
          vehicleNumber: 1,
          primeLocationName: '$lot.primeLocationName',
          price: '$lot.price',
          address: '$lot.address',
          pinCode: '$lot.pinCode',
        },
      },
      { $sort: { 'lot.primeLocationName': 1, spotIndex: 1 } },
    ]);

    if (spots.length === 0) {
      console.log('No spots found in aggregate; falling back to simple query');
      const basicSpots = await ParkingSpot.find()
        .populate('lotId', 'primeLocationName price address pinCode')
        .lean();
      const fallbackSpots = basicSpots.map(s => ({
        _id: s._id,
        lotId: s.lotId._id,
        status: 'A',
        label: `${s.lotId.primeLocationName.charAt(0).toUpperCase()}-${s.spotIndex || 1}`,
        vehicleNumber: null,
        primeLocationName: s.lotId.primeLocationName,
        price: s.lotId.price,
        address: s.lotId.address,
        pinCode: s.lotId.pinCode,
      }));
      return res.json(fallbackSpots);
    }

    console.log(`Fetched ${spots.length} spots with details`);
    res.json(spots);
  } catch (err) {
    console.error('Spots/details aggregate error:', err);
    res.status(200).json([]); // Return empty array on error
  }
});

// Public: summary (no auth)
router.get('/summary', async (req, res) => {
  try {
    const totalSpots = await ParkingSpot.countDocuments();
    const occupiedSpots = await ParkingSpot.countDocuments({ status: 'O' });
    const availableSpots = totalSpots - occupiedSpots;
    res.json({ occupiedSpots, availableSpots });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/reservations', isUser, async (req, res) => {
  try {
    // Use authenticated user id from middleware, ignore any userId in the body
    const userId = req.user._id;
    const { lotId, vehicleNumber } = req.body;

    if (!lotId || !vehicleNumber) {
      return res.status(400).json({ message: 'Missing lotId or vehicleNumber' });
    }

    // Vehicle validation (adjust regexp to your needs)
    if (!/^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$/.test(vehicleNumber)) {
      return res.status(400).json({ message: 'Invalid vehicle number format' });
    }

    // Find available spot and populate lot for potential label computation
    const availableSpot = await ParkingSpot.findOne({ lotId, status: 'A' }).populate('lotId');
    if (!availableSpot) {
      return res.status(400).json({ message: 'No available spots in this lot' });
    }

    // Backfill label if missing (for legacy spots)
    if (!availableSpot.label) {
      if (!availableSpot.lotId || !availableSpot.lotId.primeLocationName) {
        return res.status(500).json({ message: 'Unable to compute spot label' });
      }
      availableSpot.label = availableSpot.lotId.primeLocationName.charAt(0).toUpperCase() + '-' + availableSpot.spotIndex;
    }

    // Update spot status
    availableSpot.status = 'O';
    await availableSpot.save();

    // Create reservation
    const reservation = new Reservation({
      spotId: availableSpot._id,
      userId,
      vehicleNumber,
      parkingTimestamp: new Date(),
    });

    await reservation.save();

    // Return populated reservation (spot and lot info optional)
    const populated = await Reservation.findById(reservation._id)
      .populate({
        path: 'spotId',
        select: 'lotId spotIndex label',
        populate: { path: 'lotId', select: 'primeLocationName price' }
      })
      .lean();

    res.status(201).json(populated || reservation);
  } catch (err) {
    console.error('POST /reservations error:', err);
    res.status(500).json({ message: err.message });
  }
});

router.put('/reservations/:id/release', isUser, async (req, res) => {
  try {
    const reservation = await Reservation.findById(req.params.id);
    if (!reservation || reservation.userId.toString() !== req.user._id.toString() || reservation.leavingTimestamp) {
      return res.status(404).json({ message: 'Reservation not found or already released' });
    }
    const spot = await ParkingSpot.findById(reservation.spotId).populate('lotId');
    if (!spot || !spot.lotId) {
      return res.status(400).json({ message: 'Invalid spot or lot' });
    }
    const lot = await ParkingLot.findById(spot.lotId._id);

    // Set leaving timestamp FIRST
    const now = new Date();
    reservation.leavingTimestamp = now;

    // Calculate duration (with min 1 min to avoid zero-cost releases)
    const parkingTime = new Date(reservation.parkingTimestamp);
    let duration = (now - parkingTime) / (1000 * 60 * 60); // hours
    duration = Math.max(duration, 1 / 60); // min 1 min

    const pricePerHour = lot.price || 2;
    reservation.parkingCost = duration * pricePerHour;

    // Update spot status
    spot.status = 'A';
    await spot.save();
    await reservation.save();

    res.json({ message: 'Released', cost: reservation.parkingCost });
  } catch (err) {
    console.error('PUT /reservations/:id/release error:', err);
    res.status(500).json({ message: err.message });
  }
});

router.get('/reservations', isUser, async (req, res) => {
  try {
    const reservations = await Reservation.find({ userId: req.user._id })
      .sort({ parkingTimestamp: -1 })
      .populate({
        path: 'spotId',
        select: 'lotId spotIndex label',
        populate: { path: 'lotId', select: 'primeLocationName' }
      })
      .lean();

    // Enhanced safe handling for lot info
    for (let r of reservations) {
      const spot = r.spotId;
      if (spot && spot.lotId && spot.lotId.primeLocationName) {
        r.lotId = spot.lotId._id.toString();
        r.lotName = spot.lotId.primeLocationName;
      } else {
        // Fallback: Query lot directly if population failed
        if (spot && spot.lotId) {
          const fallbackLot = await ParkingLot.findById(spot.lotId).select('primeLocationName').lean();
          if (fallbackLot) {
            r.lotId = spot.lotId.toString();
            r.lotName = fallbackLot.primeLocationName;
          }
        }
        if (!r.lotName) {
          r.lotId = null;
          r.lotName = 'N/A';
        }
      }
    }

    res.json(reservations);
  } catch (err) {
    console.error('GET /reservations error:', err);
    res.status(500).json({ message: err.message });
  }
});

router.get('/revenue/summary', async (req, res) => {
  try {
    const reservations = await Reservation.find({ leavingTimestamp: { $ne: null } })
      .populate({
        path: 'spotId',
        select: 'lotId',
        populate: { path: 'lotId', select: 'primeLocationName' }
      })
      .lean();

    const userRevenues = {};
    const lotRevenues = {};
    let totalRevenue = 0;

    for (const r of reservations) {
      const cost = (r.parkingCost && typeof r.parkingCost === 'number') ? r.parkingCost : 0;
      totalRevenue += cost;

      const uid = r.userId ? r.userId.toString() : 'unknown';
      userRevenues[uid] = (userRevenues[uid] || 0) + cost;

      // Derive lot id safely from populated spotId.lotId
      let lid = 'unknown';
      if (r.spotId && r.spotId.lotId) {
        lid = r.spotId.lotId._id ? r.spotId.lotId._id.toString() : (r.spotId.lotId.toString ? r.spotId.lotId.toString() : 'unknown');
      }
      lotRevenues[lid] = (lotRevenues[lid] || 0) + cost;
    }

    res.json({ userRevenues, lotRevenues, totalRevenue });
  } catch (err) {
    console.error('GET /revenue/summary error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Public: single spot details
router.get('/spots/:id/details', async (req, res) => {
  try {
    const id = req.params.id;
    const mongoose = require('mongoose');
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid spot id' });
    }

    const spot = await ParkingSpot.findById(id).lean();
    if (!spot) return res.status(404).json({ message: 'Spot not found' });

    const lot = await ParkingLot.findById(spot.lotId).lean();
    const reservation = await Reservation.findOne({
      spotId: spot._id,
      leavingTimestamp: null,
    }).lean();

    let user = null;
    if (reservation && reservation.userId) {
      user = await User.findById(reservation.userId).lean();
    }

    const result = {
      id: spot._id.toString(),
      lotId: spot.lotId ? spot.lotId.toString() : null,
      status: spot.status ?? 'A',
      label: spot.label ?? (spot.spotIndex ? `${lot ? lot.primeLocationName.charAt(0).toUpperCase() : 'Lot'}-${spot.spotIndex}` : null),
      lotName: lot ? lot.primeLocationName : null,
      price: lot ? lot.price : null,
      vehicleNumber: reservation ? reservation.vehicleNumber : null,
      parkingTimestamp: reservation ? reservation.parkingTimestamp : null,
      leavingTimestamp: reservation ? reservation.leavingTimestamp : null,
      parkingCost: reservation ? reservation.parkingCost : null,
      userId: user ? user._id.toString() : null,
      username: user ? user.username : null,
    };

    return res.json(result);
  } catch (err) {
    console.error('GET /spots/:id/details error:', err);
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;