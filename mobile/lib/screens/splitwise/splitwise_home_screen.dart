import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/splitwise_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../home/home_screen.dart';
import '../feature_selection_screen.dart';
import 'splitwise_groups_tab.dart';
import 'splitwise_friends_tab.dart';
import 'splitwise_activity_tab.dart';
import 'splitwise_settings_tab.dart';
import '../../widgets/auto_translated_text.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColorsDark.background
        : const Color.fromARGB(255, 228, 228, 228);
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final secondaryColor =
        isDark ? AppColorsDark.secondary : AppColors.secondary;
    final textPrimaryColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FeatureSelectionScreen()),
          ),
          tooltip: 'Back to Menu',
        ),
        title: Text(
          'SmartSplit',
          style: AppTextStyles.heading2.copyWith(color: textPrimaryColor),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: primaryColor,
            ),
            onPressed: () {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(Icons.person_add, color: primaryColor),
            onPressed: _showJoinGroupDialog,
            tooltip: 'Join Group',
          ),
          IconButton(
            icon: Icon(Icons.wallet, color: primaryColor),
            tooltip: 'Switch to Personal Finance',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomAppBar(
        color: surfaceColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: _buildNavItem(
                  0,
                  Icons.groups_outlined,
                  Icons.groups,
                  'Groups',
                  primaryColor,
                  textSecondaryColor,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: _buildNavItem(
                  1,
                  Icons.person_outline,
                  Icons.person,
                  'Friends',
                  primaryColor,
                  textSecondaryColor,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: _buildNavItem(
                  2,
                  Icons.history_outlined,
                  Icons.history,
                  'Activity',
                  primaryColor,
                  textSecondaryColor,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildNavItem(
                    3,
                    Icons.settings_outlined,
                    Icons.settings,
                    'Settings',
                    primaryColor,
                    textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 16),
        child: FloatingActionButton(
          backgroundColor: secondaryColor,
          elevation: 8,
          onPressed: () {
            // Navigate to add group expense or create group
            if (_currentIndex == 0) {
              // Show group creation dialog
              _showCreateGroupDialog();
            }
          },
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    Color primaryColor,
    Color textSecondaryColor,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? primaryColor : textSecondaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          AutoTranslatedText(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? primaryColor : textSecondaryColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AutoTranslatedText('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                label: const AutoTranslatedText('Group Name'), // Using label widget instead of labelText string
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                label: const AutoTranslatedText('Description'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AutoTranslatedText('Cancel'),
          ),
          TextButton(
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
                    const SnackBar(
                        content: AutoTranslatedText('Group created successfully!')),
                  );
                } else if (mounted && provider.errorMessage != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${provider.errorMessage}')), // Error message might be technical, keep as Text or handle carefully? keeping as Text for safety, or simple AutoTranslatedText if safe.
                  );
                }
              }
            },
            child: const AutoTranslatedText('Create'),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;

        return AlertDialog(
          backgroundColor: surfaceColor,
          title: const AutoTranslatedText('Join Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoTranslatedText(
                  'Enter the 6-character invite code from the group creator',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: inviteCodeController,
                  decoration: InputDecoration(
                    label: const AutoTranslatedText('Invite Code'),
                    hintText: 'e.g., ABC123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
              child: const AutoTranslatedText('Cancel'),
            ),
            TextButton(
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
                      const SnackBar(
                        content: AutoTranslatedText('Joined group successfully!'),
                      ),
                    );
                  } else if (mounted && provider.errorMessage != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${provider.errorMessage}'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: AutoTranslatedText('Code must be exactly 6 characters'),
                    ),
                  );
                }
              },
              child: const AutoTranslatedText('Join'),
            ),
          ],
        );
      },
    );
  }
}
