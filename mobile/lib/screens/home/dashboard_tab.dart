import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/splitwise_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_card.dart';
import '../../l10n/app_localizations.dart';
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

    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: RefreshIndicator(
          color: FinzoTheme.brandAccent(context),
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(FinzoSpacing.md),
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
                          style: FinzoTypography.headlineMedium(color: FinzoTheme.textPrimary(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM').format(DateTime.now()),
                          style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context)),
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
                              backgroundColor: FinzoTheme.brandAccent(context),
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
                const SizedBox(height: FinzoSpacing.lg),

                // Summary Cards
                Consumer2<AnalyticsProvider, IncomeProvider>(
                  builder: (context, analytics, income, _) {
                    final dashboard = analytics.dashboardData;
                    return Column(
                      children: [
                        // Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(FinzoSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                FinzoTheme.brandAccent(context),
                                FinzoTheme.brandAccent(context).withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(FinzoRadius.lg),
                            boxShadow: FinzoShadows.medium,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Monthly Balance',
                                    style: FinzoTypography.bodyMedium().copyWith(
                                      color: Colors.white70,
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
                                    label: Text(
                                      'Add Income',
                                      style: FinzoTypography.labelSmall().copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: FinzoSpacing.sm),
                              Text(
                                '₹${NumberFormat('#,##,###').format(dashboard?.balance ?? 0)}',
                                style: FinzoTypography.displayMedium().copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: FinzoSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildBalanceItem(
                                      'Income',
                                      dashboard?.totalIncome ??
                                          income.totalIncome,
                                      Icons.arrow_downward,
                                      FinzoColors.success,
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
                                      FinzoColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: FinzoSpacing.md),

                        // Quick Stats
                        Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Savings Rate',
                                value: '${dashboard?.savingsRate ?? 0}%',
                                icon: Icons.savings_outlined,
                                color: FinzoColors.success,
                              ),
                            ),
                            const SizedBox(width: FinzoSpacing.sm),
                            Expanded(
                              child: SummaryCard(
                                title: 'This Month',
                                value: dashboard?.month ?? '',
                                icon: Icons.calendar_today,
                                color: FinzoColors.info,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: FinzoSpacing.lg),

                // Category Pie Chart
                _buildPieChartSection(),
                const SizedBox(height: FinzoSpacing.lg),

                _buildGroupExpensesSection(),
                const SizedBox(height: FinzoSpacing.lg),

                // 7-Day Balance Chart
                _buildBalanceChartSection(),
                const SizedBox(height: FinzoSpacing.lg),

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
      padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: FinzoTypography.labelSmall().copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: FinzoTypography.titleMedium().copyWith(
              color: Colors.white,
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
            padding: const EdgeInsets.all(FinzoSpacing.lg),
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(FinzoRadius.lg),
              boxShadow: FinzoShadows.small,
            ),
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline,
                    size: 48, color: FinzoTheme.textTertiary(context)),
                const SizedBox(height: FinzoSpacing.sm),
                Text(
                  'No expenses yet',
                  style: FinzoTypography.bodyMedium().copyWith(
                    color: FinzoTheme.textSecondary(context),
                  ),
                ),
                Text(
                  'Add your first expense to see the breakdown',
                  style: FinzoTypography.bodySmall().copyWith(
                    color: FinzoTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(FinzoSpacing.md),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: BorderRadius.circular(FinzoRadius.lg),
            boxShadow: FinzoShadows.small,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Expense Categories', style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context))),
              const SizedBox(height: FinzoSpacing.xs),
              Text(
                'Monthly breakdown by category',
                style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context)),
              ),
              const SizedBox(height: FinzoSpacing.md),
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
              const SizedBox(height: FinzoSpacing.md),
              Wrap(
                spacing: FinzoSpacing.sm,
                runSpacing: FinzoSpacing.sm,
                children: categoryData.map((data) {
                  final category = Category.getByName(data.category);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: FinzoSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(FinzoRadius.full),
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
                              style: FinzoTypography.labelSmall(
                                color: FinzoTheme.textPrimary(context),
                              ).copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${NumberFormat.compact().format(data.amount)}',
                          style: FinzoTypography.labelSmall().copyWith(
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
            padding: const EdgeInsets.all(FinzoSpacing.lg),
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(FinzoRadius.lg),
              boxShadow: FinzoShadows.small,
            ),
            child: Column(
              children: [
                Icon(Icons.show_chart,
                    size: 48, color: FinzoTheme.textTertiary(context)),
                const SizedBox(height: FinzoSpacing.sm),
                Text(
                  '7-Day Balance Chart',
                  style: FinzoTypography.bodyMedium().copyWith(
                    color: FinzoTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: FinzoSpacing.sm),
                Text(
                  analytics.daysRemainingForChart > 0
                      ? 'Add expenses for ${analytics.daysRemainingForChart} more unique dates'
                      : 'Start adding expenses to see the chart',
                  style: FinzoTypography.bodySmall().copyWith(
                    color: FinzoTheme.textTertiary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final chartData = analytics.balanceChartData;
        if (chartData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(FinzoSpacing.lg),
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(FinzoRadius.lg),
              boxShadow: FinzoShadows.small,
            ),
            child: Column(
              children: [
                Icon(Icons.show_chart,
                    size: 48, color: FinzoTheme.textTertiary(context)),
                const SizedBox(height: FinzoSpacing.sm),
                Text(
                  'Loading chart data...',
                  style: FinzoTypography.bodyMedium().copyWith(
                    color: FinzoTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          );
        }

        return ClipRect(
          child: Container(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(FinzoRadius.lg),
              boxShadow: FinzoShadows.small,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('7-Day Overview', style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context))),
                    _buildWeekSelector(analytics),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  analytics.isCurrentWeek
                      ? 'Income vs Expenses (Last 7 Days)'
                      : 'Income vs Expenses',
                  style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context)),
                ),
                const SizedBox(height: FinzoSpacing.lg),
                ClipRect(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 219),
                    child: _buildLayeredAreaChart(chartData),
                  ),
                ),
                const SizedBox(height: FinzoSpacing.md),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChartLegendItem('Income', FinzoColors.success),
                      const SizedBox(width: FinzoSpacing.lg),
                      _buildChartLegendItem('Expense', FinzoColors.error),
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
                final color = isIncome ? FinzoColors.success : FinzoColors.error;
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
              color: FinzoTheme.textSecondary(context).withOpacity(0.15),
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
                    style: FinzoTypography.labelSmall().copyWith(
                      color: FinzoTheme.textSecondary(context),
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
                    style: FinzoTypography.labelSmall().copyWith(
                      fontSize: 10,
                      color: FinzoTheme.textSecondary(context),
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
            color: FinzoColors.success,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: FinzoColors.success,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FinzoColors.success.withOpacity(0.3),
                  FinzoColors.success.withOpacity(0.1),
                  FinzoColors.success.withOpacity(0.0),
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
            color: FinzoColors.error,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: FinzoColors.error,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FinzoColors.error.withOpacity(0.25),
                  FinzoColors.error.withOpacity(0.1),
                  FinzoColors.error.withOpacity(0.0),
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
          style: FinzoTypography.labelSmall().copyWith(
            color: FinzoTheme.textSecondary(context),
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
          padding: const EdgeInsets.all(FinzoSpacing.md),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: BorderRadius.circular(FinzoRadius.lg),
            boxShadow: FinzoShadows.small,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest Expenses', style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context))),
                  TextButton(
                    onPressed: () {
                      // Navigate to expenses tab
                    },
                    child: Text(
                      'See All',
                      style: FinzoTypography.labelMedium(color: FinzoTheme.brandAccent(context)),
                    ),
                  ),
                ],
              ),
              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.lg),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: FinzoTheme.textTertiary(context)),
                        const SizedBox(height: FinzoSpacing.sm),
                        Text(
                          'No expenses yet',
                          style: FinzoTypography.bodyMedium().copyWith(
                            color: FinzoTheme.textSecondary(context),
                          ),
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
                      if (i < expenses.length - 1) Divider(height: 1, color: FinzoTheme.divider(context)),
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
        padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: FinzoTheme.brandAccent(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(FinzoRadius.md),
          border: Border.all(color: FinzoTheme.brandAccent(context).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today,
                size: 14, color: FinzoTheme.brandAccent(context)),
            const SizedBox(width: 6),
            Text(
              _selectedWeekOfMonth == 0
                  ? 'Current'
                  : 'Week $_selectedWeekOfMonth',
              style: FinzoTypography.labelSmall().copyWith(
                color: FinzoTheme.brandAccent(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 18, color: FinzoTheme.brandAccent(context)),
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
        decoration: BoxDecoration(
          color: FinzoTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(FinzoRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: FinzoSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FinzoTheme.divider(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: FinzoSpacing.md),

            // Title
            Text(
              'Select Week',
              style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context)),
            ),
            const SizedBox(height: FinzoSpacing.sm),

            // Month selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.md),
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
                    icon: Icon(Icons.chevron_left, color: FinzoTheme.textPrimary(context)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: FinzoSpacing.md, vertical: FinzoSpacing.sm),
                    decoration: BoxDecoration(
                      color: FinzoTheme.brandAccent(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(FinzoRadius.full),
                    ),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: FinzoTypography.labelMedium().copyWith(
                        color: FinzoTheme.brandAccent(context),
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
                    icon: Icon(Icons.chevron_right, color: FinzoTheme.textPrimary(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FinzoSpacing.md),

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
                            ? FinzoTheme.brandAccent(context)
                            : FinzoTheme.brandAccent(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          week['weekNum'] == 0 ? '⟳' : '${week['weekNum']}',
                          style: FinzoTypography.labelMedium().copyWith(
                            color: isSelected
                                ? Colors.white
                                : FinzoTheme.brandAccent(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      week['label'],
                      style: FinzoTypography.bodyMedium().copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? FinzoTheme.brandAccent(context)
                            : FinzoTheme.textPrimary(context),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: FinzoTheme.brandAccent(context))
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: FinzoSpacing.md),
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
            padding: const EdgeInsets.all(FinzoSpacing.lg),
            decoration: AppDecorations.cardDecoration,
            child: Column(
              children: [
                Icon(Icons.groups_outlined,
                    size: 48, color: FinzoTheme.textTertiary(context)),
                const SizedBox(height: FinzoSpacing.sm),
                Text(
                  'No Group Expenses',
                  style: FinzoTypography.bodyMedium().copyWith(
                    color: FinzoTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: FinzoSpacing.sm),
                Text(
                  'Create or join a group to split expenses with friends',
                  style: FinzoTypography.bodySmall().copyWith(
                    color: FinzoTheme.textTertiary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FinzoSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const SplitwiseHomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Go to Groups'),
                  style: FilledButton.styleFrom(
                    backgroundColor: FinzoTheme.brandAccent(context),
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
          padding: const EdgeInsets.all(FinzoSpacing.md),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: BorderRadius.circular(FinzoRadius.lg),
            boxShadow: FinzoShadows.small,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Group Expenses', style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context))),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const SplitwiseHomeScreen()),
                      );
                    },
                    child: Text(
                      'View All',
                      style: FinzoTypography.labelMedium(color: FinzoTheme.brandAccent(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your spending in group expenses',
                style: FinzoTypography.bodySmall().copyWith(
                  color: FinzoTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: FinzoSpacing.md),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(FinzoSpacing.sm),
                      decoration: BoxDecoration(
                        color: FinzoTheme.brandAccent(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        border: Border.all(
                            color: FinzoTheme.brandAccent(context).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.payment,
                              color: FinzoTheme.brandAccent(context), size: 20),
                          const SizedBox(height: FinzoSpacing.sm),
                          Text(
                            'Total Spent',
                            style: FinzoTypography.labelSmall().copyWith(
                              color: FinzoTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${NumberFormat('#,##,###').format(totalSpent)}',
                            style: FinzoTypography.titleMedium().copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: FinzoSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(FinzoSpacing.sm),
                      decoration: BoxDecoration(
                        color: FinzoColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        border: Border.all(
                            color: FinzoColors.info.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.groups,
                              color: FinzoColors.info, size: 20),
                          const SizedBox(height: FinzoSpacing.sm),
                          Text(
                            'Active Groups',
                            style: FinzoTypography.labelSmall().copyWith(
                              color: FinzoTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${groups.length}',
                            style: FinzoTypography.titleMedium().copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FinzoSpacing.md),

              // Group breakdown
              if (groups.isNotEmpty) ...[
                Text(
                  'Recent Groups',
                  style: FinzoTypography.labelMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: FinzoSpacing.sm),
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
                    margin: const EdgeInsets.only(bottom: FinzoSpacing.sm),
                    padding: const EdgeInsets.all(FinzoSpacing.sm),
                    decoration: BoxDecoration(
                      color: FinzoTheme.surface(context),
                      borderRadius: BorderRadius.circular(FinzoRadius.md),
                      border: Border.all(
                          color: FinzoTheme.divider(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FinzoSpacing.sm),
                          decoration: BoxDecoration(
                            color: FinzoTheme.brandAccent(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(FinzoRadius.md),
                          ),
                          child: Icon(
                            Icons.group,
                            color: FinzoTheme.brandAccent(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: FinzoSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: FinzoTypography.bodyMedium().copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.members.length} members • ${group.expenses.length} expenses',
                                style: FinzoTypography.labelSmall().copyWith(
                                  color: FinzoTheme.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${groupTotal.toStringAsFixed(0)}',
                              style: FinzoTypography.labelMedium().copyWith(
                                fontWeight: FontWeight.bold,
                                color: FinzoTheme.brandAccent(context),
                              ),
                            ),
                            Text(
                              balance >= 0
                                  ? 'Gets ₹${balance.abs().toStringAsFixed(0)}'
                                  : 'Owes ₹${balance.abs().toStringAsFixed(0)}',
                              style: FinzoTypography.labelSmall().copyWith(
                                color: balance >= 0 ? FinzoColors.success : FinzoColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}