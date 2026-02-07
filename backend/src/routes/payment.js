const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth'); // Assuming you have auth middleware
const { createOrder, verifyPayment, getRazorpayKey } = require('../controllers/paymentController');

router.get('/key', protect, getRazorpayKey);
router.post('/create-order', protect, createOrder);
router.post('/verify', protect, verifyPayment);

module.exports = router;
