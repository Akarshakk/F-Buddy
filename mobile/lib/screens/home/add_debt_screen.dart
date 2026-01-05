import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
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

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedType == DebtType.theyOweMe
                  ? Colors.green
                  : Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _addDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select debt type'),
          backgroundColor: AppColors.error,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.done_all, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedType == DebtType.theyOweMe
                      ? 'Reminder set! You\'ll be notified on ${_formatDate(_selectedDueDate)}'
                      : 'Reminder set! Don\'t forget to pay on ${_formatDate(_selectedDueDate)}',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(debtProvider.errorMessage ?? 'Failed to add debt'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Debt'),
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebtListScreen()),
              );
            },
            icon: const Icon(Icons.history, color: AppColors.primary),
            label: const Text(
              'View All',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Debt Type Selection
              const Text(
                'Who owes whom?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      type: DebtType.theyOweMe,
                      icon: Icons.arrow_outward,
                      title: 'They Owe Me',
                      subtitle: 'Someone owes you money',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeCard(
                      type: DebtType.iOwe,
                      icon: Icons.credit_card,
                      title: 'I Owe',
                      subtitle: 'You owe someone money',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),

              if (_selectedType != null) ...[
                const SizedBox(height: 24),

                // Amount Input
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedType == DebtType.theyOweMe
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedType == DebtType.theyOweMe
                                ? Colors.green
                                : Colors.orange)
                            .withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedType == DebtType.theyOweMe
                            ? 'Amount to Receive'
                            : 'Amount to Pay',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 40,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Person Name
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.cardDecoration,
                  child: TextFormField(
                    controller: _personNameController,
                    decoration: InputDecoration(
                      hintText: _selectedType == DebtType.theyOweMe
                          ? 'Who owes you?'
                          : 'Who do you owe?',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the person\'s name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Due Date Selection
                GestureDetector(
                  onTap: _selectDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.cardDecoration,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_selectedType == DebtType.theyOweMe
                                    ? Colors.green
                                    : Colors.orange)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: _selectedType == DebtType.theyOweMe
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedType == DebtType.theyOweMe
                                    ? 'When should they pay?'
                                    : 'When do you need to pay?',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(_selectedDueDate),
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: _selectedType == DebtType.theyOweMe
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description (optional)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.cardDecoration,
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Add a note (optional)',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Reminder Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'ll receive a reminder on the due date',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Add Button
                Consumer<DebtProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _addDebt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == DebtType.theyOweMe
                              ? Colors.green
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _selectedType == DebtType.theyOweMe
                                    ? 'Set Reminder to Collect'
                                    : 'Set Reminder to Pay',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
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
      onTap: () {
        setState(() => _selectedType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
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
            Icon(icon, size: 40, color: isSelected ? color : AppColors.textPrimary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color.withOpacity(0.8) : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
