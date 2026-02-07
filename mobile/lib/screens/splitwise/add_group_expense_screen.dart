import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/group.dart' show GroupExpenseSplit;
import '../../providers/splitwise_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';

class AddGroupExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddGroupExpenseScreen({super.key, required this.groupId});

  @override
  State<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends State<AddGroupExpenseScreen> {
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  String selectedCategory = 'restaurant';
  bool splitEqually = true;
  final Map<String, double> memberSplits = {};
  String? selectedPayerId; // Track who paid for the expense
  final Set<String> selectedMembers = {}; // Track who's involved in the split

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SplitWiseProvider>(context, listen: false);
    final group =
        provider.groups.firstWhere((g) => g.id == widget.groupId);

    // Set default payer to current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    selectedPayerId = authProvider.user?.id ?? group.members.first.userId;

    // Initialize splits and select all members by default
    for (var member in group.members) {
      memberSplits[member.userId] = 0;
      selectedMembers.add(member.userId); // All members selected by default
    }
  }

  // Calculate equal splits for selected members only
  void _calculateEqualSplits() {
    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount > 0 && selectedMembers.isNotEmpty) {
      final provider = Provider.of<SplitWiseProvider>(context, listen: false);
      final group = provider.groups.firstWhere((g) => g.id == widget.groupId);
      final perPerson = amount / selectedMembers.length;
      for (var member in group.members) {
        // Only split among selected members
        memberSplits[member.userId] = selectedMembers.contains(member.userId) ? perPerson : 0;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SplitWiseProvider>(
      builder: (context, provider, _) {
        final group = provider.groups.firstWhere(
          (g) => g.id == widget.groupId,
        );
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        return Scaffold(
          backgroundColor: FinzoTheme.background(context),
          appBar: AppBar(
            title: Text('Add Expense', style: FinzoTypography.titleLarge(color: FinzoTheme.textPrimary(context))),
            backgroundColor: FinzoTheme.background(context),
            elevation: 0,
            foregroundColor: FinzoTheme.textPrimary(context),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense Description (Optional)
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g., Dinner',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.brandAccent(context), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.brandAccent(context), width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (splitEqually) {
                        _calculateEqualSplits();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Paid By Dropdown
                  Text(
                    'Paid by',
                    style: FinzoTypography.titleSmall(
                      color: FinzoTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPayerId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: group.members.map((member) {
                      return DropdownMenuItem<String>(
                        value: member.userId,
                        child: Text('${member.name} (${member.email})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPayerId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'Category',
                    style: FinzoTypography.titleSmall(
                      color: FinzoTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                        borderSide: BorderSide(color: FinzoTheme.divider(context)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      'restaurant',
                      'school',
                      'local_bar',
                      'shopping',
                      'transportation',
                      'entertainment',
                      'utilities',
                      'other'
                    ]
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Split Type
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FinzoTheme.surface(context),
                      borderRadius: BorderRadius.circular(FinzoRadius.md),
                      border: Border.all(color: FinzoTheme.divider(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to split?',
                          style: FinzoTypography.titleSmall(
                            color: FinzoTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<bool>(
                          value: true,
                          groupValue: splitEqually,
                          onChanged: (value) {
                            setState(() => splitEqually = value ?? true);
                            // Calculate equal splits when switching to equal mode
                            if (splitEqually) {
                              _calculateEqualSplits();
                            }
                          },
                          activeColor: FinzoTheme.brandAccent(context),
                          title: const Text('Split Equally'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: splitEqually,
                          onChanged: (value) {
                            setState(() => splitEqually = value ?? false);
                          },
                          activeColor: FinzoTheme.brandAccent(context),
                          title: const Text('Custom Split'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Members and Split amounts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members',
                        style: FinzoTypography.titleMedium(
                          color: FinzoTheme.textPrimary(context),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (selectedMembers.length == group.members.length) {
                              // Deselect all
                              selectedMembers.clear();
                            } else {
                              // Select all
                              selectedMembers.clear();
                              for (var member in group.members) {
                                selectedMembers.add(member.userId);
                              }
                            }
                            // Recalculate if equal split
                            if (splitEqually) {
                              _calculateEqualSplits();
                            }
                          });
                        },
                        icon: Icon(
                          selectedMembers.length == group.members.length
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: FinzoTheme.brandAccent(context),
                        ),
                        label: Text(
                          selectedMembers.length == group.members.length
                              ? 'Deselect All'
                              : 'Select All',
                          style: FinzoTypography.labelSmall(
                            color: FinzoTheme.brandAccent(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...group.members.map((member) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FinzoTheme.surface(context),
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                          border: Border.all(color: FinzoTheme.divider(context)),
                        ),
                        child: Row(
                          children: [
                            // Checkbox to select/deselect member
                            Checkbox(
                              value: selectedMembers.contains(member.userId),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedMembers.add(member.userId);
                                  } else {
                                    selectedMembers.remove(member.userId);
                                  }
                                  // Recalculate splits if in equal mode
                                  if (splitEqually) {
                                    _calculateEqualSplits();
                                  } else {
                                    // Set to 0 if unselected in unequal mode
                                    if (!selectedMembers.contains(member.userId)) {
                                      memberSplits[member.userId] = 0;
                                    }
                                  }
                                });
                              },
                              activeColor: FinzoTheme.brandAccent(context),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: FinzoTypography.titleSmall(
                                      color: FinzoTheme.textPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    member.email,
                                    style: FinzoTypography.bodySmall(
                                      color: FinzoTheme.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (splitEqually)
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: '₹0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(FinzoRadius.sm),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: memberSplits[member.userId]
                                            ?.toStringAsFixed(2) ??
                                        '0',
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  enabled: selectedMembers.contains(member.userId),
                                  decoration: InputDecoration(
                                    hintText: '₹0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(FinzoRadius.sm),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(
                                    text: memberSplits[member.userId]
                                            ?.toStringAsFixed(2) ??
                                        '0',
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      memberSplits[member.userId] =
                                          double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount > 0 && selectedPayerId != null) {
                          // Get payer details
                          final payer = group.members.firstWhere(
                            (m) => m.userId == selectedPayerId,
                          );

                          // Create splits list
                          final splits = memberSplits.entries
                              .where((e) => e.value > 0)
                              .map((e) {
                            final member = group.members.firstWhere(
                              (m) => m.userId == e.key,
                            );
                            return GroupExpenseSplit(
                              memberId: e.key,
                              memberName: member.name,
                              amount: e.value,
                            );
                          }).toList();

                          final success = await provider.addGroupExpense(
                            groupId: widget.groupId,
                            description: descriptionController.text.isEmpty
                                ? 'Group Expense'
                                : descriptionController.text,
                            amount: amount,
                            category: selectedCategory,
                            paidBy: selectedPayerId!,
                            paidByName: payer.name,
                            splits: splits,
                          );

                          // Get the created group expense ID so we can link it
                          String? groupExpenseId;
                          if (success && provider.currentGroup!= null) {
                            final updatedGroup = provider.currentGroup!;
                            if (updatedGroup.expenses.isNotEmpty) {
                              groupExpenseId = updatedGroup.expenses.last.id;
                            }
                          }

                          // Always add user's share to personal expenses with group link
                          if (success && groupExpenseId != null) {
                            final authUserId = authProvider.user?.id;
                            if (authUserId != null) {
                              final expenseProvider =
                                  Provider.of<ExpenseProvider>(context, listen: false);
                              
                              // Calculate user's share
                              final userSplit = splits.firstWhere(
                                (s) => s.memberId == authUserId,
                                orElse: () => GroupExpenseSplit(
                                  memberId: authUserId,
                                  memberName: authProvider.user?.name ?? '',
                                  amount: 0,
                                ),
                              );
                              
                              // Only add if user has a share in this expense
                              if (userSplit.amount > 0) {
                                // Map category from group to personal expense category
                                String personalCategory = selectedCategory;
                                if (selectedCategory == 'restaurant' || selectedCategory == 'local_bar') {
                                  personalCategory = 'food';
                                } else if (selectedCategory == 'school') {
                                  personalCategory = 'education';
                                }
                                
                                await expenseProvider.addExpense(
                                  amount: userSplit.amount, // User's share
                                  category: personalCategory,
                                  description: descriptionController.text.isEmpty
                                      ? 'Group Expense - ${group.name}'
                                      : descriptionController.text,
                                  date: DateTime.now(),
                                  groupExpenseId: groupExpenseId,  // LINK TO GROUP
                                  groupId: widget.groupId,          // LINK TO GROUP
                                );
                              }
                            }
                          }

                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense added successfully!'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter an amount and select who paid',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinzoTheme.brandAccent(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                        ),
                      ),
                      child: Text(
                        'Add Expense',
                        style: FinzoTypography.titleSmall(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


