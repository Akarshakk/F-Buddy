import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../config/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'package:finzo/l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'splitwise/splitwise_home_screen.dart';
import '../features/financial_calculator/finance_manager_screen.dart';
import 'markets/markets_lab_home_screen.dart';

/// Premium Feature Selection Screen - Spotify/Instagram inspired
class FeatureSelectionScreen extends StatefulWidget {
  const FeatureSelectionScreen({super.key});

  @override
  State<FeatureSelectionScreen> createState() => _FeatureSelectionScreenState();
}

class _FeatureSelectionScreenState extends State<FeatureSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollController.offset);
      });

    // Staggered entrance animation
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardsController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = FinzoTheme.isDark(context);
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: FinzoTheme.background(context),
      body: Stack(
        children: [
          // Subtle gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF1A1A2E).withOpacity(0.3),
                          FinzoTheme.background(context),
                        ]
                      : [
                          const Color(0xFFD4A574).withOpacity(0.08),
                          FinzoTheme.background(context),
                        ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
          
          // Decorative circles (Spotify-style)
          Positioned(
            top: -100 + (_scrollOffset * 0.3),
            right: -80,
            child: _buildDecorativeCircle(200, isDark),
          ),
          Positioned(
            top: 200 + (_scrollOffset * 0.2),
            left: -60,
            child: _buildDecorativeCircle(120, isDark),
          ),
          
          // Main content
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Animated Header
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _headerController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: _buildHeader(context, user),
                    ),
                  ),
                ),
                
                // Title Section
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerController,
                    child: _buildTitleSection(context),
                  ),
                ),
                
                // Feature Cards with staggered animation
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final features = _getFeatures(context);
                        if (index >= features.length) return null;
                        
                        return _AnimatedFeatureCard(
                          feature: features[index],
                          index: index,
                          controller: _cardsController,
                        );
                      },
                      childCount: 4,
                    ),
                  ),
                ),
                
                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isDark
              ? [
                  const Color(0xFFD4A574).withOpacity(0.1),
                  Colors.transparent,
                ]
              : [
                  const Color(0xFFD4A574).withOpacity(0.15),
                  Colors.transparent,
                ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.t('welcome_back'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FinzoTheme.textSecondary(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? 'User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: FinzoTheme.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            children: [
              _PremiumIconButton(
                icon: Icons.translate_rounded,
                onTap: () => _showLanguageSheet(context),
              ),
              const SizedBox(width: 12),
              _PremiumIconButton(
                icon: FinzoTheme.isDark(context)
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
              ),
              const SizedBox(width: 12),
              // Logout button
              _PremiumIconButton(
                icon: Icons.logout_rounded,
                onTap: () => _showLogoutConfirmation(context),
                isDestructive: true,
              ),
              const SizedBox(width: 12),
              _buildProfileAvatar(context, user),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, user) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4A574), Color(0xFFB8956E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          (user?.name ?? 'U')[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('choose_your_feature'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: FinzoTheme.textPrimary(context),
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.t('select_how_to_manage'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: FinzoTheme.textSecondary(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  List<_FeatureData> _getFeatures(BuildContext context) {
    return [
      _FeatureData(
        icon: Icons.account_balance_wallet_rounded,
        title: context.l10n.t('personal_finance'),
        subtitle: context.l10n.t('personal_finance_desc'),
        gradient: const [Color(0xFF1A1A2E), Color(0xFF16213E)],
        accentColor: const Color(0xFFD4A574),
        route: const HomeScreen(),
      ),
      _FeatureData(
        icon: Icons.group_rounded,
        title: context.l10n.t('group_finance'),
        subtitle: context.l10n.t('group_finance_desc'),
        gradient: const [Color(0xFF4A3728), Color(0xFF2D221A)],
        accentColor: const Color(0xFFE8C5A0),
        route: const SplitwiseHomeScreen(),
      ),
      _FeatureData(
        icon: Icons.calculate_rounded,
        title: context.l10n.t('finance_manager_title'),
        subtitle: context.l10n.t('finance_manager_desc'),
        gradient: const [Color(0xFF0F3460), Color(0xFF16213E)],
        accentColor: const Color(0xFF7EC8E3),
        route: const FinanceManagerScreen(),
      ),
      _FeatureData(
        icon: Icons.candlestick_chart_rounded,
        title: context.l10n.t('markets_lab'),
        subtitle: context.l10n.t('markets_lab_desc'),
        gradient: const [Color(0xFF2D1F1F), Color(0xFF1A1212)],
        accentColor: const Color(0xFFE57373),
        route: const MarketsLabHomeScreen(),
      ),
    ];
  }

  void _showLanguageSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageBottomSheet(),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FinzoTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: FinzoTheme.textPrimary(context),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: TextStyle(
            fontSize: 15,
            color: FinzoTheme.textSecondary(context),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: FinzoTheme.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PremiumIconButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<_PremiumIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FinzoTheme.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: FinzoTheme.border(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isDestructive 
                  ? Colors.red 
                  : FinzoTheme.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final Widget route;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.route,
  });
}

class _AnimatedFeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final int index;
  final AnimationController controller;

  const _AnimatedFeatureCard({
    required this.feature,
    required this.index,
    required this.controller,
  });

  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tapAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );

    // Staggered entrance
    final delay = widget.index * 0.15;
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(delay, math.min(delay + 0.4, 1.0), curve: Curves.easeOutCubic),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(delay, math.min(delay + 0.4, 1.0), curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTapDown: (_) => _tapController.forward(),
                onTapUp: (_) {
                  _tapController.reverse();
                  HapticFeedback.mediumImpact();
                  Navigator.pushReplacement(
                    context,
                    _createRoute(widget.feature.route),
                  );
                },
                onTapCancel: () => _tapController.reverse(),
                child: AnimatedBuilder(
                  animation: _tapAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _tapAnimation.value,
                    child: _buildCard(context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = FinzoTheme.isDark(context);
    
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.feature.gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.feature.gradient[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.feature.icon,
                    color: widget.feature.accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.feature.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.feature.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class _LanguageBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = FinzoTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: FinzoTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: FinzoTheme.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  context.l10n.t('change_language'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FinzoTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _LanguageOption(
            language: AppLanguage.english,
            title: 'English',
            subtitle: 'English',
            isSelected: languageProvider.language == AppLanguage.english,
            onTap: () {
              languageProvider.setLanguage(AppLanguage.english);
              Navigator.pop(context);
            },
          ),
          _LanguageOption(
            language: AppLanguage.hindi,
            title: 'हिंदी',
            subtitle: 'Hindi',
            isSelected: languageProvider.language == AppLanguage.hindi,
            onTap: () {
              languageProvider.setLanguage(AppLanguage.hindi);
              Navigator.pop(context);
            },
          ),
          _LanguageOption(
            language: AppLanguage.marathi,
            title: 'मराठी',
            subtitle: 'Marathi',
            isSelected: languageProvider.language == AppLanguage.marathi,
            onTap: () {
              languageProvider.setLanguage(AppLanguage.marathi);
              Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final AppLanguage language;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4A574).withOpacity(0.1)
              : FinzoTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4A574)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: FinzoTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: FinzoTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A574),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
