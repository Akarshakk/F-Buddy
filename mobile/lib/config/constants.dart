class ApiConstants {
  // Change this to your server's IP when testing on physical device
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: localhost
  // For physical device use your computer's local IP
  
  // Automatically detect platform and use correct URL
  static String get baseUrl {
    // For web
    if (identical(0, 0.0)) {
      return 'http://localhost:5001/api';
    }
    // For Android emulator
    return 'http://10.0.2.2:5001/api';
  }
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendOtp = '/auth/resend-otp';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/update';
  static const String updatePassword = '/auth/password';
  
  // Income endpoints
  static const String income = '/income';
  static const String currentIncome = '/income/current';
  
  // Expense endpoints
  static const String expenses = '/expenses';
  static const String latestExpenses = '/expenses/latest';
  static const String checkDuplicate = '/expenses/check-duplicate';
  
  // Analytics endpoints
  static const String categoryAnalytics = '/analytics/category';
  static const String summary = '/analytics/summary';
  static const String balanceChart = '/analytics/balance-chart';
  static const String dashboard = '/analytics/dashboard';
  
  // Category endpoints
  static const String categories = '/categories';
  
  // Bill scanning endpoints
  static const String billScan = '/bill/scan';
  static const String billScanBase64 = '/bill/scan-base64';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String user = 'user_data';
  static const String isFirstTime = 'is_first_time';
}
