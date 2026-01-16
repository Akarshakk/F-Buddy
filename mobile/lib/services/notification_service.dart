import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    print('[Notifications] Service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[Notifications] Tapped: ${response.payload}');
    // You can navigate to specific screen based on payload
  }

  /// Show transaction detected notification
  Future<void> showTransactionDetected({
    required double amount,
    required String merchant,
    required String type,
    required bool autoSaved,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sms_transactions',
      'SMS Transactions',
      channelDescription: 'Notifications for SMS-detected transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6C63FF),
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = autoSaved
        ? '💰 Transaction Auto-Saved'
        : '📝 Review Transaction';

    final body = autoSaved
        ? '₹$amount ${type == 'expense' ? 'spent at' : 'received from'} $merchant'
        : '₹$amount ${type == 'expense' ? 'spent at' : 'received from'} $merchant - Tap to review';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: 'transaction_${DateTime.now().millisecondsSinceEpoch}',
    );

    print('[Notifications] Shown: $title - $body');
  }

  /// Show error notification
  Future<void> showError(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'sms_errors',
      'SMS Errors',
      channelDescription: 'Error notifications for SMS processing',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '❌ SMS Processing Error',
      message,
      details,
    );
  }

  /// Show bulk import notification
  Future<void> showBulkImportComplete(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'sms_bulk_import',
      'SMS Bulk Import',
      channelDescription: 'Bulk import completion notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '✅ Import Complete',
      'Successfully imported $count transactions from SMS',
      details,
    );
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // iOS handles permissions in initialization
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
