import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class FeatureSelectionScreen extends StatelessWidget {
  const FeatureSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FinzoSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: FinzoSpacing.xl),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: FinzoTypography.bodyMedium(
                            color: FinzoTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: FinzoSpacing.xs),
                        Text(
                          user?.name ?? 'User',
                          style: FinzoTypography.headlineMedium(
                            color: FinzoTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _ThemeToggleButton(),
                        const SizedBox(width: FinzoSpacing.sm),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                FinzoTheme.brandPrimary(context),
                                FinzoTheme.brandSecondary(context),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(FinzoRadius.full),
                          ),
                          child: Center(
                            child: Text(
                              (user?.name ?? 'U')[0].toUpperCase(),
                              style: FinzoTypography.titleMedium(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: FinzoSpacing.xxxl),
                
                // Title
                Text(
                  'Choose your\nfinance tracker',
                  style: FinzoTypography.displaySmall(
                    color: FinzoTheme.textPrimary(context),
                  ),
                ),
                
                const SizedBox(height: FinzoSpacing.md),
                
                Text(
                  'Select a feature to manage your finances effectively',
                  style: FinzoTypography.bodyLarge(
                    color: FinzoTheme.textSecondary(context),
                  ),
                ),
                
                const SizedBox(height: FinzoSpacing.xxxl),
                
                // Feature Cards
                _FeatureCard(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  title: 'Personal Finance',
                  description: 'Track expenses, income, and manage your personal budget with ease',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/personal-finance'),
                ),
                
                const SizedBox(height: FinzoSpacing.lg),
                
                _FeatureCard(
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  title: 'Group Expenses',
                  description: 'Split bills with friends, track shared expenses, and settle up easily',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/group-finance'),
                ),
                
                const SizedBox(height: FinzoSpacing.lg),
                
                _FeatureCard(
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up,
                  title: 'Finance Manager',
                  description: 'Plan investments, calculate returns, and manage your financial future',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/finance-manager'),
                ),
                
                const SizedBox(height: FinzoSpacing.xxxl),
                
                // Quick tip
                Container(
                  padding: const EdgeInsets.all(FinzoSpacing.lg),
                  decoration: BoxDecoration(
                    color: FinzoTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(FinzoRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(FinzoSpacing.sm),
                        decoration: BoxDecoration(
                          color: FinzoTheme.brandAccent(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(FinzoRadius.md),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
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
                              'Quick Tip',
                              style: FinzoTypography.labelLarge(
                                color: FinzoTheme.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: FinzoSpacing.xs),
                            Text(
                              'Swipe between features or use the navigation bar to switch.',
                              style: FinzoTypography.bodySmall(
                                color: FinzoTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: FinzoSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: FinzoTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(FinzoRadius.full),
          border: Border.all(
            color: FinzoTheme.border(context),
            width: 1,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              key: ValueKey(isDark),
              color: FinzoTheme.textPrimary(context),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String description;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isPressed || _isHovered;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(isActive ? 0.98 : 1.0),
          decoration: BoxDecoration(
            color: FinzoTheme.surface(context),
            borderRadius: BorderRadius.circular(FinzoRadius.xl),
            border: Border.all(
              color: isActive 
                  ? widget.gradient.colors.first 
                  : FinzoTheme.border(context),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? FinzoShadows.medium : FinzoShadows.small,
          ),
          child: Padding(
            padding: const EdgeInsets.all(FinzoSpacing.xl),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(FinzoRadius.lg),
                  ),
                  child: Center(
                    child: Icon(
                      isActive ? widget.activeIcon : widget.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                
                const SizedBox(width: FinzoSpacing.lg),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: FinzoTypography.titleLarge(
                          color: FinzoTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: FinzoSpacing.xs),
                      Text(
                        widget.description,
                        style: FinzoTypography.bodyMedium(
                          color: FinzoTheme.textSecondary(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: FinzoSpacing.md),
                
                // Arrow icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? widget.gradient.colors.first.withValues(alpha: 0.1)
                        : FinzoTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(FinzoRadius.full),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: isActive 
                          ? widget.gradient.colors.first
                          : FinzoTheme.textSecondary(context),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


