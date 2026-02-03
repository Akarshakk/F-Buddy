import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/theme_provider.dart';

class SplitwiseSettingsTab extends StatelessWidget {
  const SplitwiseSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      body: ListView(
        padding: const EdgeInsets.all(FinzoSpacing.md),
        children: [
          // Theme Settings
          _buildSectionCard(
            context,
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Column(
                  children: [
                    _buildThemeOption(
                      context,
                      'Light',
                      Icons.light_mode_rounded,
                      ThemeMode.light,
                      themeProvider.themeMode == ThemeMode.light,
                      () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(height: FinzoSpacing.sm),
                    _buildThemeOption(
                      context,
                      'Dark',
                      Icons.dark_mode_rounded,
                      ThemeMode.dark,
                      themeProvider.themeMode == ThemeMode.dark,
                      () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                    const SizedBox(height: FinzoSpacing.sm),
                    _buildThemeOption(
                      context,
                      'System',
                      Icons.auto_awesome_rounded,
                      ThemeMode.system,
                      themeProvider.themeMode == ThemeMode.system,
                      () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: FinzoSpacing.md),

          // Feature Selection
          _buildSectionCard(
            context,
            title: 'Features',
            icon: Icons.apps_rounded,
            child: _buildSettingsTile(
              context,
              icon: Icons.swap_horiz_rounded,
              title: 'Switch Feature',
              subtitle: 'Switch between Personal Finance and Group Expenses',
              onTap: () => _showSwitchDialog(context),
            ),
          ),
          const SizedBox(height: FinzoSpacing.md),

          // About
          _buildSectionCard(
            context,
            title: 'About',
            icon: Icons.info_outline_rounded,
            child: _buildSettingsTile(
              context,
              icon: Icons.verified_rounded,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: BorderRadius.circular(FinzoRadius.lg),
        boxShadow: FinzoShadows.small,
        border: Border.all(color: FinzoTheme.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(FinzoSpacing.sm),
                  decoration: BoxDecoration(
                    color: FinzoTheme.brandAccent(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(FinzoRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: FinzoTheme.brandAccent(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: FinzoSpacing.md),
                Text(
                  title,
                  style: FinzoTypography.titleMedium(
                    color: FinzoTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: FinzoTheme.divider(context), height: 1),
          Padding(
            padding: const EdgeInsets.all(FinzoSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinzoRadius.md),
        child: Container(
          padding: const EdgeInsets.all(FinzoSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? FinzoTheme.brandAccent(context).withOpacity(0.1)
                : FinzoTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(FinzoRadius.md),
            border: Border.all(
              color: isSelected
                  ? FinzoTheme.brandAccent(context)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? FinzoTheme.brandAccent(context)
                    : FinzoTheme.textSecondary(context),
                size: 22,
              ),
              const SizedBox(width: FinzoSpacing.md),
              Text(
                title,
                style: FinzoTypography.bodyMedium(
                  color: isSelected
                      ? FinzoTheme.brandAccent(context)
                      : FinzoTheme.textSecondary(context),
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: FinzoTheme.brandAccent(context),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FinzoRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FinzoSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(FinzoSpacing.sm),
                decoration: BoxDecoration(
                  color: FinzoTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(FinzoRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: FinzoTheme.brandAccent(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: FinzoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FinzoTypography.bodyMedium(
                        color: FinzoTheme.textPrimary(context),
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: FinzoTypography.bodySmall(
                        color: FinzoTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: FinzoTheme.textSecondary(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FinzoTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FinzoRadius.lg),
        ),
        title: Text(
          'Switch Feature',
          style: FinzoTypography.titleLarge(
            color: FinzoTheme.textPrimary(context),
          ),
        ),
        content: Text(
          'Go back to feature selection?',
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
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: Text(
              'Switch',
              style: FinzoTypography.labelMedium(
                color: FinzoTheme.brandAccent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


