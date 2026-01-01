import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../services/api_service.dart';

class DebtProvider with ChangeNotifier {
  List<Debt> _debts = [];
  DebtSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  List<Debt> get debts => _debts;
  DebtSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get active debts (not settled)
  List<Debt> get activeDebts => _debts.where((d) => !d.isSettled).toList();

  // Get debts where they owe me
  List<Debt> get theyOweMeDebts =>
      activeDebts.where((d) => d.type == DebtType.theyOweMe).toList();

  // Get debts where I owe
  List<Debt> get iOweDebts =>
      activeDebts.where((d) => d.type == DebtType.iOwe).toList();

  // Get debts due today
  List<Debt> get debtsDueToday =>
      activeDebts.where((d) => d.isDueToday).toList();

  // Get overdue debts
  List<Debt> get overdueDebts => activeDebts.where((d) => d.isOverdue).toList();

  // Fetch all debts
  Future<void> fetchDebts({String? type, bool? settled}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (settled != null) queryParams['settled'] = settled.toString();

      final response = await ApiService.get(
        '/debts',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _debts = data.map((json) => Debt.fromJson(json)).toList();

        if (response['summary'] != null) {
          _summary = DebtSummary.fromJson(response['summary']);
        }
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch debts';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new debt
  Future<bool> addDebt({
    required DebtType type,
    required double amount,
    required String personName,
    String description = '',
    required DateTime dueDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/debts',
        body: {
          'type': type == DebtType.theyOweMe ? 'they_owe_me' : 'i_owe',
          'amount': amount,
          'personName': personName,
          'description': description,
          'dueDate': dueDate.toIso8601String(),
        },
      );

      if (response['success'] == true) {
        final newDebt = Debt.fromJson(response['data']);
        _debts.insert(0, newDebt);
        await fetchDebts(); // Refresh to get updated summary
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add debt';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Settle a debt
  Future<bool> settleDebt(String debtId) async {
    try {
      final response = await ApiService.put('/debts/$debtId/settle');

      if (response['success'] == true) {
        final index = _debts.indexWhere((d) => d.id == debtId);
        if (index != -1) {
          _debts[index] = _debts[index].copyWith(
            isSettled: true,
            settledDate: DateTime.now(),
          );
        }
        await fetchDebts(); // Refresh to get updated summary
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to settle debt';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    }
    return false;
  }

  // Delete a debt
  Future<bool> deleteDebt(String debtId) async {
    try {
      final response = await ApiService.delete('/debts/$debtId');

      if (response['success'] == true) {
        _debts.removeWhere((d) => d.id == debtId);
        await fetchDebts(); // Refresh to get updated summary
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete debt';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    }
    return false;
  }

  // Get debts due today from API
  Future<List<Debt>> fetchDebtsDueToday() async {
    try {
      final response = await ApiService.get('/debts/due-today');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => Debt.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching debts due today: $e');
    }
    return [];
  }

  // Mark reminder as sent
  Future<void> markReminderSent(String debtId) async {
    try {
      await ApiService.put('/debts/$debtId/reminder-sent');
      final index = _debts.indexWhere((d) => d.id == debtId);
      if (index != -1) {
        _debts[index] = _debts[index].copyWith(reminderSent: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking reminder as sent: $e');
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
