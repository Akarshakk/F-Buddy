import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../services/notification_service.dart';
import 'dart:convert';

class SmsService {
  final Telephony telephony = Telephony.instance;
  final ApiService apiService = ApiService();
  final NotificationService notificationService = NotificationService();

  // Bank and payment app identifiers
  static const List<String> BANK_SENDERS = [
    'SBIINB',
    'HDFCBK',
    'ICICIB',
    'AXISBK',
    'PNBSMS',
    'KOTAKBK',
    'PAYTM',
    'GPAY',
    'PHONEPE',
    'AMAZPAY',
    'BHARPE',
    'SBIPAY',
    'YESBNK',
    'CITIBK',
    'SCBANK',
    'HSBC',
    'IDBIBNK'
  ];

  /// Initialize SMS listener
  Future<bool> initializeSmsListener() async {
    try {
      // Request permissions
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

      if (permissionsGranted != null && permissionsGranted) {
        // Start listening for incoming SMS
        telephony.listenIncomingSms(
          onNewMessage: onSmsReceived,
          onBackgroundMessage: backgroundMessageHandler,
          listenInBackground: true,
        );

        print('[SMS Service] Listener initialized successfully');
        return true;
      } else {
        print('[SMS Service] Permissions not granted');
        return false;
      }
    } catch (e) {
      print('[SMS Service] Error initializing: $e');
      return false;
    }
  }

  /// Request SMS permissions
  Future<bool> requestPermissions() async {
    try {
      var status = await Permission.sms.request();
      if (status.isGranted) {
        print('[SMS Service] SMS permission granted');
        return true;
      } else {
        print('[SMS Service] SMS permission denied');
        return false;
      }
    } catch (e) {
      print('[SMS Service] Error requesting permission: $e');
      return false;
    }
  }

  /// Handle incoming SMS
  Future<void> onSmsReceived(SmsMessage message) async {
    try {
      final sender = message.address ?? '';
      final body = message.body ?? '';

      print('[SMS Service] ========================================');
      print('[SMS Service] 📱 New SMS Received');
      print('[SMS Service] From: $sender');
      print('[SMS Service] Body: ${body.substring(0, body.length > 100 ? 100 : body.length)}...');

      // Check if SMS is from bank/payment app
      if (_isPaymentSms(sender)) {
        print('[SMS Service] ✅ Payment SMS Detected!');
        print('[SMS Service] Processing transaction...');
        await _processSms(message);
      } else {
        print('[SMS Service] ⏭️  Skipped - Not a payment SMS');
      }
      print('[SMS Service] ========================================');
    } catch (e) {
      print('[SMS Service] ❌ Error handling SMS: $e');
    }
  }

  /// Background message handler (static method required)
  static Future<void> backgroundMessageHandler(SmsMessage message) async {
    print('[SMS Service] Background SMS received');
    // Process in background
    final service = SmsService();
    await service.onSmsReceived(message);
  }

  /// Check if SMS is from bank/payment app
  bool _isPaymentSms(String sender) {
    final upperSender = sender.toUpperCase();
    return BANK_SENDERS.any((bank) => upperSender.contains(bank));
  }

  /// Process and parse SMS
  Future<void> _processSms(SmsMessage message) async {
    try {
      final sender = message.address ?? '';
      final body = message.body ?? '';
      final smsId = message.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Send to backend for parsing
      final response = await apiService.post(
        '/sms/parse',
        {
          'smsText': body,
          'sender': sender,
          'smsId': smsId,
        },
      );

      if (response['success'] == true) {
        if (response['isDuplicate'] == true) {
          print('[SMS Service] Duplicate transaction detected');
          return;
        }

        final transaction = response['transaction'];
        final needsReview = response['needsReview'] ?? false;

        if (needsReview) {
          // Show notification for review
          await _showReviewNotification(transaction, smsId);
        } else {
          // Auto-save high confidence transactions
          await _autoSaveTransaction(transaction, smsId);
        }
      }
    } catch (e) {
      print('[SMS Service] Error processing SMS: $e');
    }
  }

