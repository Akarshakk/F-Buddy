const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getExpensesByCategory,
  getSummary,
  getBalanceChart,
  getDashboard
} = require('../controllers/analyticsController');

// All routes are protected
router.use(protect);

// Routes
router.get('/category', getExpensesByCategory);
router.get('/summary', getSummary);
router.get('/balance-chart', getBalanceChart);
router.get('/dashboard', getDashboard);

module.exports = router;
