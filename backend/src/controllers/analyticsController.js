const Expense = require('../models/Expense');
const Income = require('../models/Income');

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

    const categoryData = await Expense.aggregateByCategory(req.user.id, startDate, endDate);

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
    const expenses = await Expense.findByUser(req.user.id, { startDate, endDate });
    const totalExpense = expenses.reduce((sum, exp) => sum + exp.amount, 0);
    const expenseCount = expenses.length;

    // Get total income for the period
    const totalIncome = await Income.getTotalForRange(req.user.id, startDate, endDate);
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
        expenseCount,
        incomeCount: 0, // Simplified
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
exports.getBalanceChart = async (req, res) => {
  try {
    const { weekStart } = req.query;

    let startDate, endDate;

    if (weekStart) {
      startDate = new Date(weekStart);
      startDate.setHours(0, 0, 0, 0);
      endDate = new Date(startDate);
      endDate.setDate(startDate.getDate() + 6);
      endDate.setHours(23, 59, 59, 999);
    } else {
      endDate = new Date();
      startDate = new Date();
      startDate.setDate(endDate.getDate() - 6);
      startDate.setHours(0, 0, 0, 0);
    }

    // Get daily expenses
    const dailyExpenses = await Expense.getDailyExpenses(req.user.id, startDate, endDate);

    // Get daily income
    const dailyIncome = await Income.getDailyIncome(req.user.id, startDate, endDate);

    // Create maps for easy lookup
    const expenseMap = new Map();
    dailyExpenses.forEach(item => {
      const key = `${item.year}-${item.month}-${item.day}`;
      expenseMap.set(key, item.totalExpense);
    });

    const incomeMap = new Map();
    dailyIncome.forEach(item => {
      const key = `${item.year}-${item.month}-${item.day}`;
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
    console.error('[Analytics] Error fetching balance chart:', error); // Critical log
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
    const totalIncome = await Income.getTotalForMonth(req.user.id, now.getMonth() + 1, now.getFullYear());

    // Get monthly expenses
    const expenses = await Expense.findByUser(req.user.id, {
      startDate: startOfMonth,
      endDate: endOfMonth
    });
    const totalExpense = expenses.reduce((sum, exp) => sum + exp.amount, 0);

    // Get category breakdown
    const categoryData = await Expense.aggregateByCategory(req.user.id, startOfMonth, endOfMonth);
    const categoryBreakdown = categoryData.map(cat => ({
      category: cat._id,
      amount: cat.totalAmount,
      count: cat.count,
      percentage: totalExpense > 0 ? ((cat.totalAmount / totalExpense) * 100).toFixed(2) : 0
    }));

    // Get latest 10 expenses
    const latestExpenses = await Expense.findByUser(req.user.id, { limit: 10 });

    // Check for chart data availability
    const uniqueDatesCount = await Expense.getUniqueDatesCount(req.user.id);
    const hasChartData = uniqueDatesCount >= 7;

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
        categoryBreakdown,
        latestExpenses,
        hasChartData
      }
    });
  } catch (error) {
    console.error('[Analytics] Error fetching dashboard data:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard data',
      error: error.message
    });
  }
};
