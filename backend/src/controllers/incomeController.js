const Income = require('../models/Income');

// @desc    Add income
// @route   POST /api/income
// @access  Private
exports.addIncome = async (req, res) => {
  try {
    const { amount, description, source, month, year, date } = req.body;

    const currentDate = new Date();
    const incomeMonth = month || currentDate.getMonth() + 1;
    const incomeYear = year || currentDate.getFullYear();

    const income = await Income.create({
      user: req.user.id,
      amount,
      description: description || 'Monthly Income',
      source: source || 'pocket_money',
      month: incomeMonth,
      year: incomeYear,
      date: date || currentDate
    });

    res.status(201).json({
      success: true,
      message: 'Income added successfully',
      data: { income }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error adding income',
      error: error.message
    });
  }
};

// @desc    Get all income for user
// @route   GET /api/income
// @access  Private
exports.getIncomes = async (req, res) => {
  try {
    const { month, year } = req.query;

    const options = {};
    if (month) options.month = parseInt(month);
    if (year) options.year = parseInt(year);

    const incomes = await Income.findByUser(req.user.id, options);

    // Calculate total income
    const totalIncome = incomes.reduce((sum, inc) => sum + inc.amount, 0);

    res.status(200).json({
      success: true,
      count: incomes.length,
      totalIncome,
      data: { incomes }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching incomes',
      error: error.message
    });
  }
};

// @desc    Get current month income
// @route   GET /api/income/current
// @access  Private
exports.getCurrentMonthIncome = async (req, res) => {
  try {
    const currentDate = new Date();
    const month = currentDate.getMonth() + 1;
    const year = currentDate.getFullYear();

    const incomes = await Income.findByUser(req.user.id, { month, year });
    const totalIncome = incomes.reduce((sum, inc) => sum + inc.amount, 0);

    res.status(200).json({
      success: true,
      month,
      year,
      totalIncome,
      count: incomes.length,
      data: { incomes }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching current month income',
      error: error.message
    });
  }
};

// @desc    Update income
// @route   PUT /api/income/:id
// @access  Private
exports.updateIncome = async (req, res) => {
  try {
    let income = await Income.findById(req.params.id);

    if (!income) {
      return res.status(404).json({
        success: false,
        message: 'Income not found'
      });
    }

    // Make sure user owns the income
    if (income.user !== req.user.id) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to update this income'
      });
    }

    income = await Income.updateById(req.params.id, req.body);

    res.status(200).json({
      success: true,
      message: 'Income updated successfully',
      data: { income }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating income',
      error: error.message
    });
  }
};

// @desc    Delete income
// @route   DELETE /api/income/:id
// @access  Private
exports.deleteIncome = async (req, res) => {
  try {
    const income = await Income.findById(req.params.id);

    if (!income) {
      return res.status(404).json({
        success: false,
        message: 'Income not found'
      });
    }

    // Make sure user owns the income
    if (income.user !== req.user.id) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to delete this income'
      });
    }

    await Income.deleteById(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Income deleted successfully',
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting income',
      error: error.message
    });
  }
};
