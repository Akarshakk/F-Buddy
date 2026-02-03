import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/income_provider.dart';
import '../../providers/analytics_provider.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedSource = 'pocket_money';

  final List<Map<String, dynamic>> _sources = [
    {'id': 'pocket_money', 'name': 'Pocket Money', 'icon': '💰'},
    {'id': 'salary', 'name': 'Salary', 'icon': '💼'},
    {'id': 'freelance', 'name': 'Freelance', 'icon': '💻'},
    {'id': 'gift', 'name': 'Gift', 'icon': '🎁'},
    {'id': 'scholarship', 'name': 'Scholarship', 'icon': '🎓'},
    {'id': 'other', 'name': 'Other', 'icon': '📦'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: FinzoTypography.bodyMedium(color: Colors.white)),
        backgroundColor: isSuccess ? FinzoColors.success : isError ? FinzoColors.error : FinzoColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinzoRadius.sm)),
        margin: const EdgeInsets.all(FinzoSpacing.md),
      ),
    );
  }

  Future<void> _addIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);

    final success = await incomeProvider.addIncome(
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Monthly Income',
      source: _selectedSource,
    );

    if (!mounted) return;

    if (success) {
      await analyticsProvider.fetchDashboardData();
      await analyticsProvider.fetchBalanceChartData();
      _showSnackBar('Income added successfully!', isSuccess: true);
      Navigator.pop(context);
    } else {
      _showSnackBar(incomeProvider.errorMessage ?? 'Failed to add income', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        title: Text(
          'Add Income',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Container(
                padding: const EdgeInsets.all(FinzoSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FinzoColors.success, Color(0xFF4ECDC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(FinzoRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: FinzoColors.success.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Enter Income Amount',
                      style: FinzoTypography.bodyMedium(color: Colors.white70),
                    ),
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
                        hintText: '0',
                        hintStyle: FinzoTypography.displayLarge(color: Colors.white38),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an amount';
                        if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Please enter a valid amount';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FinzoSpacing.xl),

              // Source Selection
              Text(
                'Income Source',
                style: FinzoTypography.titleSmall(color: FinzoTheme.textPrimary(context)),
              ),
              const SizedBox(height: FinzoSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: FinzoSpacing.sm,
                  mainAxisSpacing: FinzoSpacing.sm,
                ),
                itemCount: _sources.length,
                itemBuilder: (context, index) {
                  final source = _sources[index];
                  final isSelected = _selectedSource == source['id'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedSource = source['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? FinzoColors.success.withOpacity(0.15)
                            : FinzoTheme.surface(context),
                        borderRadius: BorderRadius.circular(FinzoRadius.lg),
                        border: Border.all(
                          color: isSelected ? FinzoColors.success : FinzoTheme.divider(context),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: FinzoColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(source['icon'], style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(
                            source['name'],
                            style: FinzoTypography.labelSmall(
                              color: isSelected ? FinzoColors.success : FinzoTheme.textSecondary(context),
                            ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: FinzoSpacing.xl),

              // Description
              Container(
                padding: const EdgeInsets.all(FinzoSpacing.md),
                decoration: BoxDecoration(
                  color: FinzoTheme.surface(context),
                  borderRadius: BorderRadius.circular(FinzoRadius.lg),
                  border: Border.all(color: FinzoTheme.divider(context)),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    hintStyle: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.note_outlined, color: FinzoTheme.textSecondary(context)),
                  ),
                ),
              ),
              const SizedBox(height: FinzoSpacing.xl),

              // Add Button
              Consumer<IncomeProvider>(
                builder: (context, provider, _) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [FinzoColors.success, Color(0xFF4ECDC4)],
                      ),
                      borderRadius: BorderRadius.circular(FinzoRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: FinzoColors.success.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _addIncome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                        ),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Add Income', style: FinzoTypography.labelLarge(color: Colors.white)),
                    ),
                  );
                },
              ),
              const SizedBox(height: FinzoSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}


