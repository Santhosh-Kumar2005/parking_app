const express = require('express');
const User = require('../models/User');
const jwt = require('jsonwebtoken'); // For JWT
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-key-change-this'; // Add to .env

router.post('/login', async (req, res) => {
  try {
    // Mask password immediately
    const { username, password } = req.body;
    const maskedPassword = password ? password.replace(/./g, '#') : '########';
    const maskedBody = { ...req.body, password: maskedPassword };

    // Log username only and masked body
    console.log('Login attempt:', username);
    console.log('POST /api/auth/login - Body:', JSON.stringify(maskedBody));

    const user = await User.findOne({ username });
    if (!user || !(await user.comparePassword(password))) {
      console.log('Login failed for', username);
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    console.log('Login success for', user.username, 'role:', user.role);
    // Generate JWT
    const token = jwt.sign({ userId: user._id, role: user.role }, JWT_SECRET, { expiresIn: '1h' });
    res.json({ ...user.toObject(), token }); // Return user + token
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Register - Return JWT
router.post('/register', async (req, res) => {
  try {
    const { username, password, role } = req.body;
    console.log('Register attempt:', username, role); // Debug
    if (password.length < 8 || !/^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!]{7,15}$/.test(password)) {
      return res.status(400).json({ message: 'Invalid password format' });
    }
    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ message: 'Username exists' });
    }
    const user = new User({ username, password, role });
    await user.save();
    console.log('Registered user:', user.username, 'role:', user.role); // Debug
    // Generate JWT
    const token = jwt.sign({ userId: user._id, role: user.role }, JWT_SECRET, { expiresIn: '1h' });
    res.status(201).json({ ...user.toObject(), token });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;