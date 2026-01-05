import 'package:flutter/material.dart';
import '../config/theme.dart';

enum SavingsAlertType {
  warning,
  danger,
  success,
  celebration,
}

class SavingsAlertService {
  static const double warningBuffer = 5.0;

  static Map<String, dynamic> calculateSavingsStatus({
    required double totalIncome,
    required double totalExpenses,
    required double savingsTargetPercent,
  }) {
    if (totalIncome <= 0 || savingsTargetPercent <= 0) {
      return {
        'status': 'no_target',
        'message': 'Set a savings target to track your progress',
        'currentSavingsPercent': 0.0,
        'savingsTargetPercent': savingsTargetPercent,
        'savingsAmount': 0.0,
        'remainingBudget': totalIncome - totalExpenses,
      };
    }

    final savingsAmount = totalIncome - totalExpenses;
    final currentSavingsPercent = (savingsAmount / totalIncome) * 100;
    
    final maxSpendingPercent = 100 - savingsTargetPercent;
    final maxSpendingAllowed = (maxSpendingPercent / 100) * totalIncome;
    final remainingBudget = maxSpendingAllowed - totalExpenses;
    
    final warningThreshold = savingsTargetPercent + warningBuffer;
    final dangerThreshold = savingsTargetPercent;

    SavingsAlertType alertType;
    String message;
    String title;

    if (currentSavingsPercent < dangerThreshold) {
      alertType = SavingsAlertType.danger;
      title = '🚨 Savings Limit Reached!';
      final shortfall = savingsTargetPercent - currentSavingsPercent;
      message = 'Your current savings rate is ${currentSavingsPercent.toStringAsFixed(1)}%, '
          'which is ${shortfall.toStringAsFixed(1)}% below your ${savingsTargetPercent.toStringAsFixed(0)}% target. '
          'Consider reducing expenses to protect your savings!';
    } else if (currentSavingsPercent < warningThreshold) {
      alertType = SavingsAlertType.warning;
      title = '⚠️ Savings Limit Approaching!';
      final buffer = currentSavingsPercent - savingsTargetPercent;
      message = 'Your savings rate is ${currentSavingsPercent.toStringAsFixed(1)}%, '
          'only ${buffer.toStringAsFixed(1)}% above your ${savingsTargetPercent.toStringAsFixed(0)}% target. '
          'You have ₹${remainingBudget.toStringAsFixed(0)} left before reaching your limit.';
    } else if (currentSavingsPercent >= warningThreshold + 10) {
      alertType = SavingsAlertType.celebration;
      title = '🎉 Excellent Savings!';
      message = 'Amazing! You\'re saving ${currentSavingsPercent.toStringAsFixed(1)}% of your income - '
          'that\'s ${(currentSavingsPercent - savingsTargetPercent).toStringAsFixed(1)}% more than your target! '
          'Keep up the great work!';
    } else {
      alertType = SavingsAlertType.success;
      title = '✅ On Track!';
      message = 'Great job! You\'re saving ${currentSavingsPercent.toStringAsFixed(1)}% of your income, '
          'comfortably above your ${savingsTargetPercent.toStringAsFixed(0)}% target. '
          '₹${remainingBudget.toStringAsFixed(0)} spending budget remaining.';
    }

    return {
      'alertType': alertType,
      'title': title,
      'message': message,
      'currentSavingsPercent': currentSavingsPercent,
      'savingsTargetPercent': savingsTargetPercent,
      'warningThreshold': warningThreshold,
      'savingsAmount': savingsAmount,
      'maxSpendingAllowed': maxSpendingAllowed,
      'remainingBudget': remainingBudget,
      'isOverBudget': currentSavingsPercent < dangerThreshold,
      'isApproachingLimit': currentSavingsPercent >= dangerThreshold && currentSavingsPercent < warningThreshold,
    };
  }

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Savings: ${(status['currentSavingsPercent'] as double).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Target: ${(status['savingsTargetPercent'] as double).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.6 * 
                            ((status['currentSavingsPercent'] as double) / 100).clamp(0.0, 1.0),
                        color: (status['currentSavingsPercent'] as double) < (status['savingsTargetPercent'] as double)
                            ? Colors.red
                            : (status['currentSavingsPercent'] as double) < (status['warningThreshold'] as double)
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.6 * 
                          ((status['savingsTargetPercent'] as double) / 100).clamp(0.0, 1.0) - 2,
                      child: Container(
                        height: 14,
                        width: 4,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    Text(
                      '▲ Target',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
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
