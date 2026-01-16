const express = require('express');
const router = express.Router();
const smsParser = require('../services/smsParser');
const Expense = require('../models/Expense');
const Income = require('../models/Income');
const Category = require('../models/Category');
const { protect } = require('../middleware/auth');

/**
 * @route   POST /api/sms/parse
 * @desc    Parse SMS and extract transaction details
 * @access  Private
 */
router.post('/parse', protect, async (req, res) => {
  try {
    const { smsText, sender, smsId } = req.body;
    const userId = req.user._id;

    // Validate input
    if (!smsText || !sender) {
      return res.status(400).json({ 
        success: false,
        error: 'SMS text and sender are required' 
      });
    }

    // Check if SMS is from a bank/payment app
    if (!smsParser.isPaymentSms(sender)) {
      return res.status(400).json({ 
        success: false,
        error: 'SMS is not from a recognized bank or payment app' 
      });
    }

    // Parse SMS
    const transaction = await smsParser.parseSms(smsText, sender);

    if (!transaction || !transaction.amount || !transaction.type) {
      return res.status(400).json({ 
        success: false,
        error: 'Could not parse transaction details from SMS' 
      });
    }

    // Check for duplicates (same amount, merchant, within 2 minutes)
    const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
    
    let duplicate = null;
    if (transaction.type === 'expense') {
      duplicate = await Expense.findOne({
        user: userId,
        amount: transaction.amount,
        description: new RegExp(transaction.merchant, 'i'),
        date: { $gte: twoMinutesAgo }
      });
    } else {
      duplicate = await Income.findOne({
        user: userId,
        amount: transaction.amount,
        description: new RegExp(transaction.merchant || '', 'i'),
        date: { $gte: twoMinutesAgo }
      });
    }

    if (duplicate) {
      return res.json({ 
        success: true,
        isDuplicate: true, 
        message: 'Duplicate transaction detected',
        existingTransaction: duplicate
      });
    }

    // Return parsed transaction for review/confirmation
    res.json({ 
      success: true, 
      transaction,
      isDuplicate: false,
      autoSaved: false,
      needsReview: transaction.needsReview || transaction.confidence < 0.8
    });

  } catch (error) {
    console.error('SMS Parse Error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

/**
 * @route   POST /api/sms/save
 * @desc    Save parsed SMS transaction
 * @access  Private
 */
router.post('/save', protect, async (req, res) => {
  try {
    const { transaction, smsId } = req.body;
    const userId = req.user._id;

    if (!transaction || !transaction.type) {
      return res.status(400).json({ 
        success: false,
        error: 'Invalid transaction data' 
      });
    }

    let saved;

    if (transaction.type === 'expense') {
      // Find or create category
      let category = await Category.findOne({ 
        user: userId, 
        name: transaction.category 
      });

      if (!category) {
        category = await Category.create({
          user: userId,
          name: transaction.category,
          type: 'expense',
          icon: '💳',
          color: '#6C63FF'
        });
      }

      // Create expense
      saved = await Expense.create({
        user: userId,
        amount: transaction.amount,
        category: category._id,
        description: transaction.description || `SMS: ${transaction.merchant}`,
        date: transaction.date || new Date(),
        paymentMethod: 'upi',
        notes: `Auto-created from SMS\nSender: ${transaction.sender}\nRef: ${transaction.refNo || 'N/A'}`,
        source: 'sms_auto',
        smsId: smsId,
        merchant: transaction.merchant,
        upiId: transaction.upiId,
        confidence: transaction.confidence
      });

      // Populate category
      await saved.populate('category');
    } else {
      // Create income
      saved = await Income.create({
        user: userId,
        amount: transaction.amount,
        source: transaction.merchant || 'Other',
        description: transaction.description || `SMS: ${transaction.merchant || 'Credit'}`,
        date: transaction.date || new Date(),
        notes: `Auto-created from SMS\nSender: ${transaction.sender}\nRef: ${transaction.refNo || 'N/A'}`,
        smsId: smsId,
        confidence: transaction.confidence
      });
    }

    res.json({ 
      success: true, 
      transaction: saved,
      message: 'Transaction saved successfully'
    });

  } catch (error) {
    console.error('SMS Save Error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

/**
 * @route   POST /api/sms/parse-bulk
 * @desc    Parse multiple SMS messages in bulk
 * @access  Private
 */
router.post('/parse-bulk', protect, async (req, res) => {
  try {
    const { smsArray } = req.body;
    const userId = req.user._id;

    if (!Array.isArray(smsArray) || smsArray.length === 0) {
      return res.status(400).json({ 
        success: false,
        error: 'SMS array is required' 
      });
    }

    // Filter only bank/payment SMS
    const paymentSms = smsArray.filter(sms => 
      smsParser.isPaymentSms(sms.sender)
    );

    if (paymentSms.length === 0) {
      return res.json({ 
        success: true,
        transactions: [],
        message: 'No payment-related SMS found'
      });
    }

    // Parse all SMS
    const transactions = await smsParser.parseBulkSms(paymentSms);

    // Filter out duplicates
    const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
    const uniqueTransactions = [];

    for (const transaction of transactions) {
      if (!transaction) continue;

      let duplicate = null;
      if (transaction.type === 'expense') {
        duplicate = await Expense.findOne({
          user: userId,
          amount: transaction.amount,
          date: { $gte: twoMinutesAgo }
        });
      } else {
        duplicate = await Income.findOne({
          user: userId,
          amount: transaction.amount,
          date: { $gte: twoMinutesAgo }
        });
      }

      if (!duplicate) {
        uniqueTransactions.push(transaction);
      }
    }

    res.json({ 
      success: true, 
      transactions: uniqueTransactions,
      total: transactions.length,
      unique: uniqueTransactions.length,
      duplicates: transactions.length - uniqueTransactions.length
    });

  } catch (error) {
    console.error('Bulk SMS Parse Error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

/**
 * @route   GET /api/sms/transactions
 * @desc    Get all SMS-created transactions
 * @access  Private
 */
router.get('/transactions', protect, async (req, res) => {
  try {
    const userId = req.user._id;

    const expenses = await Expense.find({ 
      user: userId,
      source: 'sms_auto'
    })
    .populate('category')
    .sort({ date: -1 })
    .limit(50);

    const incomes = await Income.find({ 
      user: userId,
      smsId: { $exists: true }
    })
    .sort({ date: -1 })
    .limit(50);

    res.json({ 
      success: true, 
      expenses,
      incomes,
      total: expenses.length + incomes.length
    });

  } catch (error) {
    console.error('Get SMS Transactions Error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

module.exports = router;
