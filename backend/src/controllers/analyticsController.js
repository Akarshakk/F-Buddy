const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

// @desc    Get expenses by category (for pie chart)
// @route   GET /api/analytics/category
// @access  Private
exports.getExpensesByCategory = async (req, res) => {
  try {
    const { period, month, year } = req.query;

    let startDate, endDate;
    const now = new Date();

    // Determine date range based on period
    if (period === 'weekly') {
      startDate = new Date(now);
      startDate.setDate(now.getDate() - 7);
      endDate = now;
    } else if (period === 'monthly' || (!period && !month)) {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    } else if (month && year) {
      startDate = new Date(parseInt(year), parseInt(month) - 1, 1);
      endDate = new Date(parseInt(year), parseInt(month), 0, 23, 59, 59);
    } else {
      // Default to current month
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    }

    const categoryData = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$category',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      {
        $sort: { totalAmount: -1 }
      }
    ]);

    // Calculate total for percentage
    const totalExpense = categoryData.reduce((sum, cat) => sum + cat.totalAmount, 0);

    // Format data for pie chart
    const pieChartData = categoryData.map(cat => ({
      category: cat._id,
      amount: cat.totalAmount,
      count: cat.count,
      percentage: totalExpense > 0 ? ((cat.totalAmount / totalExpense) * 100).toFixed(2) : 0
    }));

    res.status(200).json({
      success: true,
      period: period || 'monthly',
      startDate,
      endDate,
      totalExpense,
      data: { categoryData: pieChartData }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching category analytics',
      error: error.message
    });
  }
};

// @desc    Get weekly/monthly summary
// @route   GET /api/analytics/summary
// @access  Private
exports.getSummary = async (req, res) => {
  try {
    const { period } = req.query;
    const now = new Date();

    let startDate, endDate;

    if (period === 'weekly') {
      startDate = new Date(now);
      startDate.setDate(now.getDate() - 7);
      endDate = now;
    } else {
      // Monthly (default)
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    }

    // Get total expenses
    const expenseResult = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: null,
          totalExpense: { $sum: '$amount' },
          expenseCount: { $sum: 1 }
        }
      }
    ]);

    // Get total income for the period
    const incomeResult = await Income.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: null,
          totalIncome: { $sum: '$amount' },
          incomeCount: { $sum: 1 }
        }
      }
    ]);

    const totalExpense = expenseResult[0]?.totalExpense || 0;
    const totalIncome = incomeResult[0]?.totalIncome || 0;
    const balance = totalIncome - totalExpense;

    res.status(200).json({
      success: true,
      period: period || 'monthly',
      startDate,
      endDate,
      data: {
        totalIncome,
        totalExpense,
        balance,
        expenseCount: expenseResult[0]?.expenseCount || 0,
        incomeCount: incomeResult[0]?.incomeCount || 0,
        savingsRate: totalIncome > 0 ? ((balance / totalIncome) * 100).toFixed(2) : 0
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching summary',
      error: error.message
    });
  }
};

