const express = require('express');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-key-change-this';

// ========================================
// LOGIN ENDPOINT
// ========================================
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    console.log(`🔐 Login attempt for: ${username}`);
    
    // Validate input
    if (!username || !password) {
      return res.status(400).json({ 
        success: false,
        message: 'Username and password required' 
      });
    }

    // Find user
    const user = await User.findOne({ username });
    if (!user) {
      console.log(`❌ User not found: ${username}`);
      return res.status(401).json({ 
        success: false,
        message: 'Invalid credentials' 
      });
    }

    // Verify password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      console.log(`❌ Invalid password for: ${username}`);
      return res.status(401).json({ 
        success: false,
        message: 'Invalid credentials' 
      });
    }

    console.log(`✅ Login successful: ${username} (${user.role})`);

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, role: user.role }, 
      JWT_SECRET, 
      { expiresIn: '24h' }
    );

    // Return user data + token
    res.json({
      success: true,
      user: {
        id: user._id,
        username: user.username,
        role: user.role
      },
      token: token
    });

  } catch (err) {
    console.error('❌ Login error:', err);
    res.status(500).json({ 
      success: false,
      message: 'Server error during login' 
    });
  }
});

// ========================================
// REGISTER ENDPOINT
// ========================================
router.post('/register', async (req, res) => {
  try {
    const { username, password, role } = req.body;
    
    console.log(`📝 Registration attempt: ${username} as ${role}`);

    // Validate input
    if (!username || !password || !role) {
      return res.status(400).json({ 
        success: false,
        message: 'All fields required' 
      });
    }

    // Validate password strength
    if (password.length < 8) {
      return res.status(400).json({ 
        success: false,
        message: 'Password must be at least 8 characters' 
      });
    }

    // Validate role
    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid role. Must be "user" or "admin"' 
      });
    }

    // Check if user exists
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      console.log(`❌ Username already exists: ${username}`);
      return res.status(400).json({ 
        success: false,
        message: 'Username already exists' 
      });
    }

    // Create new user
    const user = new User({ 
      username, 
      password, 
      role 
    });
    
    await user.save();
    console.log(`✅ User registered: ${username} (${role})`);

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, role: user.role }, 
      JWT_SECRET, 
      { expiresIn: '24h' }
    );

    // Return user data + token
    res.status(201).json({
      success: true,
      user: {
        id: user._id,
        username: user.username,
        role: user.role
      },
      token: token
    });

  } catch (err) {
    console.error('❌ Registration error:', err);
    res.status(500).json({ 
      success: false,
      message: 'Server error during registration' 
    });
  }
});

// ========================================
// VERIFY TOKEN (Optional - for testing)
// ========================================
router.get('/verify', async (req, res) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false,
        message: 'No token provided' 
      });
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'User not found' 
      });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        username: user.username,
        role: user.role
      }
    });

  } catch (err) {
    res.status(401).json({ 
      success: false,
      message: 'Invalid token' 
    });
  }
});

module.exports = router;