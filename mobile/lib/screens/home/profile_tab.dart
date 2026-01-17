import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/analytics_provider.dart';
import '../auth/login_screen.dart';
import '../feature_selection_screen.dart';
import '../kyc/kyc_screen.dart';
import '../sms_settings_screen.dart';
import '../bank_statement_screen.dart';
import 'add_income_screen.dart';
import '../../widgets/auto_translated_text.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    // Show options dialog
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const AutoTranslatedText('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const AutoTranslatedText('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            if (Provider.of<AuthProvider>(context, listen: false)
                    .user
                    ?.profilePicture !=
                null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const AutoTranslatedText('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isUploadingImage = true);

        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        // Update profile with base64 image
        final success = await Provider.of<AuthProvider>(context, listen: false)
            .updateProfile(profilePicture: base64Image);

        setState(() => _isUploadingImage = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AutoTranslatedText('Profile picture updated! 📸'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AutoTranslatedText('Failed to update profile picture'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error: ${e.toString()}'), // Keeping error technical trace as Text
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _removeProfilePicture() async {
    setState(() => _isUploadingImage = true);

    // Set profilePicture to empty string to remove it
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .updateProfile(profilePicture: '');

    setState(() => _isUploadingImage = false);

    if (success) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final successColor = isDark ? AppColorsDark.success : AppColors.success;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const AutoTranslatedText('Profile picture removed'),
          backgroundColor: successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimaryColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const AutoTranslatedText('Profile'),
        backgroundColor: bgColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor =
              isDark ? AppColorsDark.primary : AppColors.primary;
          final secondaryColor =
              isDark ? AppColorsDark.secondary : AppColors.secondary;
          final textPrimaryColor =
              isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
          final textSecondaryColor =
              isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
          final cardDecoration = isDark
              ? AppDecorations.cardDecorationDark
              : AppDecorations.cardDecoration;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Profile Picture with edit button
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: _isUploadingImage
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundColor: primaryColor,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : user?.profilePicture != null &&
                                        user!.profilePicture!.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundImage: MemoryImage(
                                          base64Decode(user.profilePicture!
                                              .split(',')
                                              .last),
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        backgroundColor: primaryColor,
                                        child: Text(
                                          (user?.name.isNotEmpty ?? false)
                                              ? user!.name[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User',
                        style: AppTextStyles.heading2.copyWith(
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: AppTextStyles.body2.copyWith(
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Section
                Container(
                  decoration: cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.savings_outlined,
                        title: 'Savings Target',
                        subtitle:
                            '${user?.savingsTarget.toStringAsFixed(0) ?? '0'}% of income',
                        onTap: () => _showEditSavingsTargetDialog(context),
                        textColor: textPrimaryColor,
                        subtitleColor: textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.add_circle_outline,
                        title: 'Add Income',
                        subtitle: 'Add pocket money or income',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AddIncomeScreen()),
                          );
                        },
                        textColor: textPrimaryColor,
                        subtitleColor: textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Update your name',
                        onTap: () => _showEditNameDialog(context),
                        textColor: textPrimaryColor,
                        subtitleColor: textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.verified_user_outlined,
                        title: user?.kycStatus == 'VERIFIED'
                            ? 'KYC Verified'
                            : 'Complete KYC',
                        subtitle: user?.kycStatus == 'VERIFIED'
                            ? 'Your account is verified ✓'
                            : 'Verify your identity',
                        onTap: () {
                          if (user?.kycStatus != 'VERIFIED') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => KycScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: AutoTranslatedText(
                                    'Your account is already verified! ✅'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        textColor: textPrimaryColor,
                        subtitleColor: user?.kycStatus == 'VERIFIED'
                            ? Colors.green
                            : textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.message,
                        title: 'SMS Auto-Tracking',
                        subtitle: 'Track expenses from payment SMS',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SmsSettingsScreen()),
                          );
                        },
                        textColor: textPrimaryColor,
                        subtitleColor: textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.account_balance_wallet,
                        title: 'Bank Statement OCR',
                        subtitle: 'Upload statement to extract transactions',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const BankStatementScreen()),
                          );
                        },
                        textColor: textPrimaryColor,
                        subtitleColor: textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        icon: Icons.switch_account,
                        title: 'Switch to SmartSplit',
                        subtitle: 'Manage group expenses',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const AutoTranslatedText('Switch Feature'),
                              content: const AutoTranslatedText(
                                  'Switch to Group Expenses (SmartSplit)?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const AutoTranslatedText('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const FeatureSelectionScreen()),
                                    );
                                  },
                                  child: const AutoTranslatedText('Switch'),
                                ),
                              ],
                            ),
                          );
                        },
                        textColor: textPrimaryColor,
                        subtitleColor: textSecondaryColor,
                      ),
                      const Divider(height: 1),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          String themeName = 'System';
                          if (themeProvider.themeMode == ThemeMode.light) {
                            themeName = 'Light';
                          } else if (themeProvider.themeMode ==
                              ThemeMode.dark) {
                            themeName = 'Dark';
                          }

                          return _buildListTile(
                            icon: Icons.brightness_4_outlined,
                            title: 'Theme',
                            subtitle: '$themeName theme',
                            onTap: () =>
                                _showThemePickerDialog(context, themeProvider),
                            textColor: textPrimaryColor,
                            subtitleColor: textSecondaryColor,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const AutoTranslatedText(
                      'Logout',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for navigation bar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final textColorFinal = textColor ??
        (isDark ? AppColorsDark.textPrimary : AppColors.textPrimary);
    final subtitleColorFinal = subtitleColor ??
        (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: AutoTranslatedText(title,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: textColorFinal,
          )),
      subtitle: AutoTranslatedText(subtitle,
          style: AppTextStyles.caption.copyWith(
            color: subtitleColorFinal,
          )),
      trailing: Icon(Icons.chevron_right, color: subtitleColorFinal, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showEditSavingsTargetDialog(BuildContext context) {
    final controller = TextEditingController(
      text: Provider.of<AuthProvider>(context, listen: false)
          .user
          ?.savingsTarget
          .toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AutoTranslatedText('Set Savings Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AutoTranslatedText(
              'What percentage of your monthly income do you want to save?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: AutoTranslatedText('Savings Target'),
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            const AutoTranslatedText(
              // Moved helper text here
              'Enter a value between 0-100',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AutoTranslatedText(
                      'Example: If income is ₹5000 and target is 20%, you should spend max ₹4000',
                      style:
                          TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AutoTranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final target = double.tryParse(controller.text);
              if (target != null && target >= 0 && target <= 100) {
                // Store references before async call
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final success =
                    await authProvider.updateProfile(savingsTarget: target);

                navigator.pop();

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: AutoTranslatedText(
                          'Savings target set to ${target.toStringAsFixed(0)}%! 🎯'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: AutoTranslatedText(
                          'Failed to update savings target. Please try again.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: AutoTranslatedText(
                        'Please enter a valid percentage (0-100)'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const AutoTranslatedText('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: Provider.of<AuthProvider>(context, listen: false).user?.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AutoTranslatedText('Edit Name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            label: AutoTranslatedText('Full Name'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AutoTranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await Provider.of<AuthProvider>(context, listen: false)
                    .updateProfile(name: controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const AutoTranslatedText('Save'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AutoTranslatedText('Logout'),
        content: const AutoTranslatedText('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AutoTranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear all providers
              Provider.of<ExpenseProvider>(context, listen: false).clear();
              Provider.of<IncomeProvider>(context, listen: false).clear();
              Provider.of<AnalyticsProvider>(context, listen: false).clear();
              await Provider.of<AuthProvider>(context, listen: false).logout();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const AutoTranslatedText('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showThemePickerDialog(
      BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AutoTranslatedText('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const AutoTranslatedText('Light Theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const AutoTranslatedText('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const AutoTranslatedText('System Default'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
