import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../widgets/rag_chat_widget.dart';
import 'package:finzo/l10n/app_localizations.dart';
import 'calculators/inflation_calculator.dart';
import 'calculators/investment_return_calculator.dart';
import 'calculators/retirement_calculator.dart';
import 'calculators/sip_calculator.dart';
import 'calculators/emi_calculator.dart';
import 'calculators/emergency_fund_calculator.dart';
import 'calculators/health_insurance_calculator.dart';
import 'calculators/term_insurance_calculator.dart';
import 'calculators/motor_insurance_calculator.dart';
import 'pages/financial_advisory_page.dart';
import 'pages/home_loan_page.dart';
import 'pages/vehicle_loan_page.dart';
import 'pages/itr_planning_page.dart';
import 'pages/itr_filing_page.dart';
import 'pages/tax_calculator_page.dart';
import 'pages/coming_soon_page.dart';
import 'pages/loan_dashboard_page.dart';
import 'pages/tax_dashboard_page.dart';

/// Personal Finance Manager Screen with top navigation bar
class FinanceManagerScreen extends StatefulWidget {
  const FinanceManagerScreen({super.key});

  @override
  State<FinanceManagerScreen> createState() => _FinanceManagerScreenState();
}

class _FinanceManagerScreenState extends State<FinanceManagerScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'advisory';
  String _selectedItem = 'advisory';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  // Navigation structure
  final List<_NavCategory> _navCategories = [
    _NavCategory(
      id: 'advisory',
      titleKey: 'financial_advisory',
      items: [],
    ),
    _NavCategory(
      id: 'calculators',
      titleKey: 'financial_calculators',
      items: [
        _NavItem(id: 'inflation', titleKey: 'inflation_calculator'),
        _NavItem(id: 'investment', titleKey: 'investment_return'),
        _NavItem(id: 'retirement', titleKey: 'retirement_corpus'),
        _NavItem(id: 'sip', titleKey: 'sip_calculator'),
        _NavItem(id: 'emi', titleKey: 'emi_calculator'),
        _NavItem(id: 'emergency', titleKey: 'emergency_fund'),
      ],
    ),
    _NavCategory(
      id: 'insurance',
      titleKey: 'insurance_management',
      items: [
        _NavItem(id: 'term_insurance', titleKey: 'life_term_insurance'),
        _NavItem(id: 'health_insurance', titleKey: 'health_insurance'),
        _NavItem(id: 'motor_insurance', titleKey: 'motor_insurance'),
      ],
    ),
    _NavCategory(
      id: 'loans',
      titleKey: 'loan_management',
      items: [
        _NavItem(
            id: 'loan_dashboard', titleKey: '', titleText: 'Loan Tracking'),
        _NavItem(id: 'home_loan', titleKey: 'home_loan'),
        _NavItem(id: 'vehicle_loan', titleKey: 'vehicle_loan'),
        _NavItem(id: 'gold_loan', titleKey: 'gold_loan'),
      ],
    ),
    _NavCategory(
      id: 'tax',
      titleKey: 'tax_management',
      items: [
        _NavItem(id: 'tax_dashboard', titleKey: '', titleText: 'Tax Tracking'),
        _NavItem(id: 'tax_calculator', titleKey: 'tax_calculator'),
        _NavItem(id: 'itr_planning', titleKey: 'itr_planning'),
        _NavItem(id: 'itr_filing', titleKey: 'itr_filing'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _getContentWidget() {
    switch (_selectedItem) {
      case 'advisory':
        return const FinancialAdvisoryPage();
      case 'inflation':
        return const InflationCalculator();
      case 'investment':
        return const InvestmentReturnCalculator();
      case 'retirement':
        return const RetirementCalculator();
      case 'sip':
        return const SipCalculator();
      case 'emi':
        return const EmiCalculator();
      case 'emergency':
        return const EmergencyFundCalculator();
      case 'term_insurance':
        return const TermInsuranceCalculator();
      case 'health_insurance':
        return const HealthInsuranceCalculator();
      case 'motor_insurance':
        return const MotorInsuranceCalculator();
      case 'home_loan':
        return const HomeLoanPage();
      case 'vehicle_loan':
        return const VehicleLoanPage();
      case 'gold_loan':
        return ComingSoonPage(
            title: context.l10n.t('gold_loan'),
            description: context.l10n.t('coming_soon_desc_gold'),
            icon: Icons.diamond);
      case 'itr_planning':
        return const ItrPlanningPage();
      case 'itr_filing':
        return const ItrFilingPage();
      case 'tax_calculator':
        return const TaxCalculatorPage();
      case 'loan_dashboard':
        return const LoanDashboardPage();
      case 'tax_dashboard':
        return const TaxDashboardPage();
      default:
        return const FinancialAdvisoryPage();
    }
  }

  void _goBack() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = FinzoTheme.background(context);
    final surfaceColor = FinzoTheme.surface(context);
    final l10n = context.l10n;
    
    // Brand copper/gold theme for Finance Manager
    const managerAccent = FinzoColors.brandSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FinzoTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(FinzoRadius.sm),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: FinzoTheme.textPrimary(context), size: 16),
          ),
          onPressed: _goBack,
          tooltip: context.l10n.t('back_to_menu'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FinzoColors.brandSecondary, FinzoColors.brandSecondary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(FinzoRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: managerAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.t('finance_manager'),
              style: FinzoTypography.headlineLarge(color: FinzoTheme.textPrimary(context)).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                // Premium Navigation Bar
                Container(
                  color: surfaceColor,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: _navCategories.map((category) {
                        final isSelected = _selectedCategory == category.id;
                        final title = l10n.t(category.titleKey);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: category.items.isEmpty
                              ? _buildPremiumSimpleTab(category, title, isSelected, managerAccent)
                              : _buildPremiumDropdownTab(category, isSelected, managerAccent, surfaceColor),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: FinzoTheme.divider(context),
                ),
                // Content Area with animation
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    child: SingleChildScrollView(
                      key: ValueKey<String>(_selectedItem),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: _getContentWidget(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // RAG Chat Widget
          const RagChatWidget(),
        ],
      ),
    );
  }

  Widget _buildPremiumSimpleTab(_NavCategory category, String title, bool isSelected, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedCategory = category.id;
            _selectedItem = category.id;
          });
        },
        borderRadius: BorderRadius.circular(FinzoRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(FinzoRadius.md),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            style: FinzoTypography.labelMedium().copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? accentColor : FinzoTheme.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDropdownTab(_NavCategory category, bool isSelected, Color accentColor, Color surfaceColor) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.t(category.titleKey),
      offset: const Offset(0, 50),
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FinzoRadius.md),
      ),
      elevation: 8,
      onSelected: (itemId) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = category.id;
          _selectedItem = itemId;
        });
      },
      itemBuilder: (context) => category.items.map((item) {
        final isItemSelected = _selectedItem == item.id;
        return PopupMenuItem<String>(
          value: item.id,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              item.titleText ?? l10n.t(item.titleKey),
              style: FinzoTypography.bodyMedium().copyWith(
                fontWeight: isItemSelected ? FontWeight.w600 : FontWeight.normal,
                color: isItemSelected ? accentColor : FinzoTheme.textPrimary(context),
              ),
            ),
          ),
        );
      }).toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(FinzoRadius.md),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t(category.titleKey),
              style: FinzoTypography.labelMedium().copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : FinzoTheme.textSecondary(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isSelected ? accentColor : FinzoTheme.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCategory {
  final String id;
  final String titleKey;
  final List<_NavItem> items;

  _NavCategory({required this.id, required this.titleKey, required this.items});
}

class _NavItem {
  final String id;
  final String titleKey;
  final String? titleText;

  _NavItem({required this.id, required this.titleKey, this.titleText});
}