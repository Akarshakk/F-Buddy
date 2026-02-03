import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/splitwise_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'splitwise_groups_tab.dart';
import 'splitwise_friends_tab.dart';
import 'splitwise_activity_tab.dart';
import 'splitwise_settings_tab.dart';

class SplitwiseHomeScreen extends StatefulWidget {
  const SplitwiseHomeScreen({super.key});

  @override
  State<SplitwiseHomeScreen> createState() => _SplitwiseHomeScreenState();
}

class _SplitwiseHomeScreenState extends State<SplitwiseHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const SplitwiseGroupsTab(),
    const SplitwisFriendsTab(),
    const SplitwiseActivityTab(),
    const SplitwiseSettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final splitwiseProvider =
          Provider.of<SplitWiseProvider>(context, listen: false);
      splitwiseProvider.fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      appBar: AppBar(
        backgroundColor: FinzoTheme.background(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: FinzoTheme.textPrimary(context)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
          tooltip: 'Back to Menu',
        ),
        title: Text(
          'SmartSplit',
          style: FinzoTypography.headlineLarge(
            color: FinzoTheme.textPrimary(context),
          ).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              FinzoTheme.isDark(context) ? Icons.light_mode : Icons.dark_mode,
              color: FinzoTheme.textPrimary(context),
            ),
            onPressed: () {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: FinzoTheme.textPrimary(context)),
            onPressed: _showJoinGroupDialog,
            tooltip: 'Join Group',
          ),
          IconButton(
            icon: Icon(Icons.account_balance_wallet_outlined, color: FinzoTheme.textPrimary(context)),
            tooltip: 'Switch to Personal Finance',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/personal-finance');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: FinzoTheme.surface(context),
          border: Border(
            top: BorderSide(
              color: FinzoTheme.divider(context),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.groups_outlined, Icons.groups, 'Groups'),
                _buildNavItem(1, Icons.person_outline, Icons.person, 'Friends'),
                _buildNavItem(2, Icons.history_outlined, Icons.history, 'Activity'),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: FinzoTheme.brandAccent(context),
        elevation: 4,
        onPressed: () {
          if (_currentIndex == 0) {
            _showCreateGroupDialog();
          }
        },
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.md, vertical: FinzoSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected 
                  ? FinzoTheme.textPrimary(context) 
                  : FinzoTheme.textSecondary(context),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FinzoTypography.labelSmall().copyWith(
                color: isSelected 
                    ? FinzoTheme.textPrimary(context) 
                    : FinzoTheme.textSecondary(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FinzoTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
        ),
        title: Text(
          'Create Group',
          style: FinzoTypography.headlineSmall(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: FinzoTypography.bodyMedium(),
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: FinzoTypography.bodySmall().copyWith(
                  color: FinzoTheme.textSecondary(context),
                ),
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
            const SizedBox(height: FinzoSpacing.md),
            TextField(
              controller: descriptionController,
              style: FinzoTypography.bodyMedium(),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: FinzoTypography.bodySmall().copyWith(
                  color: FinzoTheme.textSecondary(context),
                ),
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
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: FinzoTypography.labelMedium().copyWith(
                color: FinzoTheme.textSecondary(context),
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final provider =
                    Provider.of<SplitWiseProvider>(context, listen: false);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                final success = await provider.createGroup(
                  name: nameController.text,
                  description: descriptionController.text,
                  memberEmails: [],
                  userId: authProvider.user?.id ?? 'user_123',
                  userName: authProvider.user?.name ?? 'User',
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Group created successfully!'),
                      backgroundColor: FinzoColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                      ),
                    ),
                  );
                } else if (mounted && provider.errorMessage != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${provider.errorMessage}'),
                      backgroundColor: FinzoColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                      ),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: FinzoTheme.brandAccent(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FinzoRadius.md),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final inviteCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FinzoTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FinzoRadius.lg),
          ),
          title: Text(
            'Join Group',
            style: FinzoTypography.headlineSmall(),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the 6-character invite code from the group creator',
                  style: FinzoTypography.bodySmall().copyWith(
                    color: FinzoTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: FinzoSpacing.md),
                TextField(
                  controller: inviteCodeController,
                  style: FinzoTypography.bodyMedium(),
                  decoration: InputDecoration(
                    labelText: 'Invite Code',
                    labelStyle: FinzoTypography.bodySmall().copyWith(
                      color: FinzoTheme.textSecondary(context),
                    ),
                    hintText: 'e.g., ABC123',
                    hintStyle: FinzoTypography.bodySmall().copyWith(
                      color: FinzoTheme.textTertiary(context),
                    ),
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
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: FinzoTypography.labelMedium().copyWith(
                  color: FinzoTheme.textSecondary(context),
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (inviteCodeController.text.length == 6) {
                  final provider =
                      Provider.of<SplitWiseProvider>(context, listen: false);
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);

                  final success = await provider.joinGroupByCode(
                    inviteCode: inviteCodeController.text.toUpperCase(),
                    userId: authProvider.user?.id ?? 'user_123',
                    userName: authProvider.user?.name ?? 'User',
                    userEmail: authProvider.user?.email ?? 'user@example.com',
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Joined group successfully!'),
                        backgroundColor: FinzoColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                        ),
                      ),
                    );
                  } else if (mounted && provider.errorMessage != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${provider.errorMessage}'),
                        backgroundColor: FinzoColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Code must be exactly 6 characters'),
                      backgroundColor: FinzoColors.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FinzoRadius.md),
                      ),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: FinzoTheme.brandAccent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FinzoRadius.md),
                ),
              ),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }
}