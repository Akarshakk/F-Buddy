import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class BankStatementScreen extends StatefulWidget {
  const BankStatementScreen({Key? key}) : super(key: key);

  @override
  State<BankStatementScreen> createState() => _BankStatementScreenState();
}

class _BankStatementScreenState extends State<BankStatementScreen> {
  bool _isLoading = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _summary;
  String? _errorMessage;
  String _filterType = 'all'; // all, debit, credit

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (image != null) {
        await _uploadAndProcess(File(image.path));
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        await _uploadAndProcess(File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadAndProcess(File file) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _transactions = [];
      _summary = null;
    });

    try {
      // Read file and convert to base64
      final bytes = await file.readAsBytes();
      final base64File = base64Encode(bytes);
      final fileName = file.path.split('/').last;
      
      // Upload to backend
      final response = await ApiService.uploadFile(
        '/statement/upload',
        file,
        fieldName: 'statement',
      );

      if (response['success'] == true) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(response['transactions'] ?? []);
          _summary = response['summary'];
          _isProcessing = false;
        });

        if (_transactions.isEmpty) {
          _showError('No transactions found in the statement. Try a clearer image.');
        }
      } else {
        _showError(response['message'] ?? 'Failed to process statement');
      }
    } catch (e) {
      _showError('Error processing statement: $e');
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filterType == 'all') return _transactions;
    return _transactions.where((t) => t['type'] == _filterType).toList();
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upload Bank Statement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to upload your statement',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture statement with camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.green.shade700),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select image from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.file_present, color: Colors.orange.shade700),
                ),
                title: const Text('Choose File'),
                subtitle: const Text('Select PDF or image file'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Statement'),
        actions: [
          if (_transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _showUploadOptions,
              tooltip: 'Upload new statement',
            ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingView()
          : _transactions.isEmpty
              ? _buildEmptyView()
              : _buildTransactionsView(),
      floatingActionButton: _transactions.isEmpty && !_isProcessing
          ? null
          : FloatingActionButton.extended(
              onPressed: _showUploadOptions,
              icon: const Icon(Icons.add),
              label: const Text('Upload'),
            ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Processing Statement...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Extracting transactions using OCR',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Bank Statement',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload your bank statement (PDF or image) and we\'ll extract all transactions automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showUploadOptions,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Statement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For best results, use a clear, well-lit image of your statement',
                      style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsView() {
    final filtered = _filteredTransactions;
    
    return Column(
      children: [
        // Summary Card
        if (_summary != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      'Total',
                      '${_summary!['totalTransactions']}',
                      Icons.receipt_long,
                    ),
                    _buildSummaryItem(
                      'Debit',
                      '₹${_formatAmount(_summary!['totalDebit'])}',
                      Icons.arrow_upward,
                      color: Colors.red.shade200,
                    ),
                    _buildSummaryItem(
                      'Credit',
                      '₹${_formatAmount(_summary!['totalCredit'])}',
                      Icons.arrow_downward,
                      color: Colors.green.shade200,
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All', 'all', _transactions.length),
              const SizedBox(width: 8),
              _buildFilterChip('Debit', 'debit', _summary?['debitCount'] ?? 0),
              const SizedBox(width: 8),
              _buildFilterChip('Credit', 'credit', _summary?['creditCount'] ?? 0),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Transactions List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No ${_filterType} transactions',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final txn = filtered[index];
                    return _buildTransactionCard(txn);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String type, int count) {
    final isSelected = _filterType == type;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = type;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> txn) {
    final isDebit = txn['type'] == 'debit';
    final isCredit = txn['type'] == 'credit';
    final paymentMode = txn['paymentMode'] ?? 'Bank Transfer';
    
    // Get icon based on payment mode
    IconData getModeIcon() {
      if (paymentMode.contains('UPI') || paymentMode.contains('Pay')) return Icons.phone_android;
      if (paymentMode.contains('Credit Card')) return Icons.credit_card;
      if (paymentMode.contains('Debit Card') || paymentMode.contains('ATM')) return Icons.credit_card_outlined;
      if (paymentMode.contains('NEFT') || paymentMode.contains('RTGS') || paymentMode.contains('Net Banking')) return Icons.account_balance;
      return Icons.swap_horiz;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isDebit
              ? Colors.red.shade100
              : isCredit
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
          child: Icon(
            isDebit
                ? Icons.arrow_upward
                : isCredit
                    ? Icons.arrow_downward
                    : Icons.swap_horiz,
            color: isDebit
                ? Colors.red.shade700
                : isCredit
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '₹${_formatAmount(txn['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: isDebit
                      ? Colors.red.shade700
                      : isCredit
                          ? Colors.green.shade700
                          : Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDebit ? Colors.red.shade50 : isCredit ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isDebit ? 'DEBIT' : isCredit ? 'CREDIT' : 'TXN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDebit ? Colors.red.shade700 : isCredit ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              txn['merchant'] ?? txn['description'] ?? 'Transaction',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  txn['date'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 10),
                Icon(getModeIcon(), size: 12, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    paymentMode,
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                _buildDetailRow('Amount', '₹${_formatAmount(txn['amount'])}'),
                _buildDetailRow('Type', isDebit ? 'Debit (Money Out)' : isCredit ? 'Credit (Money In)' : 'Unknown'),
                _buildDetailRow('Payment Mode', paymentMode),
                _buildDetailRow('Merchant', txn['merchant'] ?? 'Unknown'),
                _buildDetailRow('Date', txn['date'] ?? ''),
                if (txn['upiId'] != null)
                  _buildDetailRow('UPI ID', txn['upiId']),
                if (txn['refNumber'] != null)
                  _buildDetailRow('Ref No.', txn['refNumber']),
                if (txn['cardLast4'] != null)
                  _buildDetailRow('Card', 'XXXX ${txn['cardLast4']}'),
                if (txn['balance'] != null)
                  _buildDetailRow('Balance', '₹${_formatAmount(txn['balance'])}'),
                const SizedBox(height: 12),
                const Text(
                  'Raw Text:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    txn['rawText'] ?? '',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    if (num >= 10000000) {
      return '${(num / 10000000).toStringAsFixed(2)} Cr';
    } else if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(2)} L';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(2);
  }
}
