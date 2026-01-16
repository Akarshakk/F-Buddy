import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class CategoryData {
  final String category;
  final double amount;
  final int count;
  final double percentage;

  CategoryData({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0,
    );
  }

  // Get emoji icon for category
  String get categoryIcon {
    const icons = {
      'clothes': '👕',
      'drinks': '🍺',
      'education': '📚',
      'food': '🍔',
      'fuel': '⛽',
      'fun': '🎮',
      'health': '💊',
      'hotel': '🏨',
      'personal': '👤',
      'pets': '🐾',
      'restaurants': '🍽️',
      'tips': '💰',
      'transport': '🚗',
      'others': '📦',
    };
    return icons[category.toLowerCase()] ?? '📦';
  }

  String get categoryDisplayName {
    return category.substring(0, 1).toUpperCase() + category.substring(1);
  }
}

class ChartDataPoint {
  final String date;
  final String dayName;
  final double income;
  final double expense;
  final double dailyBalance;
  final double cumulativeBalance;

  ChartDataPoint({
    required this.date,
    required this.dayName,
    required this.income,
    required this.expense,
    required this.dailyBalance,
    required this.cumulativeBalance,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'] ?? '',
      dayName: json['dayName'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      dailyBalance: (json['dailyBalance'] ?? 0).toDouble(),
      cumulativeBalance: (json['cumulativeBalance'] ?? 0).toDouble(),
    );
  }
}

class DashboardData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double savingsRate;
  final String month;
  final List<CategoryData> categoryBreakdown;
  final List<Expense> latestExpenses;
  final bool hasChartData;

  DashboardData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.savingsRate,
    required this.month,
    required this.categoryBreakdown,
    required this.latestExpenses,
    required this.hasChartData,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    try {
      final overview = json['overview'] ?? {};
      final categoryList = json['categoryBreakdown'] as List? ?? [];
      final expenseList = json['latestExpenses'] as List? ?? [];

      // Debug logging
      print('[DashboardData] Parsing overview: $overview');
      print('[DashboardData] Month field type: ${overview['month'].runtimeType}');
      print('[DashboardData] Month value: ${overview['month']}');

      return DashboardData(
        totalIncome: (overview['totalIncome'] ?? 0).toDouble(),
        totalExpense: (overview['totalExpense'] ?? 0).toDouble(),
        balance: (overview['balance'] ?? 0).toDouble(),
        savingsRate: double.tryParse(overview['savingsRate']?.toString() ?? '0') ?? 0,
        month: overview['month']?.toString() ?? '',
        categoryBreakdown: categoryList.map((c) => CategoryData.fromJson(c)).toList(),
        latestExpenses: expenseList.map((e) => Expense.fromJson(e)).toList(),
        hasChartData: json['hasChartData'] ?? false,
      );
    } catch (e, stackTrace) {
      print('[DashboardData] Error parsing: $e');
      print('[DashboardData] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class AnalyticsProvider extends ChangeNotifier {
  List<CategoryData> _categoryData = [];
  List<ChartDataPoint> _balanceChartData = [];
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasEnoughDataForChart = false;
  int _daysRemainingForChart = 7;
  String? _selectedWeekStart;
  String? _weekStartDate;
  String? _weekEndDate;
  bool _isCurrentWeek = true;

  List<CategoryData> get categoryData => _categoryData;
  List<ChartDataPoint> get balanceChartData => _balanceChartData;
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasEnoughDataForChart => _hasEnoughDataForChart;
  int get daysRemainingForChart => _daysRemainingForChart;
  String? get selectedWeekStart => _selectedWeekStart;
  String? get weekStartDate => _weekStartDate;
  String? get weekEndDate => _weekEndDate;
  bool get isCurrentWeek => _isCurrentWeek;

  // Fetch category breakdown for pie chart
  Future<void> fetchCategoryData({String? period, int? month, int? year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, String>? queryParams;
      if (period != null || month != null || year != null) {
        queryParams = {};
        if (period != null) queryParams['period'] = period;
        if (month != null) queryParams['month'] = month.toString();
        if (year != null) queryParams['year'] = year.toString();
      }

      final response = await ApiService.get(
        ApiConstants.categoryAnalytics,
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> dataList = response['data']['categoryData'] ?? [];
        _categoryData = dataList.map((c) => CategoryData.fromJson(c)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch category data';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch balance chart data (7 days) with optional week selection
  Future<void> fetchBalanceChartData({String? weekStart}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedWeekStart = weekStart;
    notifyListeners();

    try {
      Map<String, String>? queryParams;
      if (weekStart != null) {
        queryParams = {'weekStart': weekStart};
      }
      
      final response = await ApiService.get(
        ApiConstants.balanceChart,
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        _hasEnoughDataForChart = response['hasEnoughData'] ?? false;
        _daysRemainingForChart = response['daysRemaining'] ?? 0;
        
        // Extract week info
        final weekInfo = response['weekInfo'];
        if (weekInfo != null) {
          _weekStartDate = weekInfo['startDate'];
          _weekEndDate = weekInfo['endDate'];
          _isCurrentWeek = weekInfo['isCurrentWeek'] ?? true;
        }

        // Always populate chart data if available
        final List<dynamic> dataList = response['data']['chartData'] ?? [];
        _balanceChartData = dataList.map((c) => ChartDataPoint.fromJson(c)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch chart data';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch dashboard data
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('[Analytics] Fetching dashboard data...');
      final response = await ApiService.get(ApiConstants.dashboard);

      print('[Analytics] Dashboard response: ${response['success']}');
      if (response['success'] == true) {
        _dashboardData = DashboardData.fromJson(response['data']);
        print('[Analytics] Dashboard data loaded:');
        print('  - Total Income: ${_dashboardData?.totalIncome}');
        print('  - Total Expense: ${_dashboardData?.totalExpense}');
        print('  - Balance: ${_dashboardData?.balance}');
        
        // Only update chart availability if balance chart hasn't been fetched yet
        if (_balanceChartData.isEmpty) {
          _hasEnoughDataForChart = _dashboardData?.hasChartData ?? false;
        }
        _categoryData = _dashboardData?.categoryBreakdown ?? [];
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch dashboard data';
        print('[Analytics] Error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('[Analytics] Exception: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear data
  void clear() {
    _categoryData = [];
    _balanceChartData = [];
    _dashboardData = null;
    _hasEnoughDataForChart = false;
    _daysRemainingForChart = 7;
    _selectedWeekStart = null;
    _weekStartDate = null;
    _weekEndDate = null;
    _isCurrentWeek = true;
    _errorMessage = null;
    notifyListeners();
  }
}
