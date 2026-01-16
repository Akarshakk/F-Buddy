import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../config/theme.dart';

class SmsSettingsScreen extends StatefulWidget {
  const SmsSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends State<SmsSettingsScreen> {
  final SmsService _smsService = SmsService();
  bool _isEnabled = false;
  bool _isLoading = true;
  bool _isScanning = false;
  int _smsTransactionCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadSmsTransactions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _smsService.hasPermissions();
    setState(() {
      _isEnabled = hasPermission;
      _isLoading = false;
    });
  }

  Future<void> _loadSmsTransactions() async {
    try {
      final data = await _smsService.getSmsTransactions();
      setState(() {
        _smsTransactionCount = data['total'] ?? 0;
      });
    } catch (e) {
      print('Error loading SMS transactions: $e');
    }
  }

  Future<void> _toggleSmsTracking(bool value) async {
    if (value) {
      // Enable SMS tracking
      final granted = await _smsService.requestPermissions();
      if (granted) {
        await _smsService.initializeSmsListener();
        setState(() {
          _isEnabled = true;
        });
        _showSnackBar('SMS tracking enabled', isError: false);
      } else {
        _showSnackBar('SMS permission denied', isError: true);
      }
    } else {
      // Disable SMS tracking
      setState(() {
        _isEnabled = false;
      });
      _showSnackBar('SMS tracking disabled', isError: false);
    }
  }

  Future<void> _scanExistingSms() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final transactions = await _smsService.scanExistingSms(daysBack: 30);
      
      setState(() {
        _isScanning = false;
      });

      if (transactions.isEmpty) {
        _showSnackBar('No payment SMS found in last 30 days', isError: false);
      } else {
        // Show dialog with found transactions
        _showTransactionsDialog(transactions);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showSnackBar('Error scanning SMS: $e', isError: true);
    }
  }

  void _showTransactionsDialog(List<Map<String, dynamic>> transactions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Found ${transactions.length} Transactions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final txn = transactions[index];
              return ListTile(
                leading: Icon(
                  txn['type'] == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: txn['type'] == 'expense' ? Colors.red : Colors.green,
                ),
                title: Text('₹${txn['amount']}'),
                subtitle: Text(txn['merchant'] ?? 'Unknown'),
                trailing: Text(txn['category'] ?? ''),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importTransactions(transactions);
            },
            child: const Text('Import All'),
          ),
        ],
      ),
    );
  }

  Future<void> _importTransactions(List<Map<String, dynamic>> transactions) async {
    // TODO: Implement batch import
    _showSnackBar('Importing ${transactions.length} transactions...', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Auto-Tracking'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.message,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'SMS Auto-Tracking',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Automatically track expenses from payment SMS',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable SMS Tracking'),
                          subtitle: Text(
                            _isEnabled
                                ? 'Automatically tracking payment SMS'
                                : 'Enable to start tracking',
                          ),
                          value: _isEnabled,
                          onChanged: _toggleSmsTracking,
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SMS Transactions',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_smsTransactionCount',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Auto-tracked transactions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Scan Existing SMS
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.scanner, size: 32),
                    title: const Text('Scan Existing SMS'),
                    subtitle: const Text('Import transactions from past 30 days'),
                    trailing: _isScanning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    onTap: _isScanning ? null : _scanExistingSms,
                  ),
                ),

                const SizedBox(height: 24),

                // How it works
                const Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHowItWorksItem(
                  icon: Icons.message,
                  title: 'SMS Detection',
                  description: 'Automatically detects payment SMS from banks and UPI apps',
                ),
                _buildHowItWorksItem(
                  icon: Icons.analytics,
                  title: 'AI Categorization',
                  description: 'Uses AI to automatically categorize your expenses',
                ),
                _buildHowItWorksItem(
                  icon: Icons.check_circle,
                  title: 'Auto-Save',
                  description: 'High-confidence transactions are saved automatically',
                ),
                _buildHowItWorksItem(
                  icon: Icons.edit_notifications,
                  title: 'Review',
                  description: 'Get notified for transactions that need your review',
                ),

                const SizedBox(height: 24),

                // Privacy Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy First',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Only transaction details are stored. Full SMS content is never saved.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
