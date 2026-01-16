import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/splitwise_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_card.dart';
import 'add_income_screen.dart';
import '../splitwise/splitwise_home_screen.dart';

class DashboardTab extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const DashboardTab({super.key, this.onNavigateToProfile});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _touchedIndex = -1;
  DateTime _selectedMonth = DateTime.now();
  int _selectedWeekOfMonth =
      0; // 0 = current week, 1-5 = weeks of selected month

  // Get weeks of a month
  List<Map<String, dynamic>> _getWeeksOfMonth(DateTime month) {
    final weeks = <Map<String, dynamic>>[];

    // Add "Current Week" option
    weeks.add({
      'label': 'Current Week',
      'startDate': null, // null means use current 7 days
      'weekNum': 0,
    });

    // Get first day of month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Calculate weeks
    DateTime weekStart = firstDayOfMonth;
    int weekNum = 1;

    while (weekStart.isBefore(lastDayOfMonth) ||
        weekStart.isAtSameMomentAs(lastDayOfMonth)) {
      DateTime weekEnd = weekStart.add(const Duration(days: 6));
      if (weekEnd.isAfter(lastDayOfMonth)) {
        weekEnd = lastDayOfMonth;
      }

      final startDay = weekStart.day;
      final endDay = weekEnd.day;
      final monthName = DateFormat('MMM').format(weekStart);

      weeks.add({
        'label': 'Week $weekNum ($startDay-$endDay $monthName)',
        'startDate': DateFormat('yyyy-MM-dd').format(weekStart),
        'weekNum': weekNum,
      });

      weekStart = weekStart.add(const Duration(days: 7));
      weekNum++;
    }

    return weeks;
  }

  Future<void> _refreshData() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);

    await Future.wait([
      expenseProvider.fetchLatestExpenses(),
      incomeProvider.fetchCurrentMonthIncome(),
      analyticsProvider.fetchDashboardData(),
      analyticsProvider.fetchBalanceChartData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColorsDark.background
        : const Color.fromARGB(255, 228, 228, 228);
    final textPrimaryColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'User'} 👋',
                          style: AppTextStyles.heading2
                              .copyWith(color: textPrimaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM').format(DateTime.now()),
                          style: AppTextStyles.body2
                              .copyWith(color: textSecondaryColor),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to profile tab
                        widget.onNavigateToProfile?.call();
                      },
                      child: user?.profilePicture != null &&
                              user!.profilePicture!.isNotEmpty
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: MemoryImage(
                                base64Decode(
                                    user.profilePicture!.split(',').last),
                              ),
                            )
                          : CircleAvatar(
                              radius: 24,
                              backgroundColor: primaryColor,
                              child: Text(
                                (user?.name.isNotEmpty ?? false)
                                    ? user!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary Cards
                Consumer2<AnalyticsProvider, IncomeProvider>(
                  builder: (context, analytics, income, _) {
                    final dashboard = analytics.dashboardData;
                    return Column(
                      children: [
                        // Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: AppDecorations.gradientDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Monthly Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AddIncomeScreen(),
                                            ),
                                          )
                                          .then((_) => _refreshData());
                                    },
                                    icon: const Icon(Icons.add,
                                        color: Colors.white, size: 18),
                                    label: const Text(
                                      'Add Income',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${NumberFormat('#,##,###').format(dashboard?.balance ?? 0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildBalanceItem(
                                      'Income',
                                      dashboard?.totalIncome ??
                                          income.totalIncome,
                                      Icons.arrow_downward,
                                      Colors.greenAccent,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white24,
                                  ),
                                  Expanded(
                                    child: _buildBalanceItem(
                                      'Expenses',
                                      dashboard?.totalExpense ?? 0,
                                      Icons.arrow_upward,
                                      Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Stats
                        Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Savings Rate',
                                value: '${dashboard?.savingsRate ?? 0}%',
                                icon: Icons.savings_outlined,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryCard(
                                title: 'This Month',
                                value: dashboard?.month ?? '',
                                icon: Icons.calendar_today,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Category Pie Chart
                _buildPieChartSection(),
                const SizedBox(height: 24),

                _buildGroupExpensesSection(),
                const SizedBox(height: 24),

                // 7-Day Balance Chart
                _buildBalanceChartSection(),
                const SizedBox(height: 24),

                // Latest Expenses
                _buildLatestExpensesSection(),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
      String label, double amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        final categoryData = analytics.categoryData;

        if (categoryData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.cardDecoration,
            child: Column(
              children: [
                const Icon(Icons.pie_chart_outline,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'No expenses yet',
                  style: AppTextStyles.body1
                      .copyWith(color: AppColors.textSecondary),
                ),
                const Text(
                  'Add your first expense to see the breakdown',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expense Categories', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              const Text(
                'Monthly breakdown by category',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: categoryData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final isTouched = index == _touchedIndex;
                      final category = Category.getByName(data.category);

                      return PieChartSectionData(
                        color: category.color,
                        value: data.amount,
                        title: isTouched ? '${data.percentage}%' : '',
                        radius: isTouched ? 60 : 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryData.map((data) {
                  final category = Category.getByName(data.category);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            Icon(category.icon,
                                size: 14, color: category.color),
                            const SizedBox(width: 4),
                            Text(
                              category.displayName,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${NumberFormat.compact().format(data.amount)}',
                          style: AppTextStyles.caption.copyWith(
                            color: category.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceChartSection() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        // Debug: Print chart data status
        debugPrint('hasEnoughDataForChart: ${analytics.hasEnoughDataForChart}');
        debugPrint(
            'balanceChartData length: ${analytics.balanceChartData.length}');

        if (!analytics.hasEnoughDataForChart) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.cardDecoration,
            child: Column(
              children: [
                const Icon(Icons.show_chart,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  '7-Day Balance Chart',
                  style: AppTextStyles.body1
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  analytics.daysRemainingForChart > 0
                      ? 'Add expenses for ${analytics.daysRemainingForChart} more unique dates'
                      : 'Start adding expenses to see the chart',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final chartData = analytics.balanceChartData;
        if (chartData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.cardDecoration,
            child: Column(
              children: [
                const Icon(Icons.show_chart,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Loading chart data...',
                  style: AppTextStyles.body1
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ClipRect(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('7-Day Overview', style: AppTextStyles.heading3),
                    _buildWeekSelector(analytics),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  analytics.isCurrentWeek
                      ? 'Income vs Expenses (Last 7 Days)'
                      : 'Income vs Expenses',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 20),
                ClipRect(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 219),
                    child: _buildLayeredAreaChart(chartData),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChartLegendItem('Income', AppColors.income),
                      const SizedBox(width: 24),
                      _buildChartLegendItem('Expense', AppColors.expense),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayeredAreaChart(List<ChartDataPoint> chartData) {
    final maxY = _getMaxY(chartData);

    // Create income spots
    final incomeSpots = chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.income);
    }).toList();

    // Create expense spots
    final expenseSpots = chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.expense);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIncome = spot.barIndex == 0;
                final label = isIncome ? 'Income' : 'Expense';
                final color = isIncome ? AppColors.income : AppColors.expense;
                return LineTooltipItem(
                  '$label\n₹${NumberFormat('#,##0').format(spot.y)}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textSecondary.withOpacity(0.15),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    chartData[index].dayName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₹${NumberFormat.compact().format(value)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
              reservedSize: 45,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Income line with gradient fill (on top)
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.income,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.income,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.income.withOpacity(0.3),
                  AppColors.income.withOpacity(0.1),
                  AppColors.income.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Expense line with gradient fill (below)
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.expense,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.expense,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.expense.withOpacity(0.25),
                  AppColors.expense.withOpacity(0.1),
                  AppColors.expense.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _getMaxY(List<ChartDataPoint> data) {
    double max = 0;
    for (final d in data) {
      if (d.income > max) max = d.income;
      if (d.expense > max) max = d.expense;
    }
    return max == 0 ? 1000 : max * 1.2;
  }

  Widget _buildLatestExpensesSection() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, _) {
        final expenses = expenseProvider.latestExpenses;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardDecoration,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Latest Expenses', style: AppTextStyles.heading3),
                  TextButton(
                    onPressed: () {
                      // Navigate to expenses tab
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'No expenses yet',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < expenses.length; i++) ...[
                      ExpenseCard(expense: expenses[i]),
                      if (i < expenses.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekSelector(AnalyticsProvider analytics) {
    return GestureDetector(
      onTap: () => _showWeekPickerDialog(analytics),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              _selectedWeekOfMonth == 0
                  ? 'Current'
                  : 'Week $_selectedWeekOfMonth',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showWeekPickerDialog(AnalyticsProvider analytics) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 202, 215, 212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Select Week',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),

            // Month selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                      Navigator.pop(context);
                      _showWeekPickerDialog(analytics);
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                      Navigator.pop(context);
                      _showWeekPickerDialog(analytics);
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Week options
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _getWeeksOfMonth(_selectedMonth).length,
                itemBuilder: (context, index) {
                  final week = _getWeeksOfMonth(_selectedMonth)[index];
                  final isSelected = _selectedWeekOfMonth == week['weekNum'];

                  return ListTile(
                    onTap: () async {
                      setState(() {
                        _selectedWeekOfMonth = week['weekNum'];
                      });
                      Navigator.pop(context);

                      // Fetch data for selected week
                      await analytics.fetchBalanceChartData(
                        weekStart: week['startDate'],
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          week['weekNum'] == 0 ? '⟳' : '${week['weekNum']}',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      week['label'],
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupExpensesSection() {
    return Consumer2<SplitWiseProvider, AuthProvider>(
      builder: (context, splitwiseProvider, authProvider, _) {
        final groups = splitwiseProvider.groups;
        final userId = authProvider.user?.id ?? '';

        if (groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDecorations.cardDecoration,
            child: Column(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'No Group Expenses',
                  style: AppTextStyles.body1
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create or join a group to split expenses with friends',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const SplitwiseHomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Go to Groups'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate total spent by user across all groups
        double totalSpent = 0;
        for (var group in groups) {
          final userExpenses = group.expenses.where((e) => e.paidBy == userId);
          totalSpent += userExpenses.fold(0.0, (sum, e) => sum + e.amount);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Group Expenses', style: AppTextStyles.heading3),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const SplitwiseHomeScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Your spending in group expenses',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.payment,
                              color: AppColors.primary, size: 20),
                          const SizedBox(height: 8),
                          Text(
                            'Total Spent',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${NumberFormat('#,##,###').format(totalSpent)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.groups,
                              color: AppColors.secondary, size: 20),
                          const SizedBox(height: 8),
                          Text(
                            'Active Groups',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${groups.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Group breakdown
              if (groups.isNotEmpty) ...[
                Text(
                  'Recent Groups',
                  style:
                      AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...groups.take(3).map((group) {
                  final userExpenses =
                      group.expenses.where((e) => e.paidBy == userId);
                  final groupTotal =
                      userExpenses.fold(0.0, (sum, e) => sum + e.amount);
                  final userMember = group.members.firstWhere(
                    (m) => m.userId == userId,
                    orElse: () => group.members.first,
                  );
                  final balance = userMember.balance;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.group,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.members.length} members • ${group.expenses.length} expenses',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${groupTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              balance >= 0
                                  ? 'Gets ₹${balance.abs().toStringAsFixed(0)}'
                                  : 'Owes ₹${balance.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        );
      },
    );
  }
}
