const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { handleValidationErrors } = require('../middleware/validate');
const { protect } = require('../middleware/auth');
const {
  addIncome,
  getIncomes,
  getCurrentMonthIncome,
  updateIncome,
  deleteIncome
} = require('../controllers/incomeController');

// Validation rules
const incomeValidation = [
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ min: 0 })
    .withMessage('Amount must be a positive number')
];

// All routes are protected
router.use(protect);

// Routes
router.route('/')
  .get(getIncomes)
  .post(incomeValidation, handleValidationErrors, addIncome);

router.get('/current', getCurrentMonthIncome);

router.route('/:id')
  .put(updateIncome)
  .delete(deleteIncome);

module.exports = router;
