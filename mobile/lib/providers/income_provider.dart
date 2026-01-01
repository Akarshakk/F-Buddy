import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/income.dart';
import '../services/api_service.dart';

class IncomeProvider extends ChangeNotifier {
  List<Income> _incomes = [];
  Income? _currentMonthIncome;
  bool _isLoading = false;
  String? _errorMessage;
  double _totalIncome = 0;

  List<Income> get incomes => _incomes;
  Income? get currentMonthIncome => _currentMonthIncome;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get totalIncome => _totalIncome;

  // Fetch all incomes
  Future<void> fetchIncomes({int? month, int? year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, String>? queryParams;
      if (month != null || year != null) {
        queryParams = {};
        if (month != null) queryParams['month'] = month.toString();
        if (year != null) queryParams['year'] = year.toString();
      }

      final response = await ApiService.get(
        ApiConstants.income,
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> incomeList = response['data']['incomes'] ?? [];
        _incomes = incomeList.map((i) => Income.fromJson(i)).toList();
        _totalIncome = (response['totalIncome'] ?? 0).toDouble();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch incomes';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch current month income
  Future<void> fetchCurrentMonthIncome() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConstants.currentIncome);

      if (response['success'] == true) {
        final List<dynamic> incomeList = response['data']['incomes'] ?? [];
        if (incomeList.isNotEmpty) {
          _currentMonthIncome = Income.fromJson(incomeList.first);
        }
        _totalIncome = (response['totalIncome'] ?? 0).toDouble();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch current income';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add income (pocket money)
  Future<bool> addIncome({
    required double amount,
    String? description,
    String? source,
    int? month,
    int? year,
    DateTime? date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final response = await ApiService.post(
        ApiConstants.income,
        body: {
          'amount': amount,
          'description': description ?? 'Monthly Income',
          'source': source ?? 'pocket_money',
          'month': month ?? now.month,
          'year': year ?? now.year,
          'date': (date ?? now).toIso8601String(),
        },
      );

      if (response['success'] == true) {
        final newIncome = Income.fromJson(response['data']['income']);
        _incomes.insert(0, newIncome);
        _currentMonthIncome = newIncome;
        _totalIncome += amount;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to add income';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update income
  Future<bool> updateIncome({
    required String id,
    double? amount,
    String? description,
    String? source,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (amount != null) body['amount'] = amount;
      if (description != null) body['description'] = description;
      if (source != null) body['source'] = source;

      final response = await ApiService.put(
        '${ApiConstants.income}/$id',
        body: body,
      );

      if (response['success'] == true) {
        await fetchIncomes();
        await fetchCurrentMonthIncome();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update income';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Delete income
  Future<bool> deleteIncome(String id) async {
    try {
      final response = await ApiService.delete('${ApiConstants.income}/$id');

      if (response['success'] == true) {
        _incomes.removeWhere((i) => i.id == id);
        if (_currentMonthIncome?.id == id) {
          _currentMonthIncome = null;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to delete income';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Clear data
  void clear() {
    _incomes = [];
    _currentMonthIncome = null;
    _totalIncome = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
