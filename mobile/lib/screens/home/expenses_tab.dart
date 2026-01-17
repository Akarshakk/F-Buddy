import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../widgets/expense_card.dart';
import '../../widgets/auto_translated_text.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String? _selectedCategory;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpenses();
    });
  }

  Future<void> _loadExpenses() async {
    await Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(
      category: _selectedCategory,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimaryColor = isDark ? const Color.fromARGB(255, 234, 237, 243) : AppColors.textPrimary;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final primaryLightColor = isDark ? AppColorsDark.primaryLight : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const AutoTranslatedText('Expenses'),
        backgroundColor: bgColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: textPrimaryColor),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_selectedCategory != null || _dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: AutoTranslatedText(
                        Category.getByName(_selectedCategory!).displayName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedCategory = null);
                        _loadExpenses();
                      },
                      backgroundColor: primaryLightColor.withOpacity(0.2),
                      labelStyle: TextStyle(color: primaryColor),
                      deleteIconColor: primaryColor,
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: AutoTranslatedText(
                        '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _dateRange = null);
                        _loadExpenses();
                      },
                      backgroundColor: AppColors.secondaryLight.withOpacity(0.2),
                      labelStyle: const TextStyle(color: AppColors.secondary),
                      deleteIconColor: AppColors.secondary,
                    ),
                ],
              ),
            ),

          // Swipe hint
          Consumer<ExpenseProvider>(
            builder: (context, provider, _) {
              if (provider.expenses.isEmpty) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryLightColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe_left, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    AutoTranslatedText(
                      'Swipe left to delete an expense',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Expenses list
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, _) {
                if (expenseProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = expenseProvider.expenses;

                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        AutoTranslatedText(
                          'No expenses found',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const AutoTranslatedText(
                          'Start tracking your expenses',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  );
                }

                // Group expenses by date
                final groupedExpenses = _groupExpensesByDate(expenses);

                return RefreshIndicator(
                  onRefresh: _loadExpenses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedExpenses.length,
                    itemBuilder: (context, index) {
                      final date = groupedExpenses.keys.elementAt(index);
                      final dayExpenses = groupedExpenses[date]!;
                      final dayTotal = dayExpenses.fold<double>(
                        0,
                        (sum, e) => sum + e.amount,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AutoTranslatedText(
                                  _formatDate(date),
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(dayTotal)}',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: AppDecorations.cardDecoration.copyWith(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayExpenses.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                return Dismissible(
                                  key: Key(dayExpenses[i].id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: AppColors.error,
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const AutoTranslatedText('Delete Expense'),
                                        content: const AutoTranslatedText(
                                          'Are you sure you want to delete this expense?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const AutoTranslatedText('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const AutoTranslatedText(
                                              'Delete',
                                              style: TextStyle(color: AppColors.error),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) {
                                    expenseProvider.deleteExpense(dayExpenses[i].id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: AutoTranslatedText('Expense deleted'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: ExpenseCard(expense: dayExpenses[i]),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final Map<DateTime, List<Expense>> grouped = {};
    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(expense);
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMMM').format(date);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoTranslatedText('Filter Expenses', style: AppTextStyles.heading3),
              const SizedBox(height: 24),
              
              // Category filter
              const AutoTranslatedText('Category', style: AppTextStyles.body1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Category.all.map((category) {
                  final isSelected = _selectedCategory == category.name;
                  return FilterChip(
                    avatar: Icon(category.icon, size: 18, color: isSelected ? category.color : AppColors.textSecondary),
                    label: AutoTranslatedText(category.displayName), // Category displayName is usually localized? No, it's a string. AutoTranslate it.
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category.name : null;
                      });
                      Navigator.pop(context);
                      _loadExpenses();
                    },
                    selectedColor: category.color.withOpacity(0.2),
                    checkmarkColor: category.color,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Date range filter
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const AutoTranslatedText('Select Date Range'),
                subtitle: _dateRange != null
                    ? AutoTranslatedText(
                        '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                      )
                    : const AutoTranslatedText('All time'),
                onTap: () {
                  Navigator.pop(context);
                  _selectDateRange();
                },
              ),
              const SizedBox(height: 16),
              
              // Clear filters
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _dateRange = null;
                    });
                    Navigator.pop(context);
                    _loadExpenses();
                  },
                  child: const AutoTranslatedText('Clear All Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
