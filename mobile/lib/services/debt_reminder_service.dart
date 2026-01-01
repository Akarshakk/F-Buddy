import 'package:flutter/material.dart';
import '../models/debt.dart';

class DebtReminderService {
  /// Show a popup dialog for debts due today
  static void showDebtDueReminder(BuildContext context, List<Debt> debtsDueToday) {
    if (debtsDueToday.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DebtReminderDialog(debts: debtsDueToday),
    );
  }

  /// Check if there are any debts due today and show reminder
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
    // Separate debts by type
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
            // Bell Icon with animation effect
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

            // Debts to collect (They owe me)
            if (theyOweMe.isNotEmpty) ...[
              _buildDebtSection(
                title: '💰 To Collect Today',
                debts: theyOweMe,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            // Debts to pay (I owe)
            if (iOwe.isNotEmpty) ...[
              _buildDebtSection(
                title: '💸 To Pay Today',
                debts: iOwe,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),

            // Action Buttons
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to debt list screen
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
}
