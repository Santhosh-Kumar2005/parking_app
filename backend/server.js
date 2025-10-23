// backend/server.js (Fixed: Mount adminRoutes under /api/admin so public /api/* user endpoints work)
require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const userRoutes = require('./routes/user');
const paymentRoutes = require('./routes/payment');

const app = express();
const PORT = process.env.PORT || 3000;

mongoose.set('strictQuery', false);

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/parking';
mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB Atlas!');
  })
  .catch(err => console.error('MongoDB connection error:', err));

// Middleware
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Global logger
app.use((req, res, next) => {
  // Mask password in body before logging
  const body = { ...req.body };
  if (body.password) {
    body.password = body.password.replace(/./g, '#');
  }
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - Body: ${JSON.stringify(body)}`);

  const oldSend = res.json;
  res.json = function(data) {
    console.log(`${req.method} ${req.path} - Status: ${res.statusCode} - Data: ${JSON.stringify(data)}`);
    return oldSend.call(this, data);
  };
  next();
});

// Routes - FIXED: Mount adminRoutes under /api/admin so public /api/* user endpoints work
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes); // admin-only endpoints moved to /api/admin
app.use('/api', userRoutes); // public /api/lots, /api/spots/details, /api/summary and /api/reservations (protected where needed)
app.use('/api/payment', paymentRoutes);
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (req, res) => res.json({ status: 'OK', connected: mongoose.connection.readyState === 1 }));

app.listen(PORT, () => {
  console.log(`Server on port ${PORT}`);
  console.log('Test: http://localhost:3000/api/lots');
});