import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/debt.dart';
import '../../providers/debt_provider.dart';
import 'debt_list_screen.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DebtType? _selectedType;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false, int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isSuccess) ...[
              const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
              const SizedBox(width: FinzoSpacing.sm),
            ],
            Expanded(
              child: Text(message,
                  style: FinzoTypography.bodyMedium(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? FinzoColors.success
            : isError
                ? FinzoColors.error
                : FinzoColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinzoRadius.sm)),
        margin: const EdgeInsets.all(FinzoSpacing.md),
        duration: Duration(seconds: duration),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        final color = _selectedType == DebtType.theyOweMe
            ? FinzoColors.success
            : FinzoColors.warning;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: color,
              onPrimary: Colors.white,
              surface: FinzoTheme.surface(context),
              onSurface: FinzoTheme.textPrimary(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDueDate = picked);
  }

  Future<void> _addDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      _showSnackBar('Please select debt type', isError: true);
      return;
    }

    final debtProvider = Provider.of<DebtProvider>(context, listen: false);

    final success = await debtProvider.addDebt(
      type: _selectedType!,
      amount: double.parse(_amountController.text),
      personName: _personNameController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _selectedDueDate,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar(
        _selectedType == DebtType.theyOweMe
            ? 'Reminder set! You\'ll be notified on ${_formatDate(_selectedDueDate)}'
            : 'Reminder set! Don\'t forget to pay on ${_formatDate(_selectedDueDate)}',
        isSuccess: true,
        duration: 3,
      );
      Navigator.pop(context, true);
    } else {
      _showSnackBar(debtProvider.errorMessage ?? 'Failed to add debt',
          isError: true);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Color get _typeColor =>
      _selectedType == DebtType.theyOweMe ? FinzoColors.success : FinzoColors.warning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        title: Text(
          'Add Debt',
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
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtListScreen())),
            icon: Icon(Icons.history_rounded, color: FinzoTheme.brandAccent(context), size: 20),
            label: Text(
              'View All',
              style: FinzoTypography.labelMedium(color: FinzoTheme.brandAccent(context)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Debt Type Selection
              Text(
                'Who owes whom?',
                style: FinzoTypography.titleSmall(color: FinzoTheme.textPrimary(context)),
              ),
              const SizedBox(height: FinzoSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      type: DebtType.theyOweMe,
                      icon: Icons.arrow_upward_rounded,
                      title: 'They Owe Me',
                      subtitle: 'Someone owes you money',
                      color: FinzoColors.success,
                    ),
                  ),
                  const SizedBox(width: FinzoSpacing.md),
                  Expanded(
                    child: _buildTypeCard(
                      type: DebtType.iOwe,
                      icon: Icons.arrow_downward_rounded,
                      title: 'I Owe',
                      subtitle: 'You owe someone money',
                      color: FinzoColors.warning,
                    ),
                  ),
                ],
              ),

              if (_selectedType != null) ...[
                const SizedBox(height: FinzoSpacing.xl),

                // Amount Input
                Container(
                  padding: const EdgeInsets.all(FinzoSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedType == DebtType.theyOweMe
                          ? [FinzoColors.success, const Color(0xFF4ECDC4)]
                          : [FinzoColors.warning, const Color(0xFFFFB347)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(FinzoRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: _typeColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedType == DebtType.theyOweMe ? 'Amount to Receive' : 'Amount to Pay',
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

                // Person Name
                _buildInputCard(
                  controller: _personNameController,
                  hint: _selectedType == DebtType.theyOweMe ? 'Who owes you?' : 'Who do you owe?',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter the person\'s name';
                    return null;
                  },
                ),
                const SizedBox(height: FinzoSpacing.md),

                // Due Date Selection
                GestureDetector(
                  onTap: _selectDueDate,
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
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(FinzoRadius.md),
                          ),
                          child: Icon(Icons.calendar_today_rounded, color: _typeColor),
                        ),
                        const SizedBox(width: FinzoSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedType == DebtType.theyOweMe
                                    ? 'When should they pay?'
                                    : 'When do you need to pay?',
                                style: FinzoTypography.labelSmall(color: FinzoTheme.textSecondary(context)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(_selectedDueDate),
                                style: FinzoTypography.bodyMedium(color: FinzoTheme.textPrimary(context)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: _typeColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: FinzoSpacing.md),

                // Description
                _buildInputCard(
                  controller: _descriptionController,
                  hint: 'Add a note (optional)',
                  icon: Icons.note_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: FinzoSpacing.lg),

                // Reminder Info Card
                Container(
                  padding: const EdgeInsets.all(FinzoSpacing.md),
                  decoration: BoxDecoration(
                    color: FinzoColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(FinzoRadius.md),
                    border: Border.all(color: FinzoColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: FinzoColors.info),
                      const SizedBox(width: FinzoSpacing.md),
                      Expanded(
                        child: Text(
                          'You\'ll receive a reminder on the due date',
                          style: FinzoTypography.bodySmall(color: FinzoColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FinzoSpacing.xl),

                // Add Button
                Consumer<DebtProvider>(
                  builder: (context, provider, _) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _selectedType == DebtType.theyOweMe
                              ? [FinzoColors.success, const Color(0xFF4ECDC4)]
                              : [FinzoColors.warning, const Color(0xFFFFB347)],
                        ),
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: _typeColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _addDebt,
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
                            : Text(
                                _selectedType == DebtType.theyOweMe
                                    ? 'Set Reminder to Collect'
                                    : 'Set Reminder to Pay',
                                style: FinzoTypography.labelLarge(color: Colors.white),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: FinzoSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
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
        validator: validator,
      ),
    );
  }

  Widget _buildTypeCard({
    required DebtType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(FinzoSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : FinzoTheme.surface(context),
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
          border: Border.all(
            color: isSelected ? color : FinzoTheme.divider(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(FinzoSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : FinzoTheme.surfaceVariant(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: isSelected ? color : FinzoTheme.textSecondary(context)),
            ),
            const SizedBox(height: FinzoSpacing.sm),
            Text(
              title,
              style: FinzoTypography.labelLarge(
                color: isSelected ? color : FinzoTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: FinzoTypography.labelSmall(
                color: isSelected ? color.withOpacity(0.8) : FinzoTheme.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


