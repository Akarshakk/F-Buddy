const mongoose = require('mongoose');

// Predefined categories for the app
const EXPENSE_CATEGORIES = [
  'clothes',
  'drinks',
  'education',
  'food',
  'fuel',
  'fun',
  'health',
  'hotel',
  'personal',
  'pets',
  'restaurants',
  'tips',
  'transport',
  'others'
];

const expenseSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  amount: {
    type: Number,
    required: [true, 'Please provide an amount'],
    min: [0.01, 'Amount must be at least 0.01']
  },
  category: {
    type: String,
    required: [true, 'Please select a category'],
    enum: {
      values: EXPENSE_CATEGORIES,
      message: 'Please select a valid category'
    },
    lowercase: true
  },
  description: {
    type: String,
    trim: true,
    maxlength: [200, 'Description cannot be more than 200 characters'],
    default: ''
  },
  merchant: {
    type: String,
    trim: true,
    maxlength: [100, 'Merchant name cannot be more than 100 characters'],
    default: ''
  },
  date: {
    type: Date,
    required: true,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Indexes for efficient queries
expenseSchema.index({ user: 1, date: -1 });
expenseSchema.index({ user: 1, category: 1 });
expenseSchema.index({ user: 1, date: 1, category: 1 });

// Export categories for use in other files
expenseSchema.statics.getCategories = function() {
  return EXPENSE_CATEGORIES;
};

module.exports = mongoose.model('Expense', expenseSchema);
module.exports.EXPENSE_CATEGORIES = EXPENSE_CATEGORIES;
