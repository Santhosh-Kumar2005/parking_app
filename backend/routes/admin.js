const express = require('express');
const jwt = require('jsonwebtoken');
const ParkingLot = require('../models/ParkingLot');
const ParkingSpot = require('../models/ParkingSpot');
const Reservation = require('../models/Reservation');
const User = require('../models/User');
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-key-change-this';

const isAdmin = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    req.user = user;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

router.get('/summary', async (req, res) => {
  try {
    // Fetch all completed reservations with populations
    const reservations = await Reservation.find({ leavingTimestamp: { $ne: null } })
      .populate({
        path: 'spotId',
        select: 'lotId',
        populate: { path: 'lotId', select: 'primeLocationName' }
      })
      .populate('userId', 'username')
      .lean();

    // Fetch all lots and users for names
    const lots = await ParkingLot.find().lean();
    const users = await User.find().lean();

    const userRevenues = {};
    const lotRevenues = {};
    let totalRevenue = 0;

    for (const r of reservations) {
      const cost = (r.parkingCost && typeof r.parkingCost === 'number') ? r.parkingCost : 0;
      if (cost > 0) {
        totalRevenue += cost;

        // User revenue
        const uid = r.userId?._id?.toString() || 'unknown';
        if (!userRevenues[uid]) {
          const user = users.find(u => u._id.toString() === uid);
          userRevenues[uid] = {
            userId: uid,
            username: user ? user.username : 'Unknown',
            revenue: 0
          };
        }
        userRevenues[uid].revenue += cost;

        // Lot revenue
        const spot = r.spotId;
        if (spot && spot.lotId) {
          const lid = spot.lotId._id.toString();
          if (!lotRevenues[lid]) {
            const lot = lots.find(l => l._id.toString() === lid);
            lotRevenues[lid] = {
              lotId: lid,
              lotName: lot ? lot.primeLocationName : 'Unknown',
              revenue: 0
            };
          }
          lotRevenues[lid].revenue += cost;
        }
      }
    }

    // Spots summary
    const totalSpots = await ParkingSpot.countDocuments();
    const availableSpots = await ParkingSpot.countDocuments({ status: 'A' });
    const occupiedSpots = totalSpots - availableSpots;

    res.json({
      userRevenues: Object.values(userRevenues), // Array of {userId, username, revenue}
      lotRevenues: Object.values(lotRevenues), // Array of {lotId, lotName, revenue}
      totalRevenue: totalRevenue, // Matches frontend key
      occupiedSpots,
      availableSpots,
    });
  } catch (err) {
    console.error('Summary error:', err);
    res.status(500).json({ message: err.message });
  }
});

router.post('/lots', isAdmin, async (req, res) => {
  try {
    const { primeLocationName, price, address, pinCode, maximumNumberOfSpots } = req.body;
    if (!primeLocationName || !price || !address || !pinCode || !maximumNumberOfSpots) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    const lot = new ParkingLot(req.body);
    await lot.save();

    // Create spots with label
    for (let i = 1; i <= maximumNumberOfSpots; i++) {
      const label = lot.primeLocationName.charAt(0).toUpperCase() + '-' + i;
      const spot = new ParkingSpot({
        lotId: lot._id,
        spotIndex: i,
        status: 'A',
        label: label
      });
      await spot.save();
    }

    res.status(201).json(lot);
  } catch (err) {
    console.error('POST /lots error:', err);
    res.status(500).json({ message: err.message });
  }
});
router.put('/lots/:id', isAdmin, async (req, res) => {
  try {
    const lot = await ParkingLot.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!lot) return res.status(404).json({ message: 'Lot not found' });
    res.json(lot);
  } catch (err) {
    console.error('PUT /lots/:id error:', err);
    res.status(500).json({ message: err.message });
  }
});

router.delete('/lots/:id', isAdmin, async (req, res) => {
  try {
    const lot = await ParkingLot.findByIdAndDelete(req.params.id);
    if (!lot) return res.status(404).json({ message: 'Lot not found' });

    await ParkingSpot.deleteMany({ lotId: lot._id });
    await Reservation.deleteMany({ spotId: { $in: await ParkingSpot.find({ lotId: lot._id }, '_id') } });

    res.json({ message: 'Lot deleted' });
  } catch (err) {
    console.error('DELETE /lots/:id error:', err);
    res.status(500).json({ message: err.message });
  }
});

router.put('/reservations/:id/release', isAdmin, async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ message: 'userId is required' });
    }
    const reservation = await Reservation.findOne({ _id: req.params.id, userId, leavingTimestamp: null });
    if (!reservation) {
      return res.status(404).json({ message: 'Reservation not found or already released' });
    }

    const spot = await ParkingSpot.findById(reservation.spotId).populate('lotId');
    if (!spot || !spot.lotId) {
      return res.status(400).json({ message: 'Invalid spot or lot' });
    }
    const lot = spot.lotId;

    const now = new Date();
    const parkingTime = new Date(reservation.parkingTimestamp);
    if (isNaN(parkingTime.getTime()) || parkingTime > now) {
      return res.status(400).json({ message: 'Invalid parking timestamp' });
    }
    let duration = (now - parkingTime) / (1000 * 60 * 60);
    duration = Math.max(duration, 1 / 60);

    const pricePerHour = lot.price || 2;
    const parkingCost = duration * pricePerHour;

    reservation.parkingCost = parkingCost;
    reservation.leavingTimestamp = now;
    await reservation.save();

    spot.status = 'A';
    await spot.save();

    res.json({ ...reservation.toObject(), cost: parkingCost });
  } catch (err) {
    console.error('Release spot error:', err.message);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;