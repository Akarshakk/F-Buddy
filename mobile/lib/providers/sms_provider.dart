import 'package:flutter/foundation.dart';
import '../services/sms_service.dart';
import '../services/notification_service.dart';

class SmsProvider with ChangeNotifier {
  final SmsService _smsService = SmsService();
  final NotificationService _notificationService = NotificationService();

  bool _isEnabled = false;
  bool _isInitializing = false;
  int _smsTransactionCount = 0;
  List<Map<String, dynamic>> _pendingReviews = [];

  bool get isEnabled => _isEnabled;
  bool get isInitializing => _isInitializing;
  int get smsTransactionCount => _smsTransactionCount;
  List<Map<String, dynamic>> get pendingReviews => _pendingReviews;

  /// Initialize SMS tracking on app start
  Future<void> initializeOnStartup() async {
    try {
      // Check if user has enabled SMS tracking before
      final hasPermission = await _smsService.hasPermissions();
      
      if (hasPermission) {
        _isEnabled = true;
        notifyListeners();
        
        // Initialize services
        await _notificationService.initialize();
        await _smsService.initializeSmsListener();
        
        // Load transaction count
        await loadSmsTransactionCount();
        
        print('[SMS Provider] ✅ Initialized on startup');
      }
    } catch (e) {
      print('[SMS Provider] ❌ Initialization error: $e');
    }
  }

  /// Enable SMS tracking
  Future<bool> enableSmsTracking() async {
    try {
      _isInitializing = true;
      notifyListeners();

      // Request notification permissions first
      await _notificationService.requestPermissions();
      
      // Request SMS permissions
      final granted = await _smsService.requestPermissions();
      
      if (granted) {
        // Initialize notification service
        await _notificationService.initialize();
        
        // Initialize SMS listener
        final initialized = await _smsService.initializeSmsListener();
        
        if (initialized) {
          _isEnabled = true;
          _isInitializing = false;
          notifyListeners();
          
          print('[SMS Provider] ✅ SMS tracking enabled');
          return true;
        }
      }
      
      _isInitializing = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('[SMS Provider] ❌ Error enabling: $e');
      _isInitializing = false;
      notifyListeners();
      return false;
    }
  }

  /// Disable SMS tracking
  void disableSmsTracking() {
    _isEnabled = false;
    notifyListeners();
    print('[SMS Provider] ⏸️  SMS tracking disabled');
  }

  /// Load SMS transaction count from backend
  Future<void> loadSmsTransactionCount() async {
    try {
      final data = await _smsService.getSmsTransactions();
      _smsTransactionCount = data['total'] ?? 0;
      notifyListeners();
      print('[SMS Provider] 📊 Loaded $smsTransactionCount SMS transactions');
    } catch (e) {
      print('[SMS Provider] ❌ Error loading count: $e');
    }
  }

  /// Scan existing SMS
  Future<List<Map<String, dynamic>>> scanExistingSms({int daysBack = 30}) async {
    try {
      print('[SMS Provider] 🔍 Scanning last $daysBack days...');
      
      final transactions = await _smsService.scanExistingSms(daysBack: daysBack);
      
      print('[SMS Provider] ✅ Found ${transactions.length} transactions');
      
      return transactions;
    } catch (e) {
      print('[SMS Provider] ❌ Scan error: $e');
      return [];
    }
  }

  /// Import transactions from scan
  Future<bool> importTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      int imported = 0;
      int failed = 0;

      for (var transaction in transactions) {
        try {
          final response = await _smsService.apiService.post(
            '/sms/save',
            {
              'transaction': transaction,
              'smsId': transaction['smsId'] ?? DateTime.now().toString(),
            },
          );

          if (response['success'] == true) {
            imported++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
          print('[SMS Provider] ❌ Import failed for transaction: $e');
        }
      }

      print('[SMS Provider] ✅ Imported: $imported, Failed: $failed');

      // Show notification
      if (imported > 0) {
        await _notificationService.showBulkImportComplete(imported);
      }

      // Reload count
      await loadSmsTransactionCount();

      return imported > 0;
    } catch (e) {
      print('[SMS Provider] ❌ Import error: $e');
      return false;
    }
  }

  /// Add transaction for manual review
  void addPendingReview(Map<String, dynamic> transaction) {
    _pendingReviews.add(transaction);
    notifyListeners();
  }

  /// Remove reviewed transaction
  void removePendingReview(int index) {
    if (index >= 0 && index < _pendingReviews.length) {
      _pendingReviews.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all pending reviews
  void clearPendingReviews() {
    _pendingReviews.clear();
    notifyListeners();
  }
}
