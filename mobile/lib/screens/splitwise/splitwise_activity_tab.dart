import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/splitwise_provider.dart';
import '../../providers/auth_provider.dart';

class SplitwiseActivityTab extends StatelessWidget {
  const SplitwiseActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SplitWiseProvider, AuthProvider>(
      builder: (context, splitwiseProvider, authProvider, _) {
        final groups = splitwiseProvider.groups;
        final userId = authProvider.user?.id ?? '';

        // Collect all recent activities
        List<Map<String, dynamic>> activities = [];

        // Add recent expenses from all groups
        for (var group in groups) {
          for (var expense in group.expenses) {
            activities.add({
              'type': 'expense',
              'groupName': group.name,
              'description': expense.description,
              'amount': expense.amount,
              'paidBy': expense.paidByName,
              'date': expense.date,
              'category': expense.category,
              'isYou': expense.paidBy == userId,
            });
          }
        }

        // Add settlement suggestions
        for (var group in groups) {
          for (var member in group.members) {
            if (member.userId == userId && member.balance.abs() > 0.01) {
              activities.add({
                'type': 'settlement',
                'groupName': group.name,
                'balance': member.balance,
                'date': DateTime.now(),
              });
            }
          }
        }

        // Sort by date (most recent first)
        activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        if (activities.isEmpty) {
          return Scaffold(
            backgroundColor: FinzoTheme.background(context),
            body: _buildEmptyState(context),
          );
        }

        return Scaffold(
          backgroundColor: FinzoTheme.background(context),
          body: ListView.builder(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            itemCount: activities.length > 20 ? 20 : activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final type = activity['type'] as String;

              if (type == 'expense') {
                return _buildExpenseCard(context, activity);
              } else {
                return _buildSettlementCard(context, activity);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FinzoColors.brandPrimary.withOpacity(0.1),
                  FinzoColors.brandSecondary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: FinzoTheme.brandAccent(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.lg),
          Text(
            'No Activity Yet',
            style: FinzoTypography.titleLarge(
              color: FinzoTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.sm),
          Text(
            'Your activity will appear here',
            style: FinzoTypography.bodyMedium(
              color: FinzoTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Map<String, dynamic> activity) {
    final date = activity['date'] as DateTime;
    final formattedDate = DateFormat('MMM d, h:mm a').format(date);
    final isYou = activity['isYou'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: FinzoSpacing.md),
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        boxShadow: FinzoShadows.small,
        border: Border.all(color: FinzoTheme.divider(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isYou 
                    ? FinzoColors.success.withOpacity(0.1)
                    : FinzoColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(FinzoRadius.md),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: isYou ? FinzoColors.success : FinzoColors.info,
                size: 22,
              ),
            ),
            const SizedBox(width: FinzoSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['description'] as String,
                    style: FinzoTypography.titleSmall(
                      color: FinzoTheme.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activity['paidBy']} paid in ${activity['groupName']}',
                    style: FinzoTypography.bodySmall(
                      color: FinzoTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: FinzoTypography.labelSmall(
                      color: FinzoTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FinzoSpacing.sm,
                vertical: FinzoSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isYou 
                    ? FinzoColors.success.withOpacity(0.1)
                    : FinzoTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(FinzoRadius.sm),
              ),
              child: Text(
                '₹${(activity['amount'] as double).toStringAsFixed(0)}',
                style: FinzoTypography.titleSmall(
                  color: isYou ? FinzoColors.success : FinzoTheme.textPrimary(context),
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(BuildContext context, Map<String, dynamic> activity) {
    final balance = activity['balance'] as double;
    final isOwed = balance >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: FinzoSpacing.md),
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        border: Border.all(
          color: isOwed 
              ? FinzoColors.success.withOpacity(0.4)
              : FinzoColors.warning.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOwed 
                    ? FinzoColors.success.withOpacity(0.1)
                    : FinzoColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(FinzoRadius.md),
              ),
              child: Icon(
                isOwed 
                    ? Icons.notifications_active_rounded
                    : Icons.notification_important_rounded,
                color: isOwed ? FinzoColors.success : FinzoColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: FinzoSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwed ? '💰 Settlement Pending' : '⚠️ Payment Required',
                    style: FinzoTypography.titleSmall(
                      color: isOwed ? FinzoColors.success : FinzoColors.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'In ${activity['groupName']}',
                    style: FinzoTypography.bodySmall(
                      color: FinzoTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '₹${balance.abs().toStringAsFixed(0)}',
              style: FinzoTypography.titleMedium(
                color: isOwed ? FinzoColors.success : FinzoColors.warning,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


