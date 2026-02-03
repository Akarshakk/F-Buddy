import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/debt_reminder_service.dart';
import '../kyc/kyc_screen.dart';
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
    // Create tabs with callback for navigation
    final tabs = [
      DashboardTab(
        onNavigateToProfile: () => setState(() => _currentIndex = 2),
      ),
      const ExpensesTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        backgroundColor: FinzoTheme.background(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: FinzoTheme.textPrimary(context)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
          tooltip: 'Back to Menu',
        ),
        title: Text(
          'Finzo',
          style: FinzoTypography.headlineLarge(color: FinzoTheme.textPrimary(context)).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.pie_chart_outline,
              color: FinzoTheme.brandAccent(context),
            ),
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
                  color: isVerified ? FinzoTheme.success(context) : FinzoTheme.warning(context),
                ),
                tooltip: isVerified ? 'KYC Verified' : 'Complete KYC',
                onPressed: () {
                  if (!isVerified) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => KycScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Your account is verified! ✅'),
                        backgroundColor: FinzoTheme.success(context),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              FinzoTheme.isDark(context) ? Icons.light_mode : Icons.dark_mode,
              color: FinzoTheme.textPrimary(context),
            ),
            onPressed: () {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.groups_outlined, color: FinzoTheme.textPrimary(context)),
            tooltip: 'Switch to Group Expenses',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/group-finance');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: FinzoTheme.surface(context),
          border: Border(
            top: BorderSide(
              color: FinzoTheme.divider(context),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Expenses'),
                _buildNavItem(2, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FinzoTheme.brandAccent(context),
        elevation: 4,
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
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.lg, vertical: FinzoSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? FinzoTheme.textPrimary(context) 
                  : FinzoTheme.textSecondary(context),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FinzoTypography.labelSmall().copyWith(
                color: isSelected 
                    ? FinzoTheme.textPrimary(context) 
                    : FinzoTheme.textSecondary(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


