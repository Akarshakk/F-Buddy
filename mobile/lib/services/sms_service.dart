import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class SmsService {
  static const platform = MethodChannel('com.fbuddy.f_buddy/sms');
  final NotificationService notificationService = NotificationService();

  // Bank and payment app identifiers
  static const List<String> bankSenders = [
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
    'IDBIBNK',
    'INDBNK',
    'BOIIND',
    'CANBNK',
    'UNIONBK',
    'MAHABK',
    'PNBSMS',
    'SBIUPI',
    'HDFCUPI',
    'ICICIUPI',
    'AXISUPI',
    'PAYTMUPI',
    'GOOGLEPAY',
    'WHATSAPP',
    'AMAZONPAY',
    'MOBIKWIK',
    'FREECHARGE',
    'AIRTEL',
    'JIO',
    'VODAFONE',
    'BSNL',
    'TEST', // For testing
    '+91',  // For personal numbers testing
    'VK-',  // Common bank prefix
    'VM-',  // Common bank prefix
    'TX-',  // Transaction prefix
    'AD-',  // Advertisement/bank prefix
  ];

  /// Request SMS permissions with detailed status - ALWAYS ASK
  Future<bool> requestPermissions() async {
    try {
      print('[SMS Service] Requesting SMS permission...');
      
      // Always request permission (don't check if already granted)
      var status = await Permission.sms.request();
      print('[SMS Service] Permission result: $status');
      
      if (status.isGranted) {
        print('[SMS Service] ✓ Permission granted!');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('[SMS Service] ⚠ Permission permanently denied. Opening app settings...');
        await openAppSettings();
        return false;
      } else {
        print('[SMS Service] ✗ Permission denied by user');
        return false;
      }
    } catch (e) {
      print('[SMS Service] Error requesting permission: $e');
      return false;
    }
  }

  /// Poll for recent SMS (last 20 seconds) via Native Channel
  Future<void> pollRecentSms() async {
    try {
      if (!await Permission.sms.isGranted) return;

      // Invoke native method
      final List<dynamic>? results = await platform.invokeMethod('getRecentSms', {'seconds': 20});
      
      if (results == null || results.isEmpty) return;

      for (var msgObj in results) {
        // Convert to Map
        final msg = Map<String, dynamic>.from(msgObj);
        final sender = msg['address']?.toString() ?? '';
        
        if (_isPaymentSms(sender)) {
           // We found a payment SMS!
           print('[SMS Service] 🔔 Polling found new SMS from: $sender');
           await _processSms(msg);
        }
      }
    } catch (e) {
        print('[SMS Service] Polling error: $e');
    }
  }

  /// Check if SMS is from bank/payment app or is a test message
  bool _isPaymentSms(String sender) {
    final upperSender = sender.toUpperCase();
    if (upperSender.contains('TEST')) return true;
    return bankSenders.any((bank) => upperSender.contains(bank));
  }

  /// Process and parse SMS
  Future<void> _processSms(Map<String, dynamic> msg) async {
    try {
      final sender = msg['address']?.toString() ?? '';
      final body = msg['body']?.toString() ?? '';
      // Native ID is string
      final smsId = msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Send to backend for parsing
      final response = await ApiService.post(
        '/sms/parse',
        body: {
          'smsText': body,
          'sender': sender,
          'smsId': smsId,
        },
      );

      if (response['success'] == true) {
        if (response['isDuplicate'] == true) {
          return;
        }

        final transaction = response['transaction'];
        final needsReview = response['needsReview'] ?? false;
        
        print('[SMS Service] New Transaction Found: ${transaction['merchant']}');

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

  Future<void> _autoSaveTransaction(Map<String, dynamic> transaction, String smsId) async {
    try {
      print('[SMS Service] 💾 Auto-saving transaction (high confidence)...');
      
      final response = await ApiService.post(
        '/sms/save',
        body: {
          'transaction': transaction,
          'smsId': smsId,
        },
      );

      if (response['success'] == true) {
        print('[SMS Service] ✅ Transaction auto-saved: ₹${transaction['amount']}');
        await notificationService.showTransactionDetected(
          amount: (transaction['amount'] ?? 0).toDouble(),
          merchant: transaction['merchant'] ?? 'Unknown',
          type: transaction['type'] ?? 'expense',
          autoSaved: true,
        );
      }
    } catch (e) {
      print('[SMS Service] ❌ Error auto-saving: $e');
    }
  }

  Future<void> _showReviewNotification(Map<String, dynamic> transaction, String smsId) async {
    print('[SMS Service] 📝 Review needed for: ₹${transaction['amount']}');
    await notificationService.showTransactionDetected(
      amount: (transaction['amount'] ?? 0).toDouble(),
      merchant: transaction['merchant'] ?? 'Unknown',
      type: transaction['type'] ?? 'expense',
      autoSaved: false,
    );
  }

  /// Fetch ALL SMS messages with sender numbers for debugging
  Future<List<Map<String, dynamic>>> fetchAllSms({int daysBack = 30}) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('[SMS Service] ⚠ SMS permission not granted. Cannot fetch messages.');
        throw Exception('SMS permissions not granted. Please enable SMS permission in Settings → Apps → F-Buddy → Permissions');
      }

      print('[SMS Service] 📱 Fetching ALL SMS from last $daysBack days...');
      
      // Calculate seconds
      final seconds = daysBack * 24 * 60 * 60;
      
      final List<dynamic>? results = await platform.invokeMethod('getRecentSms', {'seconds': seconds});
      
      print('[SMS Service] ✅ Total SMS found: ${results?.length ?? 0}');
      
      if (results == null || results.isEmpty) {
        print('[SMS Service] ⚠ No SMS found in inbox');
        return [];
      }

      // Convert all messages to list with sender info
      final allMessages = results.map((m) {
        final msg = Map<String, dynamic>.from(m);
        return {
          'sender': msg['address']?.toString() ?? 'Unknown',
          'body': msg['body']?.toString() ?? '',
          'date': msg['date']?.toString() ?? '',
          'id': msg['id']?.toString() ?? '',
        };
      }).toList();

      // Print first 20 messages for debugging
      print('[SMS Service] 📋 First 20 SMS messages:');
      for (var i = 0; i < (allMessages.length > 20 ? 20 : allMessages.length); i++) {
        final msg = allMessages[i];
        final body = msg['body'] ?? '';
        final preview = body.length > 60 ? '${body.substring(0, 60)}...' : body;
        print('  ${i + 1}. From: ${msg['sender']}');
        print('     Message: $preview');
        print('     Date: ${msg['date']}');
        print('');
      }

      return allMessages;
    } catch (e) {
      print('[SMS Service] ❌ Error fetching SMS: $e');
      return [];
    }
  }

  /// Scan existing SMS for transactions
  Future<List<Map<String, dynamic>>> scanExistingSms({int daysBack = 7}) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('[SMS Service] ⚠ SMS permission not granted. Cannot scan messages.');
        throw Exception('SMS permissions not granted. Please enable SMS permission in Settings → Apps → F-Buddy → Permissions');
      }

      print('[SMS Service] Scanning inbox via Native for last $daysBack days...');
      
      // Calculate seconds
      final seconds = daysBack * 24 * 60 * 60;
      
      final List<dynamic>? results = await platform.invokeMethod('getRecentSms', {'seconds': seconds});
      
      print('[SMS Service] Total SMS found: ${results?.length ?? 0}');
      
      if (results == null || results.isEmpty) {
        print('[SMS Service] No SMS found in inbox');
        return [];
      }

      // Log first few senders for debugging
      if (results.isNotEmpty) {
        print('[SMS Service] Sample senders:');
        for (var i = 0; i < (results.length > 5 ? 5 : results.length); i++) {
          final msg = Map<String, dynamic>.from(results[i]);
          print('  - ${msg['address']}: ${msg['body']?.toString().substring(0, 50)}...');
        }
      }

      final paymentMessages = results.map((m) => Map<String, dynamic>.from(m)).where((msg) {
        final sender = msg['address']?.toString() ?? '';
        final isPayment = _isPaymentSms(sender);
        if (isPayment) {
          print('[SMS Service] ✓ Payment SMS from: $sender');
        }
        return isPayment;
      }).toList();

      print('[SMS Service] Found ${paymentMessages.length} payment SMS out of ${results.length} total');

      if (paymentMessages.isEmpty) {
        print('[SMS Service] No payment SMS found. Bank senders list: ${bankSenders.join(", ")}');
        return [];
      }

      // Parse in bulk
      final smsArray = paymentMessages.map((msg) {
        return {
          'text': msg['body']?.toString() ?? '',
          'sender': msg['address']?.toString() ?? '',
          'id': msg['id']?.toString() ?? '',
          'timestamp': msg['date']?.toString() ?? '', 
        };
      }).toList();

      // Send to backend for bulk parsing
      final response = await ApiService.post(
        '/sms/parse-bulk',
        body: {'smsArray': smsArray},
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

  Future<Map<String, dynamic>> getSmsTransactions() async {
    try {
      final response = await ApiService.get('/sms/transactions');
      if (response['success'] == true) {
        return {
          'expenses': response['expenses'] ?? [],
          'incomes': response['incomes'] ?? [],
          'total': response['total'] ?? 0,
        };
      }
      return {'expenses': [], 'incomes': [], 'total': 0};
    } catch (e) {
      return {'expenses': [], 'incomes': [], 'total': 0};
    }
  }

  Future<bool> hasPermissions() async {
    return await Permission.sms.isGranted;
  }
}
