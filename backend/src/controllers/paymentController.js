const Razorpay = require('razorpay');
const crypto = require('crypto');
const Group = require('../models/Group');
const groupController = require('./groupController'); // Re-use settleUp logic if possible, or replicate safely

// Initialize Razorpay
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

// @desc    Create Razorpay Order
// @route   POST /api/payment/create-order
// @access  Private
exports.createOrder = async (req, res) => {
    try {
        console.log('createOrder hit with body:', req.body); // Debug Log
        const { amount, currency = 'INR', receipt, notes } = req.body;

        if (!amount) {
            return res.status(400).json({
                success: false,
                message: 'Amount is required'
            });
        }

        const options = {
            amount: Math.round(amount * 100), // Razorpay works in smallest currency unit (paise) and requires Integer
            currency,
            receipt: (receipt || `receipt_${Date.now()}`).toString().slice(0, 40),
            notes: notes || {}
        };

        const order = await razorpay.orders.create(options);

        res.json({
            success: true,
            data: order
        });
    } catch (error) {
        console.error('Razorpay Order Error:', error);
        res.status(500).json({
            success: false,
            message: error.error && error.error.description ? error.error.description : 'Something went wrong creating the order',
            error: error.message
        });
    }
};

// @desc    Verify Razorpay Payment
// @route   POST /api/payment/verify
// @access  Private
exports.verifyPayment = async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature,
            groupId,
            fromUserId,
            toUserId,
            amount // In original currency (e.g., INR) to settle
        } = req.body;

        // Verify Signature
        const body = razorpay_order_id + "|" + razorpay_payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body.toString())
            .digest('hex');

        if (expectedSignature !== razorpay_signature) {
            return res.status(400).json({
                success: false,
                message: 'Invalid payment signature'
            });
        }

        // Payment is legit. Now execute the settlement logic.
        // We can replicate the logic from groupController.settleUp here or call it internally if refactored.
        // For now, let's look up the group and update balances directly to ensure atomicity with payment verification.

        const group = await Group.findById(groupId);

        if (!group) {
            return res.status(404).json({
                success: false,
                message: 'Group not found for settlement'
            });
        }

        // Update balances
        const fromIndex = group.members.findIndex(m => m.userId === fromUserId);
        const toIndex = group.members.findIndex(m => m.userId === toUserId);

        if (fromIndex !== -1 && toIndex !== -1) {
            group.members[fromIndex].amountOwed = Math.max(0, group.members[fromIndex].amountOwed - amount);
            group.members[toIndex].amountLent = Math.max(0, group.members[toIndex].amountLent - amount);

            await Group.updateById(groupId, { members: group.members });
        }

        res.json({
            success: true,
            message: 'Payment verified and settlement processed',
            data: {
                paymentId: razorpay_payment_id,
                settlementAmount: amount
            }
        });

    } catch (error) {
        console.error('Payment Verification Error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error during verification',
            error: error.message
        });
    }
};
// @desc    Get Razorpay Key ID
// @route   GET /api/payment/key
// @access  Private
exports.getRazorpayKey = (req, res) => {
    res.json({
        success: true,
        key: process.env.RAZORPAY_KEY_ID
    });
};