  /// Auto-save transaction with high confidence
  Future<void> _autoSaveTransaction(Map<String, dynamic> transaction, String smsId) async {
    try {
      print('[SMS Service] 💾 Auto-saving transaction (high confidence)...');
      
      final response = await apiService.post(
        '/sms/save',
        {
          'transaction': transaction,
          'smsId': smsId,
        },
      );

      if (response['success'] == true) {
        print('[SMS Service] ✅ Transaction auto-saved: ₹${transaction['amount']}');
        
        // Show success notification
        await notificationService.showTransactionDetected(
          amount: (transaction['amount'] ?? 0).toDouble(),
          merchant: transaction['merchant'] ?? 'Unknown',
          type: transaction['type'] ?? 'expense',
          autoSaved: true,
        );
      }
    } catch (e) {
      print('[SMS Service] ❌ Error auto-saving: $e');
      await notificationService.showError('Failed to save transaction');
    }
  }

  /// Show notification for manual review
  Future<void> _showReviewNotification(Map<String, dynamic> transaction, String smsId) async {
    print('[SMS Service] 📝 Review needed for: ₹${transaction['amount']} - ${transaction['merchant']}');
    
    // Show notification asking user to review
    await notificationService.showTransactionDetected(
      amount: (transaction['amount'] ?? 0).toDouble(),
      merchant: transaction['merchant'] ?? 'Unknown',
      type: transaction['type'] ?? 'expense',
      autoSaved: false,
    );
    
    // You can also store this in local database for review later
  }

  /// Show success notification
  Future<void> _showSuccessNotification(Map<String, dynamic> transaction) async {
    print('[SMS Service] ✅ Transaction saved: ₹${transaction['amount']}');
    
    await notificationService.showTransactionDetected(
      amount: (transaction['amount'] ?? 0).toDouble(),
      merchant: transaction['merchant'] ?? 'Unknown',
      type: transaction['type'] ?? 'expense',
      autoSaved: true,
    );
  }

  /// Scan existing SMS for transactions
  Future<List<Map<String, dynamic>>> scanExistingSms({int daysBack = 7}) async {
    try {
      final permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      if (permissionsGranted != true) {
        throw Exception('SMS permissions not granted');
      }

      // Calculate date range
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));

      // Get SMS from inbox
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThanOrEqualTo(startDate.millisecondsSinceEpoch.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Filter payment-related SMS
      final paymentMessages = messages.where((msg) {
        final sender = msg.address ?? '';
        return _isPaymentSms(sender);
      }).toList();

      print('[SMS Service] Found ${paymentMessages.length} payment SMS in last $daysBack days');

      // Parse in bulk
      final smsArray = paymentMessages.map((msg) {
        return {
          'text': msg.body ?? '',
          'sender': msg.address ?? '',
          'id': msg.id?.toString() ?? '',
          'timestamp': msg.date?.toString() ?? '',
        };
      }).toList();

      if (smsArray.isEmpty) {
        return [];
      }

      // Send to backend for bulk parsing
      final response = await apiService.post(
        '/sms/parse-bulk',
        {'smsArray': smsArray},
      );

      if (response['success'] == true) {
        final transactions = List<Map<String, dynamic>>.from(
          response['transactions'] ?? []
        );
        print('[SMS Service] Parsed ${transactions.length} transactions');
        return transactions;
      }

      return [];
    } catch (e) {
      print('[SMS Service] Error scanning SMS: $e');
      return [];
    }
  }

  /// Get SMS-created transactions from backend
  Future<Map<String, dynamic>> getSmsTransactions() async {
    try {
      final response = await apiService.get('/sms/transactions');
      if (response['success'] == true) {
        return {
          'expenses': response['expenses'] ?? [],
          'incomes': response['incomes'] ?? [],
          'total': response['total'] ?? 0,
        };
      }
      return {'expenses': [], 'incomes': [], 'total': 0};
    } catch (e) {
      print('[SMS Service] Error getting SMS transactions: $e');
      return {'expenses': [], 'incomes': [], 'total': 0};
    }
  }

  /// Check if SMS permissions are granted
  Future<bool> hasPermissions() async {
    try {
      var status = await Permission.sms.status;
      return status.isGranted;
    } catch (e) {
      print('[SMS Service] Error checking permissions: $e');
      return false;
    }
  }
}
