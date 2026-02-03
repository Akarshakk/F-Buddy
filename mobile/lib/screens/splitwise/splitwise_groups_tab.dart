import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/splitwise_provider.dart';
import '../../l10n/app_localizations.dart';
import 'group_details_screen.dart';

class SplitwiseGroupsTab extends StatelessWidget {
  const SplitwiseGroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SplitWiseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: FinzoTheme.brandAccent(context),
            ),
          );
        }

        if (provider.groups.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchGroups(),
          color: FinzoTheme.brandAccent(context),
          child: ListView.builder(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return _buildGroupCard(context, group, provider);
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
              Icons.groups_rounded,
              size: 48,
              color: FinzoTheme.brandAccent(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.lg),
          Text(
            context.l10n.t('no_groups'),
            style: FinzoTypography.titleLarge(
              color: FinzoTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.sm),
          Text(
            context.l10n.t('create_group'),
            style: FinzoTypography.bodyMedium(
              color: FinzoTheme.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, dynamic group, SplitWiseProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: FinzoSpacing.md),
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        boxShadow: FinzoShadows.small,
        border: Border.all(
          color: FinzoTheme.divider(context),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailsScreen(groupId: group.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Group Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            FinzoColors.brandPrimary,
                            FinzoColors.brandSecondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.group_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: FinzoSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: FinzoTypography.titleMedium(
                              color: FinzoTheme.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.description.isEmpty
                                ? 'No description'
                                : group.description,
                            style: FinzoTypography.bodySmall(
                              color: FinzoTheme.textSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildPopupMenu(context, group, provider),
                  ],
                ),
                const SizedBox(height: FinzoSpacing.md),
                Divider(color: FinzoTheme.divider(context), height: 1),
                const SizedBox(height: FinzoSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Members count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FinzoSpacing.xs),
                          decoration: BoxDecoration(
                            color: FinzoTheme.surfaceVariant(context),
                            borderRadius: BorderRadius.circular(FinzoRadius.sm),
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 16,
                            color: FinzoTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(width: FinzoSpacing.sm),
                        Text(
                          '${group.members.length} members',
                          style: FinzoTypography.bodySmall(
                            color: FinzoTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    // Total Amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FinzoSpacing.sm,
                        vertical: FinzoSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: FinzoColors.brandPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(FinzoRadius.sm),
                      ),
                      child: Text(
                        '₹${group.getTotalExpenses().toStringAsFixed(0)}',
                        style: FinzoTypography.labelMedium(
                          color: FinzoTheme.brandAccent(context),
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, dynamic group, SplitWiseProvider provider) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert_rounded,
        color: FinzoTheme.textSecondary(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FinzoRadius.md),
      ),
      color: FinzoTheme.surface(context),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, 
                   color: FinzoColors.error, size: 20),
              const SizedBox(width: FinzoSpacing.sm),
              Text(
                'Delete',
                style: FinzoTypography.bodyMedium(color: FinzoColors.error),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              _showDeleteDialog(context, group, provider);
            });
          },
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic group, SplitWiseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FinzoTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
        ),
        title: Text(
          'Delete Group?',
          style: FinzoTypography.titleLarge(
            color: FinzoTheme.textPrimary(context),
          ),
        ),
        content: Text(
          'This action cannot be undone. All expenses in this group will be deleted.',
          style: FinzoTypography.bodyMedium(
            color: FinzoTheme.textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: FinzoTypography.labelMedium(
                color: FinzoTheme.textSecondary(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteGroup(group.id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: FinzoTypography.labelMedium(color: FinzoColors.error),
            ),
          ),
        ],
      ),
    );
  }
}


