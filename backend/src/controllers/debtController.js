const Debt = require('../models/Debt');
const Expense = require('../models/Expense');

// @desc    Create new debt
// @route   POST /api/debts
// @access  Private
exports.createDebt = async (req, res) => {
  try {
    const { type, amount, personName, description, dueDate } = req.body;

    const debt = await Debt.create({
      user: req.user.id,
      type,
      amount,
      personName,
      description,
      dueDate: new Date(dueDate)
    });

    // Create corresponding transaction (Transaction History)
    if (type === 'they_owe_me') {
      // I Lent Money -> Expense
      await Expense.create({
        user: req.user.id,
        amount,
        category: 'Debt Lent',
        description: `Debt Lent - ${personName} (${description || ''})`,
        date: new Date()
      });
    } else if (type === 'i_owe') {
      // I Borrowed Money -> Expense (Negative)
      await Expense.create({
        user: req.user.id,
        amount: -amount,
        category: 'Debt Borrowed',
        description: `Debt Borrowed - ${personName} (${description || ''})`,
        date: new Date()
      });
    }

    res.status(201).json({
      success: true,
      data: debt
    });
  } catch (error) {
    console.error('Create debt error:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get all debts for user
// @route   GET /api/debts
// @access  Private
exports.getDebts = async (req, res) => {
  try {
    const { type, settled } = req.query;

    const options = {};
    if (type) options.type = type;
    if (settled !== undefined) options.isSettled = settled === 'true';

    const debts = await Debt.findByUser(req.user.id, options);

    // Calculate summaries from unsettled debts
    const allUnsettledDebts = await Debt.findByUser(req.user.id, { isSettled: false });

    const theyOweMe = allUnsettledDebts
      .filter(d => d.type === 'they_owe_me')
      .reduce((sum, d) => sum + d.amount, 0);

    const iOwe = allUnsettledDebts
      .filter(d => d.type === 'i_owe')
      .reduce((sum, d) => sum + d.amount, 0);

    res.json({
      success: true,
      count: debts.length,
      summary: {
        theyOweMe,
        iOwe,
        netBalance: theyOweMe - iOwe
      },
      data: debts
    });
  } catch (error) {
    console.error('Get debts error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Get single debt
// @route   GET /api/debts/:id
// @access  Private
exports.getDebt = async (req, res) => {
  try {
    const debt = await Debt.findById(req.params.id);

    if (!debt || debt.user !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    res.json({
      success: true,
      data: debt
    });
  } catch (error) {
    console.error('Get debt error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Update debt
// @route   PUT /api/debts/:id
// @access  Private
exports.updateDebt = async (req, res) => {
  try {
    const { type, amount, personName, description, dueDate } = req.body;

    let debt = await Debt.findById(req.params.id);

    if (!debt || debt.user !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    const updateData = {};
    if (type) updateData.type = type;
    if (amount) updateData.amount = amount;
    if (personName) updateData.personName = personName;
    if (description !== undefined) updateData.description = description;
    if (dueDate) updateData.dueDate = new Date(dueDate);

    debt = await Debt.updateById(req.params.id, updateData);

    res.json({
      success: true,
      data: debt
    });
  } catch (error) {
    console.error('Update debt error:', error);
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Delete debt
// @route   DELETE /api/debts/:id
// @access  Private
exports.deleteDebt = async (req, res) => {
  try {
    const debt = await Debt.findById(req.params.id);

    if (!debt || debt.user !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    await Debt.deleteById(req.params.id);

    res.json({
      success: true,
      message: 'Debt deleted successfully'
    });
  } catch (error) {
    console.error('Delete debt error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Mark reminder as sent
// @route   PUT /api/debts/:id/reminder-sent
// @access  Private
exports.markReminderSent = async (req, res) => {
  try {
    const debt = await Debt.findById(req.params.id);

    if (!debt || debt.user !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    const updatedDebt = await Debt.updateById(req.params.id, { reminderSent: true });

    res.json({
      success: true,
      data: updatedDebt
    });
  } catch (error) {
    console.error('Mark reminder sent error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Settle a debt
// @route   PUT /api/debts/:id/settle
// @access  Private
exports.settleDebt = async (req, res) => {
  try {
    const debt = await Debt.findById(req.params.id);

    if (!debt || debt.user !== req.user.id) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    if (debt.isSettled) {
      return res.status(400).json({
        success: false,
        message: 'Debt is already settled'
      });
    }

    // Create corresponding transaction (Closing History)
    if (debt.type === 'they_owe_me') {
      // I Collected Money -> Expense (Negative - Reimbursement)
      await Expense.create({
        user: req.user.id,
        amount: -debt.amount,
        category: 'Debt Collected',
        description: `Debt Collected - ${debt.personName}`,
        date: new Date()
      });
    } else if (debt.type === 'i_owe') {
      // I Repaid Money -> Expense
      await Expense.create({
        user: req.user.id,
        amount: debt.amount,
        category: 'Debt Repaid',
        description: `Debt Repaid - ${debt.personName}`,
        date: new Date()
      });
    }

    // Delete the debt (Clean up active list)
    await Debt.deleteById(req.params.id);

    res.json({
      success: true,
      message: 'Debt settled and transaction recorded successfully'
    });
  } catch (error) {
    console.error('Settle debt error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Get debts due today (for reminders)
// @route   GET /api/debts/due-today
// @access  Private
exports.getDebtsDueToday = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get all debts for user and filter client-side for due today
    const allDebts = await Debt.findByUser(req.user.id, { isSettled: false });

    const debts = allDebts.filter(d => {
      const dueDate = d.dueDate instanceof Date ? d.dueDate : new Date(d.dueDate);
      return dueDate >= today && dueDate < tomorrow;
    });

    res.json({
      success: true,
      count: debts.length,
      data: debts
    });
  } catch (error) {
    console.error('Get debts due today error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};

// @desc    Get upcoming debts (next 7 days)
// @route   GET /api/debts/upcoming
// @access  Private
exports.getUpcomingDebts = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);

    // Get all debts for user and filter client-side
    const allDebts = await Debt.findByUser(req.user.id, { isSettled: false });

    const debts = allDebts.filter(d => {
      const dueDate = d.dueDate instanceof Date ? d.dueDate : new Date(d.dueDate);
      return dueDate >= today && dueDate <= nextWeek;
    }).sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));

    res.json({
      success: true,
      count: debts.length,
      data: debts
    });
  } catch (error) {
    console.error('Get upcoming debts error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error'
    });
  }
};
