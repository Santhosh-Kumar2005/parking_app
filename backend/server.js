const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// ========================================
// MIDDLEWARE
// ========================================
app.use(cors());
app.use(express.json());

// Request logging (simplified)
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
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
// ROUTES - ORDER MATTERS!
// ========================================

// Import routes
const adminRoutes = require('./routes/admin');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const bookingRoutes = require('./routes/bookings');

// Register routes - ORDER MATTERS!
app.use('/auth', authRoutes);                    
app.use('/api/admin', adminRoutes);              
app.use('/api/bookings', bookingRoutes);         
app.use('/bookings', bookingRoutes);             // Support both /bookings and /api/bookings
app.use('/api', userRoutes);                     

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: '🚀 Smart Parking API Running',
    version: '2.1.0',
    status: 'OK',
    endpoints: {
      auth: {
        login: 'POST /auth/login',
        register: 'POST /auth/register'
      },
      bookings: {
        list: 'GET /api/bookings OR /bookings',
        stats: 'GET /api/bookings/parking-stats OR /bookings/parking-stats',
        create: 'POST /api/bookings OR /bookings',
        userBookings: 'GET /api/bookings/user/:userId OR /bookings/user/:userId'
      },
      parking: {
        lots: 'GET /api/lots',
        spots: 'GET /api/spots/details'
      }
    }
  });
});

// ========================================
// 404 HANDLER - MUST BE LAST!
// ========================================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.path}`,
    hint: 'Check GET / for available endpoints'
  });
});

// ========================================
// START SERVER
// ========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('========================================');
  console.log('🚀 Smart Parking Server Started!');
  console.log('========================================');
  console.log(`📡 Server: http://localhost:${PORT}`);
  console.log(`🔐 Auth: http://localhost:${PORT}/auth/login`);
  console.log(`📊 Stats: http://localhost:${PORT}/bookings/parking-stats`);
  console.log(`🅿️  Lots: http://localhost:${PORT}/api/lots`);
  console.log('========================================');
  console.log('✅ Both /bookings and /api/bookings work!');
  console.log('========================================');
  console.log('Press Ctrl+C to stop\n');
});