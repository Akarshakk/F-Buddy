import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../config/theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final SmsService _smsService = SmsService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _upiTransactions = [];
  List<Map<String, dynamic>> _bankTransfers = [];
  List<String> _accountNumbers = [];
  String? _selectedAccount;  // null means "All Accounts"

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categorized = await _smsService.fetchCategorizedTransactions(daysBack: 30);
      
      setState(() {
        _upiTransactions = List<Map<String, dynamic>>.from(categorized['upi']);
        _bankTransfers = List<Map<String, dynamic>>.from(categorized['bankTransfers']);
        _accountNumbers = List<String>.from(categorized['accountNumbers'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Filter transactions by selected account
  List<Map<String, dynamic>> _filterByAccount(List<Map<String, dynamic>> transactions) {
    if (_selectedAccount == null) return transactions;
    return transactions.where((t) => t['accountNumber'] == _selectedAccount).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUpi = _filterByAccount(_upiTransactions);
    final filteredBank = _filterByAccount(_bankTransfers);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: const Icon(Icons.phone_android),
                text: 'UPI (${filteredUpi.length})',
              ),
              Tab(
                icon: const Icon(Icons.account_balance),
                text: 'Bank (${filteredBank.length})',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Account Filter Dropdown
                  if (_accountNumbers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Text('Filter by A/C:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedAccount,
                                  isExpanded: true,
                                  hint: const Text('All Accounts'),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Accounts'),
                                    ),
                                    ..._accountNumbers.map((acc) => DropdownMenuItem<String?>(
                                      value: acc,
                                      child: Text('XX$acc'),
                                    )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAccount = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (_selectedAccount != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedAccount = null;
                                });
                              },
                              tooltip: 'Clear filter',
                            ),
                        ],
                      ),
                    ),
                  // Transaction Lists
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTransactionList(filteredUpi, isUPI: true),
                        _buildTransactionList(filteredBank, isUPI: false),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions, {required bool isUPI}) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUPI ? Icons.phone_android : Icons.account_balance,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isUPI ? 'UPI' : 'Bank'} transactions found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final isDebit = txn['type'] == 'debit';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isDebit ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '₹${txn['amount']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUPI ? Colors.purple.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUPI ? 'UPI' : 'Bank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUPI ? Colors.purple.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  txn['merchant'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${txn['date']} at ${txn['time']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (txn['accountNumber'] != null && txn['accountNumber'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'XX${txn['accountNumber']}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Bank/App', txn['bankName'] ?? txn['sender'], Icons.business),
                    if (txn['accountNumber'] != null && txn['accountNumber'].toString().isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildDetailRow('Account', 'XX${txn['accountNumber']}', Icons.credit_card),
                    ],
                    const Divider(height: 20),
                    _buildDetailRow('Amount', '₹${txn['amount']}', Icons.currency_rupee),
                    const Divider(height: 20),
                    _buildDetailRow('Type', isDebit ? 'Debit' : 'Credit', 
                      isDebit ? Icons.remove_circle : Icons.add_circle),
                    const Divider(height: 20),
                    _buildDetailRow('Date & Time', '${txn['date']} at ${txn['time']}', Icons.access_time),
                    const Divider(height: 20),
                    _buildDetailRow('Merchant', txn['merchant'], Icons.store),
                    if (txn['upiId'] != null && txn['upiId'].toString().isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildDetailRow('UPI ID', txn['upiId'], Icons.alternate_email),
                    ],
                    if (txn['refNumber'] != null && txn['refNumber'].toString().isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildDetailRow('Ref No.', txn['refNumber'], Icons.tag),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.message, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Full Message:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        txn['body'],
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
