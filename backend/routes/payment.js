const express = require('express');
const router = express.Router();
const { createPaymentOrder } = require('../payment/razorpay');
const Booking = require('../models/Booking');

// Create payment order when user wants to book
router.post('/create-order', async (req, res) => {
  try {
    const { bookingId, amount } = req.body;
    
    // Create Razorpay order
    const order = await createPaymentOrder(amount, bookingId);
    
    // Update booking with order ID
    await Booking.findByIdAndUpdate(bookingId, {
      orderId: order.id,
      paymentAmount: amount
    });
    
    res.json({
      success: true,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Verify payment after user completes payment
router.post('/verify-payment', async (req, res) => {
  try {
    const { paymentId, orderId, bookingId } = req.body;
    
    // Update booking with payment details
    await Booking.findByIdAndUpdate(bookingId, {
      paymentId: paymentId,
      paymentStatus: 'completed'
    });
    
    res.json({ success: true, message: 'Payment verified' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;