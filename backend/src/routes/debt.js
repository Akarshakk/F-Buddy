const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  createDebt,
  getDebts,
  getDebt,
  updateDebt,
  deleteDebt,
  settleDebt,
  getDebtsDueToday,
  getUpcomingDebts,
  markReminderSent
} = require('../controllers/debtController');

// All routes require authentication
router.use(protect);

// Special routes (must be before /:id routes)
router.get('/due-today', getDebtsDueToday);
router.get('/upcoming', getUpcomingDebts);

// CRUD routes
router.route('/')
  .get(getDebts)
  .post(createDebt);

router.route('/:id')
  .get(getDebt)
  .put(updateDebt)
  .delete(deleteDebt);

// Action routes
router.put('/:id/settle', settleDebt);
router.put('/:id/reminder-sent', markReminderSent);

module.exports = router;
