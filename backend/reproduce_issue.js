require('dotenv').config();
const Razorpay = require('razorpay');

async function testRazorpay() {
    console.log('Testing Razorpay Order Creation...');
    console.log('Key ID:', process.env.RAZORPAY_KEY_ID ? 'Present' : 'Missing');
    console.log('Key Secret:', process.env.RAZORPAY_KEY_SECRET ? 'Present' : 'Missing');

    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
        console.error('ERROR: Missing Razorpay keys in .env');
        return;
    }

    try {
        const razorpay = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET
        });

        const order = await razorpay.orders.create({
            amount: Math.round(50012.345 * 100), // Rounded to integer: 5001235
            currency: 'INR',
            receipt: 'test_receipt_FIXED',
            notes: { test: 'true' }
        });
        console.log('SUCCESS: Order created:', order);
    } catch (error) {
        console.error('FAILURE: Razorpay Error Full Object:', JSON.stringify(error, null, 2));
        console.error('FAILURE: Razorpay Error Message:', error.message);
    }
}

testRazorpay();
