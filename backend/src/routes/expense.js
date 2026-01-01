const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { handleValidationErrors } = require('../middleware/validate');
const { protect } = require('../middleware/auth');
const { EXPENSE_CATEGORIES } = require('../models/Expense');
const {
  addExpense,
  getExpenses,
  getLatestExpenses,
  getExpense,
  updateExpense,
  deleteExpense,
  checkDuplicate
} = require('../controllers/expenseController');

// Validation rules
const expenseValidation = [
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be at least 0.01'),
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(EXPENSE_CATEGORIES)
    .withMessage(`Category must be one of: ${EXPENSE_CATEGORIES.join(', ')}`)
];

// All routes are protected
router.use(protect);

// Routes
router.route('/')
  .get(getExpenses)
  .post(expenseValidation, handleValidationErrors, addExpense);

router.get('/latest', getLatestExpenses);

// Check for duplicate expenses
router.post('/check-duplicate', checkDuplicate);

router.route('/:id')
  .get(getExpense)
  .put(updateExpense)
  .delete(deleteExpense);

module.exports = router;
