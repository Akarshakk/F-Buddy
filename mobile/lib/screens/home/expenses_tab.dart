import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/expense_card.dart';

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
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        title: Text(context.l10n.t('expenses'), style: FinzoTypography.headlineMedium()),
        backgroundColor: FinzoTheme.background(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: FinzoTheme.textPrimary(context)),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_selectedCategory != null || _dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.md, vertical: FinzoSpacing.sm),
              child: Wrap(
                spacing: FinzoSpacing.sm,
                runSpacing: FinzoSpacing.sm,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: Text(
                        Category.getByName(_selectedCategory!).displayName,
                        style: FinzoTypography.labelMedium(),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedCategory = null);
                        _loadExpenses();
                      },
                      backgroundColor: FinzoTheme.brandAccent(context).withOpacity(0.1),
                      labelStyle: TextStyle(color: FinzoTheme.brandAccent(context)),
                      deleteIconColor: FinzoTheme.brandAccent(context),
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                        style: FinzoTypography.labelMedium(),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _dateRange = null);
                        _loadExpenses();
                      },
                      backgroundColor: FinzoColors.info.withOpacity(0.1),
                      labelStyle: const TextStyle(color: FinzoColors.info),
                      deleteIconColor: FinzoColors.info,
                    ),
                ],
              ),
            ),

          // Swipe hint
          Consumer<ExpenseProvider>(
            builder: (context, provider, _) {
              if (provider.expenses.isEmpty) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: FinzoSpacing.md, vertical: FinzoSpacing.sm),
                padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.sm, vertical: FinzoSpacing.sm),
                decoration: BoxDecoration(
                  color: FinzoTheme.brandAccent(context).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(FinzoRadius.md),
                  border: Border.all(color: FinzoTheme.brandAccent(context).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe_left, size: 16, color: FinzoTheme.brandAccent(context)),
                    const SizedBox(width: FinzoSpacing.sm),
                    Text(
                      'Swipe left to delete an expense',
                      style: FinzoTypography.labelSmall().copyWith(
                        color: FinzoTheme.brandAccent(context),
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
                  return Center(child: CircularProgressIndicator(color: FinzoTheme.brandAccent(context)));
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
                          color: FinzoTheme.textTertiary(context),
                        ),
                        const SizedBox(height: FinzoSpacing.md),
                        Text(
                          'No expenses found',
                          style: FinzoTypography.titleLarge(),
                        ),
                        const SizedBox(height: FinzoSpacing.sm),
                        Text(
                          'Start tracking your expenses',
                          style: FinzoTypography.bodyMedium().copyWith(
                            color: FinzoTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group expenses by date
                final groupedExpenses = _groupExpensesByDate(expenses);

                return RefreshIndicator(
                  color: FinzoTheme.brandAccent(context),
                  onRefresh: _loadExpenses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(FinzoSpacing.md),
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
                            padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.sm, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(date),
                                  style: FinzoTypography.labelLarge().copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##,###').format(dayTotal)}',
                                  style: FinzoTypography.labelMedium().copyWith(
                                    color: FinzoColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FinzoTheme.surface(context),
                              borderRadius: BorderRadius.circular(FinzoRadius.lg),
                              boxShadow: FinzoShadows.small,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayExpenses.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: FinzoTheme.divider(context)),
                              itemBuilder: (context, i) {
                                return Dismissible(
                                  key: Key(dayExpenses[i].id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: FinzoColors.error,
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: FinzoTheme.surface(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(FinzoRadius.lg),
                                        ),
                                        title: Text('Delete Expense', style: FinzoTypography.titleLarge()),
                                        content: Text(
                                          'Are you sure you want to delete this expense?',
                                          style: FinzoTypography.bodyMedium(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Cancel',
                                              style: FinzoTypography.labelMedium().copyWith(
                                                color: FinzoTheme.textSecondary(context),
                                              ),
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: FinzoColors.error,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) {
                                    expenseProvider.deleteExpense(dayExpenses[i].id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Expense deleted'),
                                        backgroundColor: FinzoTheme.brandAccent(context),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: ExpenseCard(expense: dayExpenses[i]),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: FinzoSpacing.md),
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FinzoRadius.xl)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(FinzoSpacing.lg),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(FinzoRadius.xl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: FinzoSpacing.md),
                  decoration: BoxDecoration(
                    color: FinzoTheme.divider(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Filter Expenses', style: FinzoTypography.titleLarge()),
              const SizedBox(height: FinzoSpacing.lg),
              
              // Category filter
              Text('Category', style: FinzoTypography.labelLarge()),
              const SizedBox(height: FinzoSpacing.sm),
              Wrap(
                spacing: FinzoSpacing.sm,
                runSpacing: FinzoSpacing.sm,
                children: Category.all.map((category) {
                  final isSelected = _selectedCategory == category.name;
                  return FilterChip(
                    avatar: Icon(category.icon, size: 18, color: isSelected ? category.color : FinzoTheme.textSecondary(context)),
                    label: Text(category.displayName),
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
              const SizedBox(height: FinzoSpacing.lg),
              
              // Date range filter
              ListTile(
                leading: Icon(Icons.date_range, color: FinzoTheme.brandAccent(context)),
                title: Text('Select Date Range', style: FinzoTypography.bodyMedium()),
                subtitle: _dateRange != null
                    ? Text(
                        '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                        style: FinzoTypography.bodySmall().copyWith(
                          color: FinzoTheme.textSecondary(context),
                        ),
                      )
                    : Text(
                        'All time',
                        style: FinzoTypography.bodySmall().copyWith(
                          color: FinzoTheme.textSecondary(context),
                        ),
                      ),
                onTap: () {
                  Navigator.pop(context);
                  _selectDateRange();
                },
              ),
              const SizedBox(height: FinzoSpacing.md),
              
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
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: FinzoTheme.divider(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FinzoRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.md),
                  ),
                  child: Text(
                    'Clear All Filters',
                    style: FinzoTypography.labelMedium(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}