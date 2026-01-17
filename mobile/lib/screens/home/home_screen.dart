import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/debt_reminder_service.dart';
import '../kyc/kyc_screen.dart';
import '../splitwise/splitwise_home_screen.dart';
import '../feature_selection_screen.dart';
import 'dashboard_tab.dart';
import 'expenses_tab.dart';
import 'add_expense_screen.dart';
import 'profile_tab.dart';
import 'live_finance_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final analyticsProvider =
        Provider.of<AnalyticsProvider>(context, listen: false);
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);

    await Future.wait([
      expenseProvider.fetchLatestExpenses(),
      incomeProvider.fetchCurrentMonthIncome(),
      analyticsProvider.fetchDashboardData(),
      analyticsProvider.fetchBalanceChartData(),
      debtProvider.fetchDebts(),
    ]);

    // Check for debt reminders after loading data
    if (mounted) {
      DebtReminderService.checkAndShowReminders(
        context,
        debtProvider.fetchDebtsDueToday,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final secondaryColor =
        isDark ? AppColorsDark.secondary : AppColors.secondary;
    final textSecondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    // Create tabs with callback for navigation
    final tabs = [
      DashboardTab(
        onNavigateToProfile: () => setState(() => _currentIndex = 2),
      ),
      const ExpensesTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FeatureSelectionScreen()),
          ),
          tooltip: 'Back to Menu',
        ),
        title: Text(
          'F Buddy',
          style: AppTextStyles.heading2.copyWith(color: primaryColor),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            color: Colors.purple, // Distinct color to stand out
            tooltip: 'Live Finance Tracking',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const LiveFinanceTrackingScreen()),
              );
            },
          ),
          // KYC Status Icon
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isVerified = auth.user?.kycStatus == 'VERIFIED';
              return IconButton(
                icon: Icon(
                  isVerified
                      ? Icons.verified_user
                      : Icons.verified_user_outlined,
                  color: isVerified ? Colors.green : Colors.orange,
                ),
                tooltip: isVerified ? 'KYC Verified' : 'Complete KYC',
                onPressed: () {
                  if (!isVerified) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => KycScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your account is verified! ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: primaryColor,
            ),
            onPressed: () {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.groups, color: primaryColor),
            tooltip: 'Switch to Group Expenses',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SplitwiseHomeScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomAppBar(
        color: surfaceColor,
        elevation: 8,
        padding: EdgeInsets.zero,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard,
                  'Dashboard', primaryColor, textSecondaryColor),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: _buildNavItem(
                    1,
                    Icons.receipt_long_outlined,
                    Icons.receipt_long,
                    'Expenses',
                    primaryColor,
                    textSecondaryColor),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: _buildNavItem(2, Icons.person_outlined, Icons.person,
                      'Profile', primaryColor, textSecondaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 16),
        child: FloatingActionButton(
          backgroundColor: secondaryColor,
          elevation: 8,
          onPressed: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                )
                .then((_) => _loadData());
          },
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon,
      String label, Color primaryColor, Color textSecondaryColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? primaryColor : textSecondaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? primaryColor : textSecondaryColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
