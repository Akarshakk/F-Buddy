import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../providers/expense_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/income_provider.dart';
import '../../services/bill_scan_service.dart';
import '../../services/savings_alert_service.dart';
import 'add_debt_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isScanning = false;
  Uint8List? _scannedBillImageBytes;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _scanBill(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      setState(() => _isScanning = true);

      final Uint8List imageBytes = await image.readAsBytes();
      
      if (imageBytes.isEmpty) {
        if (mounted) {
          _showSnackBar('Failed to read image. Please try again.', isError: true);
          setState(() => _isScanning = false);
        }
        return;
      }
      
      setState(() => _scannedBillImageBytes = imageBytes);

      final result = await BillScanService.scanBillFromBytes(imageBytes);

      if (!mounted) return;

      if (result['success'] == true) {
        final BillScanResult scanResult = result['data'];
        
        setState(() {
          if (scanResult.amount != null) {
            _amountController.text = scanResult.amount!.toStringAsFixed(2);
          }
          if (scanResult.category != null) {
            _selectedCategory = scanResult.category;
          }
          if (scanResult.merchant != null && _merchantController.text.isEmpty) {
            _merchantController.text = scanResult.merchant!;
          }
          if (scanResult.merchant != null && _descriptionController.text.isEmpty) {
            _descriptionController.text = 'Purchase from ${scanResult.merchant!}';
          }
        });

        _showSnackBar(
          'Bill scanned! Amount: ₹${scanResult.amount?.toStringAsFixed(2) ?? "Not found"}, '
          'Category: ${scanResult.category ?? "Others"}',
          isSuccess: true,
          duration: 3,
        );
      } else {
        _showSnackBar(result['message'] ?? 'Failed to scan bill', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false, int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FinzoTypography.bodyMedium(color: Colors.white)),
        backgroundColor: isSuccess ? FinzoColors.success : isError ? FinzoColors.error : FinzoColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinzoRadius.sm)),
        margin: const EdgeInsets.all(FinzoSpacing.md),
        duration: Duration(seconds: duration),
      ),
    );
  }

  void _showBillScanOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinzoTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FinzoRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FinzoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FinzoTheme.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: FinzoSpacing.lg),
              Text(
                'Scan Bill',
                style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context)),
              ),
              const SizedBox(height: FinzoSpacing.sm),
              Text(
                'Take a photo or choose from gallery to auto-fill expense details',
                textAlign: TextAlign.center,
                style: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
              ),
              const SizedBox(height: FinzoSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildScanOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: FinzoColors.brandPrimary,
                      onTap: () {
                        Navigator.pop(context);
                        _scanBill(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: FinzoSpacing.md),
                  Expanded(
                    child: _buildScanOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: FinzoColors.brandSecondary,
                      onTap: () {
                        Navigator.pop(context);
                        _scanBill(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FinzoSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: FinzoSpacing.sm),
            Text(label, style: FinzoTypography.labelLarge(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsAlertDialog(BuildContext context, Map<String, dynamic> status) {
    final alertType = status['alertType'] as SavingsAlertType;
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (alertType) {
      case SavingsAlertType.danger:
        backgroundColor = FinzoColors.error.withOpacity(0.1);
        iconColor = FinzoColors.error;
        icon = Icons.warning_rounded;
        break;
      case SavingsAlertType.warning:
        backgroundColor = FinzoColors.warning.withOpacity(0.1);
        iconColor = FinzoColors.warning;
        icon = Icons.info_outline_rounded;
        break;
      case SavingsAlertType.success:
        backgroundColor = FinzoColors.success.withOpacity(0.1);
        iconColor = FinzoColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SavingsAlertType.celebration:
        backgroundColor = FinzoColors.info.withOpacity(0.1);
        iconColor = FinzoColors.info;
        icon = Icons.celebration_rounded;
        break;
    }

    return AlertDialog(
      backgroundColor: FinzoTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinzoRadius.xl)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(FinzoSpacing.sm),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(FinzoRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: FinzoSpacing.md),
          Expanded(
            child: Text(
              status['title'],
              style: FinzoTypography.titleMedium(color: iconColor),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status['message'],
            style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
          ),
          const SizedBox(height: FinzoSpacing.md),
          Container(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(FinzoRadius.md),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Savings:', style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context))),
                    Text(
                      '${(status['currentSavingsPercent'] as double).toStringAsFixed(1)}%',
                      style: FinzoTypography.labelMedium(color: iconColor),
                    ),
                  ],
                ),
                const SizedBox(height: FinzoSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target:', style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context))),
                    Text(
                      '${(status['savingsTargetPercent'] as double).toStringAsFixed(0)}%',
                      style: FinzoTypography.labelMedium(color: FinzoTheme.textPrimary(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(FinzoRadius.sm),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: FinzoTypography.labelMedium(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FinzoColors.brandPrimary,
              onPrimary: Colors.white,
              surface: FinzoTheme.surface(context),
              onSurface: FinzoTheme.textPrimary(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<bool> _showDuplicateConfirmationDialog(Map<String, dynamic> duplicateResult) async {
    final duplicates = duplicateResult['duplicates'] as List? ?? [];
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: FinzoTheme.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinzoRadius.lg)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(FinzoSpacing.sm),
                decoration: BoxDecoration(
                  color: FinzoColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(FinzoRadius.sm),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: FinzoColors.warning, size: 24),
              ),
              const SizedBox(width: FinzoSpacing.md),
              Expanded(
                child: Text(
                  'Duplicate Expense Detected',
                  style: FinzoTypography.titleMedium(color: FinzoTheme.textPrimary(context)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'It seems like this is a duplicate or false expense entry.',
                style: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
              ),
              const SizedBox(height: FinzoSpacing.md),
              if (duplicates.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(FinzoSpacing.md),
                  decoration: BoxDecoration(
                    color: FinzoColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(FinzoRadius.md),
                    border: Border.all(color: FinzoColors.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Similar expense found:',
                        style: FinzoTypography.labelMedium(color: FinzoColors.warning),
                      ),
                      const SizedBox(height: FinzoSpacing.sm),
                      ...duplicates.take(2).map((dup) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ₹${dup['amount']} - ${dup['category']}${dup['merchant'] != null && dup['merchant'].isNotEmpty ? ' (${dup['merchant']})' : ''}',
                          style: FinzoTypography.bodySmall(color: FinzoTheme.textPrimary(context)),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: FinzoSpacing.md),
              ],
              Text(
                'Do you still want to add this expense?',
                style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Skip', style: FinzoTypography.labelMedium(color: FinzoTheme.textSecondary(context))),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [FinzoColors.brandPrimary, FinzoColors.brandSecondary]),
                borderRadius: BorderRadius.circular(FinzoRadius.sm),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes, Continue', style: FinzoTypography.labelMedium(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category', isError: true);
      return;
    }

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    final amount = double.parse(_amountController.text);
    final category = _selectedCategory!;
    final description = _descriptionController.text.trim();
    final merchant = _merchantController.text.trim();

    final duplicateResult = await expenseProvider.checkDuplicate(
      amount: amount,
      category: category,
      date: _selectedDate,
      merchant: merchant,
    );

    if (!mounted) return;

    if (duplicateResult['isDuplicate'] == true) {
      final shouldContinue = await _showDuplicateConfirmationDialog(duplicateResult);
      if (!shouldContinue) return;
    }

    final success = await expenseProvider.addExpense(
      amount: amount,
      category: category,
      description: description,
      merchant: merchant,
      date: _selectedDate,
    );

    if (!mounted) return;

    if (success) {
      await expenseProvider.fetchExpenses();
      await analyticsProvider.fetchDashboardData();
      await analyticsProvider.fetchBalanceChartData();

      final user = authProvider.user;
      if (user != null && user.savingsTarget > 0) {
        final totalIncome = incomeProvider.totalIncome;
        final totalExpenses = expenseProvider.totalExpense;
        
        final status = SavingsAlertService.calculateSavingsStatus(
          totalIncome: totalIncome,
          totalExpenses: totalExpenses,
          savingsTargetPercent: user.savingsTarget,
        );

        if (status['alertType'] == SavingsAlertType.danger ||
            status['alertType'] == SavingsAlertType.warning) {
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => _buildSavingsAlertDialog(ctx, status),
            );
          }
        } else {
          _showSnackBar('Expense added successfully!', isSuccess: true);
        }
      } else {
        _showSnackBar('Expense added successfully!', isSuccess: true);
      }
      
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(expenseProvider.errorMessage ?? 'Failed to add expense', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        title: Text(
          'Add Expense',
          style: FinzoTypography.titleMedium(color: FinzoTheme.textPrimary(context)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(FinzoSpacing.xs),
            decoration: BoxDecoration(
              color: FinzoTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(FinzoRadius.sm),
            ),
            child: Icon(Icons.arrow_back_ios_rounded, color: FinzoTheme.textPrimary(context), size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scan Bill Button
                  _buildActionCard(
                    icon: Icons.document_scanner_rounded,
                    title: '📷 Scan Bill',
                    subtitle: 'Auto-fill amount & category from bill photo',
                    gradientColors: [FinzoColors.brandPrimary, FinzoColors.brandSecondary],
                    onTap: _isScanning ? null : _showBillScanOptions,
                  ),
                  const SizedBox(height: FinzoSpacing.md),

                  // Debt/IOU Button
                  _buildActionCard(
                    icon: Icons.swap_horiz_rounded,
                    title: '💰 Track Debt / IOU',
                    subtitle: 'Track money you owe or are owed',
                    gradientColors: [FinzoColors.brandPrimary, FinzoColors.brandSecondary],
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDebtScreen()));
                    },
                  ),
                  const SizedBox(height: FinzoSpacing.lg),

                  // Scanned Bill Preview
                  if (_scannedBillImageBytes != null && _scannedBillImageBytes!.isNotEmpty) ...[
                    _buildScannedBillPreview(),
                    const SizedBox(height: FinzoSpacing.lg),
                  ],

                  // Amount Input
                  _buildAmountInput(),
                  const SizedBox(height: FinzoSpacing.xl),

                  // Category Selection
                  Text(
                    'Select Category',
                    style: FinzoTypography.titleSmall(color: FinzoTheme.textPrimary(context)),
                  ),
                  const SizedBox(height: FinzoSpacing.md),
                  _buildCategoryGrid(),
                  const SizedBox(height: FinzoSpacing.xl),

                  // Date Selection
                  _buildDateSelector(),
                  const SizedBox(height: FinzoSpacing.md),

                  // Description
                  _buildInputCard(
                    controller: _descriptionController,
                    hint: 'Add a note (optional)',
                    icon: Icons.note_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: FinzoSpacing.md),

                  // Merchant Name
                  _buildInputCard(
                    controller: _merchantController,
                    hint: 'Merchant/Store name (optional)',
                    icon: Icons.store_outlined,
                  ),
                  const SizedBox(height: FinzoSpacing.xl),

                  // Add Button
                  _buildAddButton(),
                  const SizedBox(height: FinzoSpacing.xl),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isScanning) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(FinzoSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(FinzoRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: FinzoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: FinzoTypography.titleSmall(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FinzoTypography.bodySmall(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedBillPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        border: Border.all(color: FinzoColors.success, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FinzoRadius.lg - 2),
        child: Stack(
          children: [
            Image.memory(
              _scannedBillImageBytes!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  color: FinzoTheme.surfaceVariant(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_rounded, color: FinzoTheme.textSecondary(context), size: 40),
                      const SizedBox(height: 4),
                      Text('Image preview unavailable', style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context))),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _scannedBillImageBytes = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: FinzoColors.error, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: FinzoColors.success,
                  borderRadius: BorderRadius.circular(FinzoRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Scanned', style: FinzoTypography.labelSmall(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(FinzoSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FinzoColors.brandPrimary, FinzoColors.brandSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FinzoRadius.xl),
        boxShadow: [
          BoxShadow(
            color: FinzoColors.brandPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Enter Amount', style: FinzoTypography.bodyMedium(color: Colors.white70)),
          const SizedBox(height: FinzoSpacing.sm),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: FinzoTypography.displayLarge(color: Colors.white),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: FinzoTypography.displayLarge(color: Colors.white),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              hintText: '0',
              hintStyle: FinzoTypography.displayLarge(color: Colors.white38),
              errorStyle: const TextStyle(color: Colors.white70),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an amount';
              if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid amount';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: FinzoSpacing.sm,
        mainAxisSpacing: FinzoSpacing.sm,
      ),
      itemCount: Category.all.length,
      itemBuilder: (context, index) {
        final category = Category.all[index];
        final isSelected = _selectedCategory == category.name;

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? category.color.withOpacity(0.15) : FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(FinzoRadius.md),
              border: Border.all(
                color: isSelected ? category.color : FinzoTheme.divider(context),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: category.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 26, color: isSelected ? category.color : FinzoTheme.textSecondary(context)),
                const SizedBox(height: 4),
                Text(
                  category.displayName,
                  style: FinzoTypography.labelSmall(
                    color: isSelected ? category.color : FinzoTheme.textSecondary(context),
                  ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        decoration: BoxDecoration(
          color: FinzoTheme.surface(context),
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
          border: Border.all(color: FinzoTheme.divider(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(FinzoSpacing.sm),
              decoration: BoxDecoration(
                color: FinzoTheme.brandAccent(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(FinzoRadius.md),
              ),
              child: Icon(Icons.calendar_today_rounded, color: FinzoTheme.brandAccent(context)),
            ),
            const SizedBox(width: FinzoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date', style: FinzoTypography.labelSmall(color: FinzoTheme.textSecondary(context))),
                  const SizedBox(height: 2),
                  Text(_formatDate(_selectedDate), style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FinzoTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(FinzoSpacing.md),
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        border: Border.all(color: FinzoTheme.divider(context)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: FinzoTheme.textSecondary(context)),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [FinzoColors.brandPrimary, FinzoColors.brandSecondary]),
            borderRadius: BorderRadius.circular(FinzoRadius.md),
            boxShadow: [
              BoxShadow(color: FinzoColors.brandPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _addExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinzoRadius.md)),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text('Add Expense', style: FinzoTypography.labelLarge(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(FinzoSpacing.xl),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: BorderRadius.circular(FinzoRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: FinzoTheme.brandAccent(context)),
              const SizedBox(height: FinzoSpacing.md),
              Text('Scanning Bill...', style: FinzoTypography.titleSmall(color: FinzoTheme.textPrimary(context))),
              const SizedBox(height: FinzoSpacing.xs),
              Text('Extracting amount & category', style: FinzoTypography.bodySmall(color: FinzoTheme.textSecondary(context))),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) return 'Today';
    if (dateToCompare == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}


