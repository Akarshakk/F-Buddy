const Expense = require('../models/Expense');
const { EXPENSE_CATEGORIES } = require('../models/Expense');

// Helper function to parse date without timezone issues
const parseDate = (dateString) => {
  if (!dateString) return new Date();
  
  // If it's already a Date object
  if (dateString instanceof Date) return dateString;
  
  // Parse the date string and create a date in local timezone
  const parsed = new Date(dateString);
  
  // If the parsed date is valid, use it
  if (!isNaN(parsed.getTime())) {
    // Create a new date using the date components to avoid timezone shift
    return new Date(parsed.getFullYear(), parsed.getMonth(), parsed.getDate(), 12, 0, 0);
  }
  
  return new Date();
};

// @desc    Check for duplicate expenses
// @route   POST /api/expenses/check-duplicate
// @access  Private
exports.checkDuplicate = async (req, res) => {
  try {
    const { amount, category, date, merchant } = req.body;
    
    const targetDate = parseDate(date);
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    // Find expenses with same amount, category on the same day
    const duplicates = await Expense.find({
      user: req.user.id,
      amount: amount,
      category: category.toLowerCase(),
      date: { $gte: startOfDay, $lte: endOfDay }
    });

    if (duplicates.length > 0) {
      // Found potential duplicates
      const duplicateInfo = duplicates.map(d => ({
        id: d._id,
        amount: d.amount,
        category: d.category,
        merchant: d.merchant,
        description: d.description,
        date: d.date
      }));

      return res.status(200).json({
        success: true,
        isDuplicate: true,
        message: `Found ${duplicates.length} similar expense(s) on this date with the same amount and category.`,
        duplicates: duplicateInfo
      });
    }

    // No duplicates found
    res.status(200).json({
      success: true,
      isDuplicate: false,
      message: 'No duplicates found'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error checking for duplicates',
      error: error.message
    });
  }
};

// @desc    Add expense
// @route   POST /api/expenses
// @access  Private
exports.addExpense = async (req, res) => {
  try {
    const { amount, category, description, merchant, date } = req.body;

    const expense = await Expense.create({
      user: req.user.id,
      amount,
      category: category.toLowerCase(),
      description: description || '',
      merchant: merchant || '',
      date: parseDate(date)
    });

    res.status(201).json({
      success: true,
      message: 'Expense added successfully',
      data: { expense }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding expense',
      error: error.message
    });
  }
};

// @desc    Get all expenses for user
// @route   GET /api/expenses
// @access  Private
exports.getExpenses = async (req, res) => {
  try {
    const { category, startDate, endDate, limit, page } = req.query;

    let query = { user: req.user.id };

    // Filter by category
    if (category) {
      query.category = category.toLowerCase();
    }

    // Filter by date range
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }

    // Pagination
    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 50;
    const skip = (pageNum - 1) * limitNum;

    const expenses = await Expense.find(query)
      .sort({ date: -1 })
      .skip(skip)
      .limit(limitNum);

    const total = await Expense.countDocuments(query);
    const totalAmount = await Expense.aggregate([
      { $match: query },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    res.status(200).json({
      success: true,
      count: expenses.length,
      total,
      totalAmount: totalAmount[0]?.total || 0,
      page: pageNum,
      pages: Math.ceil(total / limitNum),
      data: { expenses }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching expenses',
      error: error.message
    });
  }
};

// @desc    Get latest 10 expenses
// @route   GET /api/expenses/latest
// @access  Private
exports.getLatestExpenses = async (req, res) => {
  try {
    const expenses = await Expense.find({ user: req.user.id })
      .sort({ date: -1, createdAt: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      count: expenses.length,
      data: { expenses }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching latest expenses',
      error: error.message
    });
  }
};

// @desc    Get single expense
// @route   GET /api/expenses/:id
// @access  Private
exports.getExpense = async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.id);

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    // Make sure user owns the expense
    if (expense.user.toString() !== req.user.id) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to view this expense'
      });
    }

    res.status(200).json({
      success: true,
      data: { expense }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching expense',
      error: error.message
    });
  }
};

// @desc    Update expense
// @route   PUT /api/expenses/:id
// @access  Private
exports.updateExpense = async (req, res) => {
  try {
    let expense = await Expense.findById(req.params.id);

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    // Make sure user owns the expense
    if (expense.user.toString() !== req.user.id) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to update this expense'
      });
    }

    // Lowercase category if provided
    if (req.body.category) {
      req.body.category = req.body.category.toLowerCase();
    }

    // Parse date properly to avoid timezone issues
    if (req.body.date) {
      req.body.date = parseDate(req.body.date);
    }

    expense = await Expense.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });

    res.status(200).json({
      success: true,
      message: 'Expense updated successfully',
      data: { expense }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating expense',
      error: error.message
    });
  }
};

// @desc    Delete expense
// @route   DELETE /api/expenses/:id
// @access  Private
exports.deleteExpense = async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.id);

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    // Make sure user owns the expense
    if (expense.user.toString() !== req.user.id) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to delete this expense'
      });
    }

    await expense.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Expense deleted successfully',
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting expense',
      error: error.message
    });
  }
};
