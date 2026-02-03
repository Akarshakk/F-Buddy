import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/splitwise_provider.dart';
import '../../providers/auth_provider.dart';

class SplitwisFriendsTab extends StatelessWidget {
  const SplitwisFriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SplitWiseProvider, AuthProvider>(
      builder: (context, splitwiseProvider, authProvider, _) {
        final groups = splitwiseProvider.groups;
        final userId = authProvider.user?.id ?? '';

        // Get all unique friends (members from all groups, excluding current user)
        Map<String, Map<String, dynamic>> friendsMap = {};
        
        for (var group in groups) {
          for (var member in group.members) {
            if (member.userId != userId) {
              if (!friendsMap.containsKey(member.userId)) {
                friendsMap[member.userId] = {
                  'name': member.name,
                  'email': member.email,
                  'totalOwed': 0.0,
                  'totalLent': 0.0,
                  'groups': <String>[],
                };
              }
              friendsMap[member.userId]!['totalOwed'] = 
                  (friendsMap[member.userId]!['totalOwed'] as double) + member.amountOwed;
              friendsMap[member.userId]!['totalLent'] = 
                  (friendsMap[member.userId]!['totalLent'] as double) + member.amountLent;
              (friendsMap[member.userId]!['groups'] as List<String>).add(group.name);
            }
          }
        }

        if (friendsMap.isEmpty) {
          return Scaffold(
            backgroundColor: FinzoTheme.background(context),
            body: _buildEmptyState(context),
          );
        }

        return Scaffold(
          backgroundColor: FinzoTheme.background(context),
          body: ListView.builder(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            itemCount: friendsMap.length,
            itemBuilder: (context, index) {
              final friendId = friendsMap.keys.elementAt(index);
              final friend = friendsMap[friendId]!;
              final balance = (friend['totalLent'] as double) - (friend['totalOwed'] as double);
              return _buildFriendCard(context, friend, balance);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FinzoColors.brandPrimary.withOpacity(0.1),
                  FinzoColors.brandSecondary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: FinzoTheme.brandAccent(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.lg),
          Text(
            'No Friends Yet',
            style: FinzoTypography.titleLarge(
              color: FinzoTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.sm),
          Text(
            'Join groups to see friends here',
            style: FinzoTypography.bodyMedium(
              color: FinzoTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend, double balance) {
    final isPositive = balance >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: FinzoSpacing.md),
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        boxShadow: FinzoShadows.small,
        border: Border.all(color: FinzoTheme.divider(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FinzoColors.brandPrimary.withOpacity(0.8),
                    FinzoColors.brandSecondary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (friend['name'] as String).substring(0, 1).toUpperCase(),
                  style: FinzoTypography.titleLarge(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: FinzoSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend['name'] as String,
                    style: FinzoTypography.titleMedium(
                      color: FinzoTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FinzoSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FinzoTheme.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(FinzoRadius.sm),
                    ),
                    child: Text(
                      '${(friend['groups'] as List).length} group(s)',
                      style: FinzoTypography.labelSmall(
                        color: FinzoTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FinzoSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive 
                        ? FinzoColors.success.withOpacity(0.1)
                        : FinzoColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(FinzoRadius.sm),
                  ),
                  child: Text(
                    isPositive ? 'Gets' : 'Owes',
                    style: FinzoTypography.labelSmall(
                      color: isPositive ? FinzoColors.success : FinzoColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${balance.abs().toStringAsFixed(0)}',
                  style: FinzoTypography.titleMedium(
                    color: isPositive ? FinzoColors.success : FinzoColors.error,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


