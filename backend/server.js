const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// ========================================
// MIDDLEWARE
// ========================================
app.use(cors({
  origin: '*', // Allow Firebase and all origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// ========================================
// DATABASE CONNECTION
// ========================================
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => {
  console.log('✅ Connected to MongoDB Atlas!');
})
.catch(err => {
  console.error('❌ MongoDB Error:', err.message);
  process.exit(1);
});

// ========================================
// IMPORT ROUTES
// ========================================
const adminRoutes = require('./routes/admin');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const bookingRoutes = require('./routes/bookings');
const liftRoutes = require('./routes/lifts'); // ⭐ NEW LIFT ROUTES

// ========================================
// ROOT TEST ROUTE
// ========================================
app.get('/', (req, res) => {
  res.json({ 
    message: '🚗 Parking App API Running',
    status: 'active',
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: '/auth/login, /auth/register',
      parkingLots: '/parking-lots',
      parkingSpots: '/parking-spots',
      bookings: '/bookings',
      lifts: '/lifts', // ⭐ NEW
      summary: '/summary'
    }
  });
});

// ========================================
// REGISTER ROUTES - EXACT MATCH TO FRONTEND
// ========================================

// Auth routes (✅ Frontend calls: /auth/login, /auth/register)
app.use('/auth', authRoutes);

// Parking Lots routes (✅ Frontend calls: /parking-lots)
app.get('/parking-lots', adminRoutes);
app.post('/parking-lots', adminRoutes);
app.put('/parking-lots/:id', adminRoutes);
app.delete('/parking-lots/:id', adminRoutes);

// Parking Spots routes (✅ Frontend calls: /parking-spots/details, /parking-spots/:id)
app.get('/parking-spots/details', adminRoutes);
app.get('/parking-spots/:spotId', adminRoutes);

// Summary route (✅ Frontend calls: /summary)
app.get('/summary', adminRoutes);

// Booking routes (✅ Frontend calls: /bookings/*)
app.use('/bookings', bookingRoutes);

// ⭐ LIFT ROUTES (NEW - Frontend calls: /lifts/*)
app.use('/lifts', liftRoutes);

// User routes (if needed)
app.use('/users', userRoutes);

// ========================================
// 404 HANDLER
// ========================================
app.use((req, res) => {
  console.log(`❌ 404 Not Found: ${req.method} ${req.path}`);
  res.status(404).json({ 
    error: 'Route not found',
    path: req.path,
    method: req.method,
    availableRoutes: ['/auth', '/parking-lots', '/parking-spots', '/bookings', '/lifts', '/summary']
  });
});

// ========================================
// ERROR HANDLER
// ========================================
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Internal server error',
    message: err.message 
  });
});

// ========================================
// START SERVER
// ========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 CORS enabled for all origins`);
  console.log(`⭐ Lift system enabled on /lifts`);
});