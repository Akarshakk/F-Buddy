import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class SmsService {
  static const platform = MethodChannel('com.finzo.app/sms');
  final NotificationService notificationService = NotificationService();

  // Comprehensive bank and payment app identifiers
  static const List<String> bankSenders = [
    // State Bank of India
    'SBIINB', 'SBIPAY', 'SBIUPI', 'SBICARD', 'SBIYONO', 'SBIBNK',
    // HDFC Bank
    'HDFCBK', 'HDFCUPI', 'HDFCBA', 'HDFCCC', 'HDFCSL',
    // ICICI Bank
    'ICICIB', 'ICICIUPI', 'ICICIC', 'ICICIP', 'ICICIM',
    // Axis Bank
    'AXISBK', 'AXISUPI', 'AXISBA', 'AXISCC', 'AXISMB',
    // Punjab National Bank
    'PNBSMS', 'PNBUPI', 'PNBBNK', 'PNBMSG',
    // Kotak Mahindra Bank
    'KOTAKBK', 'KOTAKM', 'KOTAK', 'KOTAKUPI',
    // Union Bank
    'UNIONBK', 'UNIONB', 'UBIBNK', 'UBIMSG', 'VVSBNK',
    // Yes Bank
    'YESBNK', 'YESBAN', 'YESBAK',
    // Bank of Baroda
    'BOBBNK', 'BARODA', 'BOB',
    // UPI Apps
    'PAYTM', 'PAYTMUPI', 'PAYTMB',
    'GPAY', 'GOOGLEPAY', 'GOOGLE',
    'PHONEPE', 'PHONPE', 'PHPE',
    'AMAZPAY', 'AMAZONPAY', 'AMAZON',
    'BHARPE', 'BHARAT', 'BHIM',
    'MOBIKWIK', 'MOBIKW', 'MBK',
    'FREECHARGE', 'FREECH',
    'AIRTEL', 'AIRTELPAY', 'AIRPAY',
    'JIO', 'JIOPAY', 'JIOMONEY',
    'WHATSAPP', 'WHATSAPPPAY', 'WAPAY',
    // Payment Gateways
    'JUSPAY', 'RAZORPAY', 'PAYU', 'CASHFREE', 'INSTAMOJO',
    // Common Prefixes
    'VK-', 'VM-', 'TX-', 'AD-', 'JM-', 'JD-', 'JK-', 'JZ-', 'VA-', 'CP-',
    // Generic Banking Keywords
    'BANK', 'UPI', 'NEFT', 'RTGS', 'IMPS', 'WALLET',
  ];

  // ============ ENHANCED REGEX PATTERNS (NO AI) ============

  /// Extract amount from SMS using multiple patterns
  String _extractAmount(String body) {
    // Pattern 1: Rs/INR/₹ followed by amount
    final patterns = [
      RegExp(r'(?:rs\.?|inr|₹)\s*:?\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
      RegExp(r'amount[:\s]+(?:rs\.?|inr|₹)?\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:debited|credited|paid|received)[:\s]+(?:rs\.?|inr|₹)?\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.replaceAll(',', '');
      }
    }
    return '0';
  }

  /// Extract account number (last 4 digits) - Enhanced patterns
  String _extractAccountNumber(String body) {
    final patterns = [
      // Standard patterns: A/C XX1234, Account XXXX1234
      RegExp(r'a/c[:\s]*[xX*]+(\d{4})', caseSensitive: false),
      RegExp(r'account[:\s]*[xX*]+(\d{4})', caseSensitive: false),
      RegExp(r'ac[:\s]*[xX*]+(\d{4})', caseSensitive: false),
      // Masked patterns: XXXX1234, ****1234
      RegExp(r'[xX*]{4,}(\d{4})'),
      // Ending patterns: ending 1234, ends with 1234
      RegExp(r'ending\s*(\d{4})', caseSensitive: false),
      RegExp(r'ends?\s*(?:with|in)?\s*(\d{4})', caseSensitive: false),
      // From/To account patterns
      RegExp(r'(?:from|to)\s*(?:a/c|ac|account)[:\s]*[xX*]*(\d{4})', caseSensitive: false),
      // Card patterns: card XX1234
      RegExp(r'card[:\s]*[xX*]+(\d{4})', caseSensitive: false),
      // Linked patterns: linked a/c 1234
      RegExp(r'linked\s*(?:a/c|ac|account)[:\s]*[xX*]*(\d{4})', caseSensitive: false),
      // Bank account number in format: 1234XXXX5678 (extract last 4)
      RegExp(r'\b\d{4}[xX*]+(\d{4})\b'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;  // Return just 4 digits for filtering
      }
    }
    return '';
  }

  /// Extract UPI ID from SMS
  String _extractUpiId(String body) {
    final pattern = RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z]+)', caseSensitive: false);
    final match = pattern.firstMatch(body);
    return match?.group(1) ?? '';
  }

  /// Extract reference/transaction number
  String _extractRefNumber(String body) {
    final patterns = [
      RegExp(r'ref[:\s#]*(\d{6,})', caseSensitive: false),
      RegExp(r'txn[:\s#]*(\d{6,})', caseSensitive: false),
      RegExp(r'transaction[:\s#]*(\d{6,})', caseSensitive: false),
      RegExp(r'reference[:\s#]*(\d{6,})', caseSensitive: false),
      RegExp(r'utr[:\s#]*(\d{6,})', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    }
    return '';
  }

  /// Extract merchant/recipient name
  String _extractMerchant(String body) {
    final patterns = [
      RegExp(r'(?:to|at|from|for)\s+([A-Za-z][A-Za-z0-9\s]{2,25})(?:\s+on|\s+via|\s+using|\s+ref|\.|\,|\s+upi)', caseSensitive: false),
      RegExp(r'(?:paid|sent|received)\s+(?:to|from)\s+([A-Za-z][A-Za-z0-9\s]{2,25})', caseSensitive: false),
      RegExp(r'vpa[:\s]+([a-zA-Z0-9._-]+@[a-zA-Z]+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        String merchant = match.group(1)!.trim();
        // Clean up merchant name
        merchant = merchant.replaceAll(RegExp(r'\s+'), ' ');
        if (merchant.length > 2 && merchant.length < 30) {
          return merchant;
        }
      }
    }
    return 'Unknown';
  }

  /// Determine if transaction is debit or credit
  String _getTransactionType(String body) {
    final debitPatterns = [
      RegExp(r'\b(debited|debit|spent|paid|payment|purchase|withdrawn|sent|transferred)\b', caseSensitive: false),
    ];
    
    final creditPatterns = [
      RegExp(r'\b(credited|credit|received|deposited|refund|cashback)\b', caseSensitive: false),
    ];
    
    for (final pattern in debitPatterns) {
      if (pattern.hasMatch(body)) return 'debit';
    }
    
    for (final pattern in creditPatterns) {
      if (pattern.hasMatch(body)) return 'credit';
    }
    
    return 'unknown';
  }

  /// Determine if it's UPI or Bank transfer
  String _getPaymentMode(String body, String sender) {
    final upiPatterns = [
      RegExp(r'\b(upi|gpay|phonepe|paytm|bhim|googlepay|amazon\s?pay|whatsapp\s?pay)\b', caseSensitive: false),
      RegExp(r'@[a-zA-Z]+\b'), // UPI ID pattern
    ];
    
    for (final pattern in upiPatterns) {
      if (pattern.hasMatch(body) || pattern.hasMatch(sender)) {
        return 'UPI';
      }
    }
    
    final bankPatterns = [
      RegExp(r'\b(neft|rtgs|imps|bank\s?transfer|wire\s?transfer)\b', caseSensitive: false),
    ];
    
    for (final pattern in bankPatterns) {
      if (pattern.hasMatch(body)) return 'Bank Transfer';
    }
    
    return 'Bank';
  }

  /// Get bank name from sender ID
  String _getBankName(String sender) {
    final upperSender = sender.toUpperCase();
    
    final bankMap = {
      'SBI': 'State Bank of India',
      'HDFC': 'HDFC Bank',
      'ICICI': 'ICICI Bank',
      'AXIS': 'Axis Bank',
      'KOTAK': 'Kotak Bank',
      'PNB': 'Punjab National Bank',
      'UNION': 'Union Bank',
      'BOB': 'Bank of Baroda',
      'BARODA': 'Bank of Baroda',
      'YES': 'Yes Bank',
      'IDFC': 'IDFC First Bank',
      'PAYTM': 'Paytm',
      'GPAY': 'Google Pay',
      'PHONEPE': 'PhonePe',
      'AMAZON': 'Amazon Pay',
      'JUSPAY': 'Juspay',
      'RAZORPAY': 'Razorpay',
      'BHIM': 'BHIM UPI',
      'MOBIKWIK': 'MobiKwik',
      'AIRTEL': 'Airtel Payments',
      'JIO': 'Jio',
      'VVSBNK': 'VVS Bank',
    };
    
    for (final entry in bankMap.entries) {
      if (upperSender.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return sender;
  }

  // ============ CORE METHODS ============

  /// Check if SMS is from bank/payment app
  bool _isPaymentSms(String sender) {
    if (sender.isEmpty) return false;
    final upperSender = sender.toUpperCase();
    
    for (final bank in bankSenders) {
      if (upperSender.contains(bank.toUpperCase())) return true;
    }
    
    // Format: XX-XXXXXX (e.g., JM-UNIONB)
    if (RegExp(r'^[A-Z]{2}-[A-Z]{5,}').hasMatch(upperSender)) return true;
    
    // 6+ uppercase letters
    if (RegExp(r'^[A-Z]{6,}$').hasMatch(upperSender)) return true;
    
    return false;
  }

  /// Check if SMS is a real transaction (not service message)
  bool _isRealTransaction(String body) {
    if (body.isEmpty) return false;
    
    // Must have transaction keyword
    final hasTransactionKeyword = RegExp(
      r'\b(debited|credited|spent|received|paid|txn|transaction|deposited|withdrawn|transfer|payment|sent|refund)\b',
      caseSensitive: false,
    ).hasMatch(body);
    
    // Must have amount
    final hasAmount = RegExp(
      r'(rs\.?|inr|₹)\s?:?\s?\d+',
      caseSensitive: false,
    ).hasMatch(body);
    
    // Exclude service messages
    final isServiceMessage = RegExp(
      r'\b(otp|verification|verify|welcome|activate|validity|expire|offer|plan|data\s?usage|download|click\s?here|call\s?us|support)\b',
      caseSensitive: false,
    ).hasMatch(body) && !hasTransactionKeyword;
    
    return hasTransactionKeyword && hasAmount && !isServiceMessage;
  }

  /// Parse SMS and extract all transaction details using REGEX only
  Map<String, dynamic> _parseTransaction(String body, String sender, String dateStr) {
    final amount = _extractAmount(body);
    final accountNumber = _extractAccountNumber(body);
    final upiId = _extractUpiId(body);
    final refNumber = _extractRefNumber(body);
    final merchant = _extractMerchant(body);
    final transactionType = _getTransactionType(body);
    final paymentMode = _getPaymentMode(body, sender);
    final bankName = _getBankName(sender);
    
    // Parse date
    final timestamp = int.tryParse(dateStr) ?? 0;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return {
      'amount': amount,
      'accountNumber': accountNumber,
      'upiId': upiId,
      'refNumber': refNumber,
      'merchant': merchant,
      'type': transactionType,
      'paymentMode': paymentMode,
      'bankName': bankName,
      'sender': sender,
      'date': formattedDate,
      'time': formattedTime,
      'timestamp': dateStr,
      'body': body,
    };
  }

  /// Request SMS permissions
  Future<bool> requestPermissions() async {
    try {
      // SMS not available on web
      if (kIsWeb) {
        print('[SMS Service] ⚠️  SMS not available on web platform');
        return false;
      }

      print('[SMS Service] Requesting SMS permission...');
      var status = await Permission.sms.request();
      print('[SMS Service] Permission result: $status');
      
      if (status.isGranted) {
        print('[SMS Service] ✓ Permission granted!');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('[SMS Service] ⚠ Permission permanently denied.');
        await openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      print('[SMS Service] Error: $e');
      return false;
    }
  }

  /// Poll for recent SMS
  Future<void> pollRecentSms() async {
    try {
      if (!await Permission.sms.isGranted) return;
      final List<dynamic>? results = await platform.invokeMethod('getRecentSms', {'seconds': 20});
      if (results == null || results.isEmpty) return;

      for (var msgObj in results) {
        final msg = Map<String, dynamic>.from(msgObj);
        final sender = msg['address']?.toString() ?? '';
        final body = msg['body']?.toString() ?? '';
        
        if (_isPaymentSms(sender) && _isRealTransaction(body)) {
          print('[SMS Service] 🔔 New transaction from: $sender');
          await _processSms(msg);
        }
      }
    } catch (e) {
      print('[SMS Service] Polling error: $e');
    }
  }

  Future<void> _processSms(Map<String, dynamic> msg) async {
    try {
      final sender = msg['address']?.toString() ?? '';
      final body = msg['body']?.toString() ?? '';
      final smsId = msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

      final response = await ApiService.post('/sms/parse', body: {
        'smsText': body,
        'sender': sender,
        'smsId': smsId,
      });

      if (response['success'] == true && response['isDuplicate'] != true) {
        final transaction = response['transaction'];
        print('[SMS Service] Transaction: ${transaction['merchant']}');
        
        if (response['needsReview'] == true) {
          await notificationService.showTransactionDetected(
            amount: (transaction['amount'] ?? 0).toDouble(),
            merchant: transaction['merchant'] ?? 'Unknown',
            type: transaction['type'] ?? 'expense',
            autoSaved: false,
          );
        } else {
          await ApiService.post('/sms/save', body: {'transaction': transaction, 'smsId': smsId});
          await notificationService.showTransactionDetected(
            amount: (transaction['amount'] ?? 0).toDouble(),
            merchant: transaction['merchant'] ?? 'Unknown',
            type: transaction['type'] ?? 'expense',
            autoSaved: true,
          );
        }
      }
    } catch (e) {
      print('[SMS Service] Error: $e');
    }
  }

  /// Fetch ALL transaction SMS with REGEX parsing
  Future<List<Map<String, dynamic>>> fetchAllSms({int daysBack = 30}) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) throw Exception('SMS permission not granted');

      print('[SMS Service] 📱 Fetching SMS from last $daysBack days...');
      final seconds = daysBack * 24 * 60 * 60;
      final List<dynamic>? results = await platform.invokeMethod('getRecentSms', {'seconds': seconds});
      
      print('[SMS Service] ✅ Total SMS: ${results?.length ?? 0}');
      if (results == null || results.isEmpty) return [];

      final transactions = <Map<String, dynamic>>[];
      
      for (var m in results) {
        final msg = Map<String, dynamic>.from(m);
        final sender = msg['address']?.toString() ?? '';
        final body = msg['body']?.toString() ?? '';
        final date = msg['date']?.toString() ?? '';
        
        if (_isPaymentSms(sender) && _isRealTransaction(body)) {
          final parsed = _parseTransaction(body, sender, date);
          transactions.add(parsed);
        }
      }

      // Sort by timestamp (newest first)
      transactions.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      
      print('[SMS Service] 🏦 Transactions found: ${transactions.length}');
      return transactions;
    } catch (e) {
      print('[SMS Service] ❌ Error: $e');
      return [];
    }
  }

  /// Fetch categorized transactions (UPI vs Bank) with account numbers
  Future<Map<String, dynamic>> fetchCategorizedTransactions({int daysBack = 30}) async {
    try {
      final allTransactions = await fetchAllSms(daysBack: daysBack);
      
      final upi = allTransactions.where((t) => t['paymentMode'] == 'UPI').toList();
      final bank = allTransactions.where((t) => t['paymentMode'] != 'UPI').toList();
      
      // Extract unique account numbers for filtering
      final Set<String> accountNumbers = {};
      for (final txn in allTransactions) {
        final accNo = txn['accountNumber']?.toString() ?? '';
        if (accNo.isNotEmpty && accNo.length == 4) {
          accountNumbers.add(accNo);
        }
      }
      
      print('[SMS Service] 📊 UPI: ${upi.length}, Bank: ${bank.length}, Accounts: ${accountNumbers.length}');
      
      return {
        'upi': upi,
        'bankTransfers': bank,
        'total': allTransactions.length,
        'accountNumbers': accountNumbers.toList()..sort(),
      };
    } catch (e) {
      print('[SMS Service] ❌ Error: $e');
      return {'upi': [], 'bankTransfers': [], 'total': 0, 'accountNumbers': []};
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
    // SMS not available on web
    if (kIsWeb) {
      return false;
    }
    return await Permission.sms.isGranted;
  }

  Future<List<Map<String, dynamic>>> scanExistingSms({int daysBack = 7}) async {
    return await fetchAllSms(daysBack: daysBack);
  }
}


