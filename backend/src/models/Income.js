const mongoose = require('mongoose');

const incomeSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  amount: {
    type: Number,
    required: [true, 'Please provide an amount'],
    min: [0, 'Amount cannot be negative']
  },
  description: {
    type: String,
    default: 'Monthly Income',
    trim: true,
    maxlength: [200, 'Description cannot be more than 200 characters']
  },
  source: {
    type: String,
    enum: ['pocket_money', 'salary', 'freelance', 'gift', 'scholarship', 'other'],
    default: 'pocket_money'
  },
  month: {
    type: Number,
    required: true,
    min: 1,
    max: 12
  },
  year: {
    type: Number,
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Compound index for efficient queries
incomeSchema.index({ user: 1, month: 1, year: 1 });

module.exports = mongoose.model('Income', incomeSchema);