// @desc    Get 7-day balance chart data (Income vs Expense)
// @route   GET /api/analytics/balance-chart
// @access  Private
// @query   weekStart - Optional: Start date of the week to view (YYYY-MM-DD format)
exports.getBalanceChart = async (req, res) => {
  try {
    const { weekStart } = req.query;
    
    let startDate, endDate;
    
    if (weekStart) {
      // User specified a custom week starting date
      startDate = new Date(weekStart);
      startDate.setHours(0, 0, 0, 0);
      endDate = new Date(startDate);
      endDate.setDate(startDate.getDate() + 6);
      endDate.setHours(23, 59, 59, 999);
    } else {
      // Default: Last 7 days
      endDate = new Date();
      startDate = new Date();
      startDate.setDate(endDate.getDate() - 6);
      startDate.setHours(0, 0, 0, 0);
    }
    
    const now = new Date();
    const sevenDaysAgo = startDate;

    // Check if user has expenses on at least 7 unique dates
    const uniqueDates = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id)
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' },
            day: { $dayOfMonth: '$date' }
          }
        }
      }
    ]);
    
    const uniqueDaysCount = uniqueDates.length;
    
    if (uniqueDaysCount === 0) {
      return res.status(200).json({
        success: true,
        message: 'No expenses found. Start adding expenses to see the balance chart.',
        hasEnoughData: false,
        daysRemaining: 7,
        data: { chartData: [] }
      });
    }

    if (uniqueDaysCount < 7) {
      return res.status(200).json({
        success: true,
        message: `Balance chart will be available after ${7 - uniqueDaysCount} more days of entries.`,
        hasEnoughData: false,
        daysRemaining: 7 - uniqueDaysCount,
        data: { chartData: [] }
      });
    }

    // Get daily expenses for the selected week
    const dailyExpenses = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' },
            day: { $dayOfMonth: '$date' }
          },
          totalExpense: { $sum: '$amount' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
      }
    ]);

    // Get daily income for the selected week
    const dailyIncome = await Income.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' },
            day: { $dayOfMonth: '$date' }
          },
          totalIncome: { $sum: '$amount' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
      }
    ]);

    // Create a map for easy lookup
    const expenseMap = new Map();
    dailyExpenses.forEach(item => {
      const key = `${item._id.year}-${item._id.month}-${item._id.day}`;
      expenseMap.set(key, item.totalExpense);
    });

    const incomeMap = new Map();
    dailyIncome.forEach(item => {
      const key = `${item._id.year}-${item._id.month}-${item._id.day}`;
      incomeMap.set(key, item.totalIncome);
    });

    // Generate chart data for all 7 days
    const chartData = [];
    let cumulativeBalance = 0;

    for (let i = 0; i <= 6; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      
      const key = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
      const dayIncome = incomeMap.get(key) || 0;
      const dayExpense = expenseMap.get(key) || 0;
      const dayBalance = dayIncome - dayExpense;
      cumulativeBalance += dayBalance;

      chartData.push({
        date: date.toISOString().split('T')[0],
        dayName: date.toLocaleDateString('en-US', { weekday: 'short' }),
        income: dayIncome,
        expense: dayExpense,
        dailyBalance: dayBalance,
        cumulativeBalance
      });
    }

    // Return week info for UI display
    const weekInfo = {
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      isCurrentWeek: !weekStart
    };

    res.status(200).json({
      success: true,
      hasEnoughData: true,
      weekInfo,
      data: { chartData }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching balance chart data',
      error: error.message
    });
  }
};

// @desc    Get dashboard overview
// @route   GET /api/analytics/dashboard
// @access  Private
exports.getDashboard = async (req, res) => {
  try {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    // Get monthly income
    const monthlyIncome = await Income.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          month: now.getMonth() + 1,
          year: now.getFullYear()
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amount' }
        }
      }
    ]);

    // Get monthly expenses
    const monthlyExpenses = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startOfMonth, $lte: endOfMonth }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amount' }
        }
      }
    ]);

    // Get category breakdown
    const categoryBreakdown = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id),
          date: { $gte: startOfMonth, $lte: endOfMonth }
        }
      },
      {
        $group: {
          _id: '$category',
          total: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      {
        $sort: { total: -1 }
      }
    ]);

    // Get latest 10 expenses
    const latestExpenses = await Expense.find({ user: req.user.id })
      .sort({ date: -1, createdAt: -1 })
      .limit(10);

    // Check for 7-day chart availability - count unique expense dates
    const uniqueDates = await Expense.aggregate([
      {
        $match: {
          user: new mongoose.Types.ObjectId(req.user.id)
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$date' },
            month: { $month: '$date' },
            day: { $dayOfMonth: '$date' }
          }
        }
      }
    ]);
    const hasChartData = uniqueDates.length >= 7;

    const totalIncome = monthlyIncome[0]?.total || 0;
    const totalExpense = monthlyExpenses[0]?.total || 0;
    const balance = totalIncome - totalExpense;

    res.status(200).json({
      success: true,
      data: {
        overview: {
          totalIncome,
          totalExpense,
          balance,
          savingsRate: totalIncome > 0 ? ((balance / totalIncome) * 100).toFixed(2) : 0,
          month: now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
        },
        categoryBreakdown: categoryBreakdown.map(cat => ({
          category: cat._id,
          amount: cat.total,
          count: cat.count,
          percentage: totalExpense > 0 ? ((cat.total / totalExpense) * 100).toFixed(2) : 0
        })),
        latestExpenses,
        hasChartData
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard data',
      error: error.message
    });
  }
};
