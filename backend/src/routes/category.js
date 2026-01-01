const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getCategories,
  seedCategories
} = require('../controllers/categoryController');

// Public route to get categories
router.get('/', getCategories);

// Protected route to seed categories (admin use)
router.post('/seed', protect, seedCategories);

module.exports = router;
