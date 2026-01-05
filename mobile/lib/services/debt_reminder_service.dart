import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../providers/income_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/analytics_provider.dart';

class DebtReminderService {
  static void showDebtDueReminder(BuildContext context, List<Debt> debtsDueToday) {
    if (debtsDueToday.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DebtReminderDialog(debts: debtsDueToday),
    );
  }

  static Future<void> checkAndShowReminders(
    BuildContext context,
    Future<List<Debt>> Function() fetchDebtsDueToday,
  ) async {
    try {
      final debtsDueToday = await fetchDebtsDueToday();
      if (debtsDueToday.isNotEmpty && context.mounted) {
        showDebtDueReminder(context, debtsDueToday);
      }
    } catch (e) {
      debugPrint('Error checking debt reminders: $e');
    }
  }
}

class _DebtReminderDialog extends StatelessWidget {
  final List<Debt> debts;

  const _DebtReminderDialog({required this.debts});

  @override
  Widget build(BuildContext context) {
    final theyOweMe = debts.where((d) => d.type == DebtType.theyOweMe).toList();
    final iOwe = debts.where((d) => d.type == DebtType.iOwe).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Text('🔔', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 16),

            const Text(
              'Payment Reminder!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have ${debts.length} debt${debts.length > 1 ? 's' : ''} due today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            if (theyOweMe.isNotEmpty) ...[
              _buildDebtSection(
                title: '💰 To Collect Today',
                debts: theyOweMe,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            if (iOwe.isNotEmpty) ...[
              _buildDebtSection(
                title: '💸 To Pay Today',
                debts: iOwe,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Remind Later'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleSettled(context, theyOweMe, iOwe),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Settled'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/debts');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSection({
    required String title,
    required List<Debt> debts,
    required Color color,
  }) {
    final totalAmount = debts.fold<double>(0, (sum, d) => sum + d.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...debts.map((debt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        debt.personName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '₹${debt.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSettled(
    BuildContext context,
    List<Debt> theyOweMe,
    List<Debt> iOwe,
  ) async {
    try {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);

      final totalOwedToMe = theyOweMe.fold<double>(0, (sum, debt) => sum + debt.amount);
      final totalIOwe = iOwe.fold<double>(0, (sum, debt) => sum + debt.amount);

      if (totalOwedToMe > 0) {
        await incomeProvider.addIncome(
          amount: totalOwedToMe,
          description: 'Debt collection from ${theyOweMe.length} debt${theyOweMe.length > 1 ? 's' : ''}',
          source: 'debt_settlement',
        );
      }

      if (totalIOwe > 0) {
        await expenseProvider.addExpense(
          amount: totalIOwe,
          category: 'Debt Payment',
          description: 'Debt payment to ${iOwe.length} person${iOwe.length > 1 ? 's' : ''}',
        );
      }

      for (final debt in [...theyOweMe, ...iOwe]) {
        await debtProvider.settleDebt(debt.id);
      }

      await Future.wait([
        incomeProvider.fetchCurrentMonthIncome(),
        expenseProvider.fetchLatestExpenses(),
      ]);

      await Future.delayed(const Duration(milliseconds: 500));

      await Future.wait([
        analyticsProvider.fetchDashboardData(),
        analyticsProvider.fetchBalanceChartData(),
      ]);

      if (context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ All debts settled! ${totalOwedToMe > 0 ? 'Received ₹${totalOwedToMe.toStringAsFixed(0)}. ' : ''}${totalIOwe > 0 ? 'Paid ₹${totalIOwe.toStringAsFixed(0)}.' : ''}Balance updated!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          await analyticsProvider.fetchDashboardData();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to settle debts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
