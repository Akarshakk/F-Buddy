class ApiConstants {
  // ====================================================================
  // NETWORK CONFIGURATION FOR SMS TESTING
  // ====================================================================
  // 
  // IMPORTANT: Update this when testing on real Android device!
  // 
  // OPTION 1: Development (Default)
  // - Use 'localhost' for web/iOS simulator
  // - Use '10.0.2.2' for Android emulator
  // 
  // OPTION 2: Real Android Device (Same Wi-Fi)
  // - Find your computer's IP: `ipconfig getifaddr en0` (macOS)
  // - Replace 'localhost' below with your IP (e.g., '192.168.1.100')
  // 
  // OPTION 3: USB Reverse Proxy
  // - Run: `adb reverse tcp:5001 tcp:5001`
  // - Use 'localhost' (Android will forward to computer)
  // ====================================================================
  
  // 🔧 CHANGE THIS FOR REAL DEVICE TESTING:
  // Example: static const String _serverIp = '192.168.1.100';
  static const String _serverIp = 'localhost';  // Using USB reverse proxy (adb reverse)
  static const String _serverPort = '5001';
  
  // Automatically detect platform and use correct URL
  static String get baseUrl {
    // For web and iOS simulator
    if (identical(0, 0.0)) {
      return 'http://$_serverIp:$_serverPort/api';
    }
    
    // For Android emulator
    if (_serverIp == 'localhost') {
      return 'http://10.0.2.2:$_serverPort/api';
    }
    
    // For real Android device (using computer's IP)
    return 'http://$_serverIp:$_serverPort/api';
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
