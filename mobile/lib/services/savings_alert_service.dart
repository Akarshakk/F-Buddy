import 'package:flutter/material.dart';
import '../config/theme.dart';

enum SavingsAlertType {
  warning,      // About to exceed savings target
  danger,       // Exceeded savings target
  success,      // On track to meet savings target
  celebration,  // Great progress towards savings
}

class SavingsAlertService {
  /// Calculate savings status based on income, expenses, and target
  static Map<String, dynamic> calculateSavingsStatus({
    required double totalIncome,
    required double totalExpenses,
    required double savingsTargetPercent,
  }) {
    if (totalIncome <= 0 || savingsTargetPercent <= 0) {
      return {
        'status': 'no_target',
        'message': 'Set a savings target to track your progress',
        'percentUsed': 0.0,
        'maxSpendingAllowed': totalIncome,
        'remainingBudget': totalIncome - totalExpenses,
      };
    }

    // Calculate max spending allowed to meet savings target
    // If savings target is 20%, max spending is 80% of income
    final maxSpendingPercent = 100 - savingsTargetPercent;
    final maxSpendingAllowed = (maxSpendingPercent / 100) * totalIncome;
    final remainingBudget = maxSpendingAllowed - totalExpenses;
    final percentUsed = (totalExpenses / maxSpendingAllowed) * 100;
    final savingsAmount = totalIncome - totalExpenses;
    final currentSavingsPercent = totalIncome > 0 ? (savingsAmount / totalIncome) * 100 : 0;

    SavingsAlertType alertType;
    String message;
    String title;

    if (totalExpenses >= maxSpendingAllowed) {
      // Exceeded limit
      alertType = SavingsAlertType.danger;
      title = '⚠️ Budget Exceeded!';
      message = 'You\'ve exceeded your spending limit by ₹${(totalExpenses - maxSpendingAllowed).toStringAsFixed(0)}. '
          'Your savings target of ${savingsTargetPercent.toStringAsFixed(0)}% is at risk!';
    } else if (percentUsed >= 90) {
      // About to exceed (90%+)
      alertType = SavingsAlertType.warning;
      title = '⚡ Almost at Limit!';
      message = 'Only ₹${remainingBudget.toStringAsFixed(0)} left before you exceed your spending limit. '
          'Be careful with your next expense!';
    } else if (percentUsed >= 75) {
      // Warning zone (75-90%)
      alertType = SavingsAlertType.warning;
      title = '📊 Spending Alert';
      message = 'You\'ve used ${percentUsed.toStringAsFixed(0)}% of your spending budget. '
          '₹${remainingBudget.toStringAsFixed(0)} remaining to meet your ${savingsTargetPercent.toStringAsFixed(0)}% savings goal.';
    } else if (percentUsed <= 50 && totalExpenses > 0) {
      // Great progress
      alertType = SavingsAlertType.celebration;
      title = '🎉 Excellent Progress!';
      message = 'You\'re doing great! At this rate, you\'ll save ${currentSavingsPercent.toStringAsFixed(0)}% this month - '
          'even better than your ${savingsTargetPercent.toStringAsFixed(0)}% target!';
    } else {
      // On track
      alertType = SavingsAlertType.success;
      title = '✅ On Track!';
      message = 'You\'re on track to meet your ${savingsTargetPercent.toStringAsFixed(0)}% savings target. '
          '₹${remainingBudget.toStringAsFixed(0)} spending budget remaining.';
    }

    return {
      'alertType': alertType,
      'title': title,
      'message': message,
      'percentUsed': percentUsed,
      'maxSpendingAllowed': maxSpendingAllowed,
      'remainingBudget': remainingBudget,
      'savingsAmount': savingsAmount,
      'currentSavingsPercent': currentSavingsPercent,
      'isOverBudget': totalExpenses >= maxSpendingAllowed,
    };
  }

  /// Show savings alert dialog
  static void showSavingsAlert(BuildContext context, Map<String, dynamic> status) {
    if (status['status'] == 'no_target') return;

    final alertType = status['alertType'] as SavingsAlertType;
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (alertType) {
      case SavingsAlertType.danger:
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red;
        icon = Icons.warning_rounded;
        break;
      case SavingsAlertType.warning:
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        icon = Icons.info_outline;
        break;
      case SavingsAlertType.success:
        backgroundColor = Colors.green.shade50;
        iconColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case SavingsAlertType.celebration:
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue;
        icon = Icons.celebration;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status['title'],
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status['message'],
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ((status['percentUsed'] as double) / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  status['percentUsed'] >= 100 
                      ? Colors.red 
                      : status['percentUsed'] >= 75 
                          ? Colors.orange 
                          : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Budget used: ${(status['percentUsed'] as double).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Show quick snackbar notification
  static void showQuickAlert(BuildContext context, Map<String, dynamic> status) {
    if (status['status'] == 'no_target') return;

    final alertType = status['alertType'] as SavingsAlertType;
    Color backgroundColor;

    switch (alertType) {
      case SavingsAlertType.danger:
        backgroundColor = Colors.red;
        break;
      case SavingsAlertType.warning:
        backgroundColor = Colors.orange;
        break;
      case SavingsAlertType.success:
        backgroundColor = AppColors.success;
        break;
      case SavingsAlertType.celebration:
        backgroundColor = Colors.blue;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${status['title']} ${status['message']}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () => showSavingsAlert(context, status),
        ),
      ),
    );
  }
}
