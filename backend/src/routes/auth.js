const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { handleValidationErrors } = require('../middleware/validate');
const { protect } = require('../middleware/auth');
const {
  register,
  verifyEmail,
  resendOtp,
  login,
  getMe,
  updateProfile,
  updatePassword
} = require('../controllers/authController');

// Validation rules
const registerValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ max: 50 })
    .withMessage('Name cannot be more than 50 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters')
];

const loginValidation = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// Routes
router.post('/register', registerValidation, handleValidationErrors, register);
router.post('/verify-email', verifyEmail);
router.post('/resend-otp', resendOtp);
router.post('/login', loginValidation, handleValidationErrors, login);
router.get('/me', protect, getMe);
router.put('/update', protect, updateProfile);
router.put('/password', protect, updatePassword);
router.put('/update', protect, updateProfile);
router.put('/password', protect, updatePassword);

module.exports = router;
