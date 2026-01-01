const mongoose = require('mongoose');

const debtSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    required: [true, 'Please specify debt type'],
    enum: {
      values: ['they_owe_me', 'i_owe'],
      message: 'Type must be either they_owe_me or i_owe'
    }
  },
  amount: {
    type: Number,
    required: [true, 'Please provide an amount'],
    min: [0.01, 'Amount must be at least 0.01']
  },
  personName: {
    type: String,
    required: [true, 'Please provide the person\'s name'],
    trim: true,
    maxlength: [100, 'Name cannot be more than 100 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [200, 'Description cannot be more than 200 characters'],
    default: ''
  },
  dueDate: {
    type: Date,
    required: [true, 'Please provide a due date']
  },
  isSettled: {
    type: Boolean,
    default: false
  },
  settledDate: {
    type: Date,
    default: null
  },
  reminderSent: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for efficient queries
debtSchema.index({ user: 1, dueDate: 1 });
debtSchema.index({ user: 1, isSettled: 1 });

// Static method to get debts due today for reminders
debtSchema.statics.getDebtsDueToday = async function() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  return this.find({
    dueDate: {
      $gte: today,
      $lt: tomorrow
    },
    isSettled: false,
    reminderSent: false
  }).populate('user', 'name email');
};

// Instance method to mark as settled
debtSchema.methods.settle = function() {
  this.isSettled = true;
  this.settledDate = new Date();
  return this.save();
};

module.exports = mongoose.model('Debt', debtSchema);
