import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/group.dart';
import '../../providers/splitwise_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_group_expense_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _useSimplifiedDebt = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<SplitWiseProvider>(
      builder: (context, provider, _) {
        final group = provider.groups.firstWhere(
          (g) => g.id == widget.groupId,
          orElse: () => Group(
            id: '',
            name: '',
            description: '',
            members: [],
            expenses: [],
            createdAt: DateTime.now(),
            createdBy: '',
            imageUrl: '',
            inviteCode: '',
          ),
        );

        if (group.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Group Details'),
              backgroundColor: FinzoTheme.background(context),
              elevation: 0,
            ),
            body: Center(
              child: Text('Group not found', style: TextStyle(color: FinzoTheme.textSecondary(context))),
            ),
          );
        }

        return Scaffold(
          backgroundColor: FinzoTheme.background(context),
          appBar: AppBar(
            title: Text(group.name),
            backgroundColor: FinzoTheme.background(context),
            elevation: 0,
            foregroundColor: FinzoTheme.textPrimary(context),
            actions: [
              IconButton(
                onPressed: () => _showShareDialog(group.inviteCode, group.name),
                icon: const Icon(Icons.share),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.exit_to_app, size: 20),
                        SizedBox(width: 8),
                        Text('Leave Group'),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final isCreator = group.createdBy == authProvider.user?.id;
                        final hasOtherMembers = group.members.length > 1;

                        // If creator with other members, show transfer ownership dialog
                        if (isCreator && hasOtherMembers) {
                          String? selectedMemberId;
                          
                          await showDialog(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: const Text('Transfer Ownership'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'As the group creator, you must transfer ownership before leaving.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Select new owner:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ...group.members
                                        .where((m) => m.userId != authProvider.user?.id)
                                        .map((member) => RadioListTile<String>(
                                              title: Text(member.name),
                                              subtitle: Text(member.email),
                                              value: member.userId,
                                              groupValue: selectedMemberId,
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedMemberId = value;
                                                });
                                              },
                                            )),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: selectedMemberId == null
                                        ? null
                                        : () async {
                                            final success = await provider.transferOwnership(
                                              group.id,
                                              selectedMemberId!,
                                            );
                                            if (context.mounted) {
                                              if (success) {
                                                Navigator.pop(context); // Close transfer dialog
                                                // Now show leave dialog
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Leave Group?'),
                                                    content: const Text(
                                                      'Ownership transferred. Do you want to leave the group now?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('Stay'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          final leaveSuccess =
                                                              await provider.leaveGroup(group.id);
                                                          if (context.mounted) {
                                                            Navigator.pop(context); // Close dialog
                                                            if (leaveSuccess) {
                                                              Navigator.pop(context); // Go back
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('You have left the group'),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: const Text('Leave'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(provider.errorMessage ??
                                                        'Failed to transfer ownership'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    child: const Text('Transfer'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Regular leave dialog for non-creators
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Leave Group?'),
                              content: const Text(
                                'Are you sure you want to leave this group?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final success = await provider.leaveGroup(group.id);
                                    if (context.mounted) {
                                      Navigator.pop(context); // Close dialog
                                      if (success) {
                                        Navigator.pop(context); // Go back to groups list
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('You have left the group'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content:
                                                Text(provider.errorMessage ?? 'Failed to leave group'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Leave', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Group Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FinzoTheme.surface(context),
                    borderRadius: BorderRadius.circular(FinzoRadius.lg),
                    border: Border.all(color: FinzoTheme.divider(context)),
                    boxShadow: FinzoShadows.small,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Info',
                        style: FinzoTypography.titleMedium(
                          color: FinzoTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        group.description.isEmpty ? 'No description' : group.description,
                        style: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Expenses',
                            style: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
                          ),
                          Text(
                            '₹${group.getTotalExpenses().toStringAsFixed(2)}',
                            style: FinzoTypography.titleMedium(
                              color: FinzoTheme.brandAccent(context),
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Statistics Section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final userId = authProvider.user?.id ?? '';
                    final userMember = group.members.firstWhere(
                      (m) => m.userId == userId,
                      orElse: () => group.members.first,
                    );
                    final balance = userMember.balance;
                    final totalSpent = group.expenses
                        .where((e) => e.paidBy == userId)
                        .fold(0.0, (sum, e) => sum + e.amount);

                    // Calculate category breakdown
                    final Map<String, double> categoryTotals = {};
                    for (var expense in group.expenses) {
                      categoryTotals[expense.category] =
                          (categoryTotals[expense.category] ?? 0) + expense.amount;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: FinzoTheme.surface(context),
                        borderRadius: BorderRadius.circular(FinzoRadius.lg),
                        border: Border.all(color: FinzoTheme.divider(context)),
                        boxShadow: FinzoShadows.small,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Statistics',
                            style: FinzoTypography.titleMedium(
                              color: FinzoTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Balance card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: balance >= 0
                                  ? FinzoColors.success.withOpacity(0.1)
                                  : FinzoColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(FinzoRadius.md),
                              border: Border.all(
                                color: balance >= 0
                                    ? FinzoColors.success.withOpacity(0.3)
                                    : FinzoColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      balance >= 0 ? 'You are owed' : 'You owe',
                                      style: FinzoTypography.labelMedium(
                                        color: FinzoTheme.textSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${balance.abs().toStringAsFixed(2)}',
                                      style: FinzoTypography.headlineMedium(
                                        color: balance >= 0 ? FinzoColors.success : FinzoColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  balance >= 0
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: balance >= 0 ? FinzoColors.success : FinzoColors.error,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'You Paid',
                                  '₹${totalSpent.toStringAsFixed(0)}',
                                  Icons.payment,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Members',
                                  '${group.members.length}',
                                  Icons.people,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Category breakdown
                          if (categoryTotals.isNotEmpty) ...[
                            Text(
                              'Expense Categories',
                              style: FinzoTypography.titleSmall(
                                color: FinzoTheme.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...categoryTotals.entries.map((entry) {
                              final percentage = (entry.value / group.getTotalExpenses()) * 100;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: FinzoTypography.labelSmall(
                                            color: FinzoTheme.textSecondary(context),
                                          ),
                                        ),
                                        Text(
                                          '₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)',
                                          style: FinzoTypography.labelMedium(
                                            color: FinzoTheme.textPrimary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: FinzoTheme.brandAccent(context).withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation(FinzoTheme.brandAccent(context)),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Members Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members (${group.members.length})',
                        style: FinzoTypography.titleMedium(
                          color: FinzoTheme.textPrimary(context),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddMemberDialog,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FinzoTheme.brandAccent(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...group.members.map((member) {
                  final balance = member.balance;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FinzoTheme.surface(context),
                      borderRadius: BorderRadius.circular(FinzoRadius.md),
                      border: Border.all(color: FinzoTheme.divider(context)),
                      boxShadow: FinzoShadows.small,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              balance >= 0 ? 'Gets back' : 'Owes',
                              style: FinzoTypography.labelSmall(
                                color: FinzoTheme.textSecondary(context),
                              ),
                            ),
                            Text(
                              '₹${balance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Settle Up Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settle Up',
                        style: FinzoTypography.titleMedium(
                          color: FinzoTheme.textPrimary(context),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Simplified',
                            style: FinzoTypography.labelSmall(
                              color: FinzoTheme.textSecondary(context),
                            ),
                          ),
                          Switch(
                            value: _useSimplifiedDebt,
                            onChanged: (value) {
                              setState(() {
                                _useSimplifiedDebt = value;
                              });
                            },
                            activeThumbColor: FinzoTheme.brandAccent(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildSettlements(context, group),

                const SizedBox(height: 20),

                // Expenses Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expenses (${group.expenses.length})',
                        style: FinzoTypography.titleMedium(
                          color: FinzoTheme.textPrimary(context),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddGroupExpenseScreen(groupId: widget.groupId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FinzoTheme.brandAccent(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No expenses yet',
                        style: FinzoTypography.bodyMedium(color: FinzoTheme.textSecondary(context)),
                      ),
                    ),
                  )
                else
                  ...group.expenses.map((expense) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FinzoTheme.surface(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FinzoTheme.brandAccent(context).withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.description,
                                    style: FinzoTypography.bodyMedium().copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: FinzoTheme.textPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    expense.paidByName,
                                    style: FinzoTypography.bodySmall().copyWith(
                                      color: FinzoTheme.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${expense.amount.toStringAsFixed(2)}',
                                style: FinzoTypography.bodyMedium().copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: FinzoTheme.brandAccent(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Split: ${expense.splits.map((s) => '${s.memberId} (₹${s.amount})').join(', ')}',
                            style: FinzoTypography.labelSmall().copyWith(
                              color: FinzoTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;

        return AlertDialog(
          backgroundColor: surfaceColor,
          title: const Text('Add Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  final provider =
                      Provider.of<SplitWiseProvider>(context, listen: false);
                  provider.addMemberToGroup(
                    groupId: widget.groupId,
                    userId: 'user_${emailController.text.split('@')[0]}',
                    name: nameController.text,
                    email: emailController.text,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member added successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showShareDialog(String inviteCode, String groupName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final textSecondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text('Share Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this code so others can join "$groupName"',
              style: TextStyle(color: textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inviteCode,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Copy to clipboard
                      await Clipboard.setData(ClipboardData(text: inviteCode));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Icon(
                      Icons.content_copy,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Others can join by entering this code in the "Join Group" option',
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSettlements(
    BuildContext context,
    Group group,
  ) {
    if (_useSimplifiedDebt) {
      return _buildSimplifiedSettlements(context, group);
    } else {
      return _buildDetailedSettlements(context, group);
    }
  }

  List<Widget> _buildSimplifiedSettlements(
    BuildContext context,
    Group group,
  ) {
    // Calculate net balance for each member
    Map<String, double> balances = {};
    for (var member in group.members) {
      balances[member.userId] = member.balance;
    }

    // Separate into creditors (positive balance) and debtors (negative balance)
    List<MapEntry<String, double>> creditors = [];
    List<MapEntry<String, double>> debtors = [];

    balances.forEach((userId, balance) {
      if (balance > 0.01) {
        creditors.add(MapEntry(userId, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(userId, -balance)); // Make positive for easier calculation
      }
    });

    // Sort descending
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Calculate settlements using greedy algorithm
    List<Map<String, dynamic>> settlements = [];
    int creditorIndex = 0;
    int debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      var creditor = creditors[creditorIndex];
      var debtor = debtors[debtorIndex];

      double amount = creditor.value < debtor.value ? creditor.value : debtor.value;

      // Find member names
      final debtorMember = group.members.firstWhere((m) => m.userId == debtor.key);
      final creditorMember = group.members.firstWhere((m) => m.userId == creditor.key);

      settlements.add({
        'from': debtorMember.name,
        'fromId': debtor.key,  // Store user ID
        'to': creditorMember.name,
        'toId': creditor.key,  // Store user ID
        'amount': amount,
      });

      // Update balances
      creditors[creditorIndex] = MapEntry(creditor.key, creditor.value - amount);
      debtors[debtorIndex] = MapEntry(debtor.key, debtor.value - amount);

      if (creditors[creditorIndex].value < 0.01) creditorIndex++;
      if (debtors[debtorIndex].value < 0.01) debtorIndex++;
    }

    if (settlements.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(FinzoRadius.lg),
              border: Border.all(color: FinzoTheme.divider(context)),
            ),
            child: Center(
              child: Text(
                '🎉 All settled up!',
                style: FinzoTypography.bodyMedium(
                  color: FinzoTheme.textSecondary(context),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return settlements.map((settlement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          // Show confirm settle dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Settle Payment?'),
              content: Text(
                'Mark payment of ₹${settlement['amount'].toStringAsFixed(2)} from ${settlement['from']} to ${settlement['to']} as settled?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                onPressed: () async {
                  // Call settle API
                  final provider = Provider.of<SplitWiseProvider>(context, listen: false);
                  final success = await provider.settleUp(
                    groupId: group.id,
                    fromUserId: settlement['fromId'],
                    toUserId: settlement['toId'],
                    amount: settlement['amount'],
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment settled! ${settlement['from']} paid ${settlement['to']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh to show updated balances
                      await provider.fetchGroupById(group.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Failed to settle payment'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Settle', style: TextStyle(color: Colors.green)),
              ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: FinzoTheme.textPrimary(context), fontSize: 14),
                    children: [
                      TextSpan(
                        text: settlement['from'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' pays '),
                      TextSpan(
                        text: settlement['to'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '₹${settlement['amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }).toList();
  }

  List<Widget> _buildDetailedSettlements(
    BuildContext context,
    Group group,
  ) {
    // Show all individual debts
    List<Widget> widgets = [];

    for (var member in group.members) {
      if (member.balance < -0.01) {
        // This member owes money
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FinzoTheme.surface(context),
                borderRadius: BorderRadius.circular(FinzoRadius.lg),
                border: Border.all(color: FinzoColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FinzoColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: FinzoColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${member.name} owes to group',
                      style: FinzoTypography.bodyMedium(
                        color: FinzoTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  Text(
                    '₹${member.balance.abs().toStringAsFixed(2)}',
                    style: FinzoTypography.titleMedium(
                      color: FinzoColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (member.balance > 0.01) {
        // This member is owed money
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FinzoTheme.surface(context),
                borderRadius: BorderRadius.circular(FinzoRadius.lg),
                border: Border.all(color: FinzoColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FinzoColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: FinzoColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Group owes ${member.name}',
                      style: FinzoTypography.bodyMedium(
                        color: FinzoTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  Text(
                    '₹${member.balance.toStringAsFixed(2)}',
                    style: FinzoTypography.titleMedium(
                      color: FinzoColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '🎉 All settled up!',
                style: FinzoTypography.bodyMedium().copyWith(
                  color: FinzoTheme.textSecondary(context),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return widgets;
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinzoTheme.brandAccent(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(FinzoRadius.md),
        border: Border.all(color: FinzoTheme.brandAccent(context).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FinzoTheme.brandAccent(context), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: FinzoTypography.labelSmall(
              color: FinzoTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: FinzoTypography.titleMedium(
              color: FinzoTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}


