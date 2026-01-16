const Expense = require('../models/Expense');

function parseDate(dateString) {
  if (!dateString) return new Date();

  // Handle DD/MM/YYYY format
  if (dateString.includes('/')) {
    const parts = dateString.split('/');
    if (parts.length === 3) {
      const day = parseInt(parts[0], 10);
      const month = parseInt(parts[1], 10) - 1;
      const year = parseInt(parts[2], 10);
      return new Date(year, month, day);
    }
  }

  // Handle ISO format or other formats
  return new Date(dateString);
}

// @desc    Check for duplicate expenses
// @route   POST /api/expenses/check-duplicate
// @access  Private
exports.checkDuplicate = async (req, res) => {
  try {
    const { amount, category, date, toleranceMinutes = 1 } = req.body;

    if (!amount || !category) {
      return res.status(400).json({
        success: false,
        message: 'Amount and category are required'
      });
    }

    const targetDate = parseDate(date);
    const toleranceMs = toleranceMinutes * 60 * 1000;

    const isDuplicate = await Expense.checkDuplicate(
      req.user.id,
      amount,
      category,
      targetDate,
      toleranceMs
    );

    res.status(200).json({
      success: true,
      isDuplicate,
      message: isDuplicate
        ? 'A similar expense was found within the time window'
        : 'No duplicate found'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error checking for duplicate',
      error: error.message
    });
  }
};

// @desc    Add expense
// @route   POST /api/expenses
// @access  Private
exports.addExpense = async (req, res) => {
  try {
    const { amount, category, description, merchant, date, groupExpenseId, groupId } = req.body;

    const expense = await Expense.create({
      user: req.user.id,
      amount,
      category,
      description,
      merchant,
      date: parseDate(date),
      groupExpenseId,
      groupId
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
    const { month, year, category } = req.query;

    let options = {};

    if (month && year) {
      const startDate = new Date(parseInt(year), parseInt(month) - 1, 1);
      const endDate = new Date(parseInt(year), parseInt(month), 0, 23, 59, 59);
      options.startDate = startDate;
      options.endDate = endDate;
    }

    if (category) {
      options.category = category;
    }

    const expenses = await Expense.findByUser(req.user.id, options);

    // Calculate total
    const total = expenses.reduce((sum, exp) => sum + exp.amount, 0);

    res.status(200).json({
      success: true,
      count: expenses.length,
      total,
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
    const expenses = await Expense.findByUser(req.user.id, { limit: 10 });

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

    // Make sure user owns expense
    if (expense.user !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this expense'
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

    // Make sure user owns expense
    if (expense.user !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this expense'
      });
    }

    const updateData = {};
    if (req.body.amount !== undefined) updateData.amount = req.body.amount;
    if (req.body.category) updateData.category = req.body.category;
    if (req.body.description !== undefined) updateData.description = req.body.description;
    if (req.body.merchant !== undefined) updateData.merchant = req.body.merchant;
    if (req.body.date) updateData.date = parseDate(req.body.date);

    expense = await Expense.updateById(req.params.id, updateData);

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

    // Make sure user owns expense
    if (expense.user !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this expense'
      });
    }

    await Expense.deleteById(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Expense deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting expense',
      error: error.message
    });
  }
};

// @desc    Delete expense by group link
// @route   DELETE /api/expenses/by-group/:groupId/:groupExpenseId
// @access  Private
exports.deleteExpenseByGroupLink = async (req, res) => {
  try {
    const { groupId, groupExpenseId } = req.params;

    const deletedCount = await Expense.deleteByGroupLink(req.user.id, groupId, groupExpenseId);

    res.status(200).json({
      success: true,
      message: `Deleted ${deletedCount} expense(s) linked to group expense`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting expense',
      error: error.message
    });
  }
};

// @desc    Get expense categories
// @route   GET /api/expenses/categories
// @access  Public
exports.getCategories = async (req, res) => {
  try {
    const categories = Expense.getCategories();
    res.status(200).json({
      success: true,
      data: { categories }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching categories',
      error: error.message
    });
  }
};
