const Debt = require('../models/Debt');

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
    const { type, settled, limit = 50 } = req.query;

    const query = { user: req.user.id };

    if (type) {
      query.type = type;
    }

    if (settled !== undefined) {
      query.isSettled = settled === 'true';
    }

    const debts = await Debt.find(query)
      .sort({ dueDate: 1 })
      .limit(parseInt(limit));

    // Calculate summaries
    const allDebts = await Debt.find({ user: req.user.id, isSettled: false });
    
    const theyOweMe = allDebts
      .filter(d => d.type === 'they_owe_me')
      .reduce((sum, d) => sum + d.amount, 0);
    
    const iOwe = allDebts
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
    const debt = await Debt.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!debt) {
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

    let debt = await Debt.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!debt) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    debt = await Debt.findByIdAndUpdate(
      req.params.id,
      {
        type,
        amount,
        personName,
        description,
        dueDate: dueDate ? new Date(dueDate) : debt.dueDate
      },
      { new: true, runValidators: true }
    );

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
    const debt = await Debt.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!debt) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    await debt.deleteOne();

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
    const debt = await Debt.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!debt) {
      return res.status(404).json({
        success: false,
        message: 'Debt not found'
      });
    }

    debt.reminderSent = true;
    await debt.save();

    res.json({
      success: true,
      data: debt
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
    const debt = await Debt.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!debt) {
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

    debt.isSettled = true;
    debt.settledDate = new Date();
    await debt.save();

    res.json({
      success: true,
      data: debt
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

    const debts = await Debt.find({
      user: req.user.id,
      dueDate: {
        $gte: today,
        $lt: tomorrow
      },
      isSettled: false
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

    const debts = await Debt.find({
      user: req.user.id,
      dueDate: {
        $gte: today,
        $lte: nextWeek
      },
      isSettled: false
    }).sort({ dueDate: 1 });

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
