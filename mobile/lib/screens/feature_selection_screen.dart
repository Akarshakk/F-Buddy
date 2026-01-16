import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'home/home_screen.dart';
import 'splitwise/splitwise_home_screen.dart';
import '../features/financial_calculator/calculator_feature.dart';

class FeatureSelectionScreen extends StatelessWidget {
  const FeatureSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColorsDark.background
        : const Color.fromARGB(255, 228, 228, 228);
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final secondaryColor =
        isDark ? AppColorsDark.secondary : AppColors.secondary;
    final textPrimaryColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to F-Buddy',
                style: AppTextStyles.heading1.copyWith(color: textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Choose how you want to manage your finances',
                style: AppTextStyles.body1.copyWith(color: textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Feature Card 1: Personal Expenses
              _buildFeatureCard(
                context,
                icon: Icons.trending_down,
                title: 'Personal Finance',
                subtitle: 'Track your personal expenses\nand income',
                color: primaryColor,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Feature Card 2: Group Expenses (SmartSplit)
              _buildFeatureCard(
                context,
                icon: Icons.group,
                title: 'Group Expenses',
                subtitle: 'Split expenses with friends\nand settle up',
                color: secondaryColor,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const SplitwiseHomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Feature Card 3: Personal Finance Manager (Calculator)
              _buildFeatureCard(
                context,
                icon: Icons.calculate,
                title: 'Personal Finance Manager',
                subtitle: 'Plan investments and\nanalyze returns',
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const FinanceManagerScreen()),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can switch between features anytime from the settings menu',
                        style: AppTextStyles.caption.copyWith(
                          color: textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.body2.copyWith(
                color: isDark
                    ? AppColorsDark.textSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Get Started',
                  style: AppTextStyles.body1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: color,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
