// This file handles Razorpay payment creation
const Razorpay = require('razorpay');

// Initialize Razorpay (you'll get these keys from Razorpay dashboard)
const razorpay = new Razorpay({
  key_id: 'YOUR_RAZORPAY_KEY_ID',
  key_secret: 'YOUR_RAZORPAY_KEY_SECRET'
});

// Function to create a payment order
async function createPaymentOrder(amount, bookingId) {
  const options = {
    amount: amount * 100, // Razorpay takes amount in paise (₹100 = 10000 paise)
    currency: 'INR',
    receipt: `booking_${bookingId}`,
    notes: {
      bookingId: bookingId
    }
  };
  
  return await razorpay.orders.create(options);
}

module.exports = { createPaymentOrder };