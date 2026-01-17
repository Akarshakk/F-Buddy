import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../screens/feature_selection_screen.dart';
import '../../widgets/rag_chat_widget.dart';
import '../../providers/language_provider.dart';
import 'package:f_buddy/l10n/app_localizations.dart';
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
import 'pages/coming_soon_page.dart';

/// Personal Finance Manager Screen with top navigation bar
class FinanceManagerScreen extends StatefulWidget {
  const FinanceManagerScreen({super.key});

  @override
  State<FinanceManagerScreen> createState() => _FinanceManagerScreenState();
}

class _FinanceManagerScreenState extends State<FinanceManagerScreen> {
  String _selectedCategory = 'advisory';
  String _selectedItem = 'advisory';

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
        _NavItem(id: 'home_loan', titleKey: 'home_loan'),
        _NavItem(id: 'vehicle_loan', titleKey: 'vehicle_loan'),
        _NavItem(id: 'gold_loan', titleKey: 'gold_loan'),
      ],
    ),
    _NavCategory(
      id: 'tax',
      titleKey: 'tax_management',
      items: [
        _NavItem(id: 'itr_planning', titleKey: 'itr_planning'),
        _NavItem(id: 'itr_filing', titleKey: 'itr_filing'),
      ],
    ),
  ];

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
      default:
        return const FinancialAdvisoryPage();
    }
  }

  void _goBack() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FeatureSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : const Color(0xFFF5F5F5);
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final languageProvider = context.watch<LanguageProvider>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: _goBack,
          tooltip: context.l10n.t('back_to_menu'),
        ),
        title: Text(
          l10n.t('finance_manager'),
          style: AppTextStyles.heading2.copyWith(color: primaryColor),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: context.l10n.t('language'),
            initialValue: languageProvider.language,
            icon: Row(
              children: [
                const Icon(Icons.translate),
                const SizedBox(width: 4),
                Text(
                  languageProvider.displayName,
                  style: TextStyle(
                      color: primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            onSelected: (lang) {
              languageProvider.setLanguage(lang);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: AppLanguage.english, child: Text('English')),
              PopupMenuItem(
                  value: AppLanguage.hindi, child: Text('हिंदी (Hindi)')),
              PopupMenuItem(
                  value: AppLanguage.marathi, child: Text('मराठी (Marathi)')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top Navigation Bar with Tabs
              Container(
                color: surfaceColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: _navCategories.map((category) {
                      final isSelected = _selectedCategory == category.id;
                      final title = l10n.t(category.titleKey);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: category.items.isEmpty
                            ? _buildSimpleTab(category, title, isSelected,
                                primaryColor, isDark)
                            : _buildDropdownTab(category, isSelected,
                                primaryColor, isDark, surfaceColor),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: _getContentWidget(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // RAG Chat Widget - Floating in bottom right corner
          const RagChatWidget(),
        ],
      ),
    );
  }

  Widget _buildSimpleTab(_NavCategory category, String title, bool isSelected,
      Color primaryColor, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category.id;
          _selectedItem = category.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTab(_NavCategory category, bool isSelected,
      Color primaryColor, bool isDark, Color surfaceColor) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.t(category.titleKey),
      offset: const Offset(0, 50),
      color: surfaceColor,
      onSelected: (itemId) {
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
              l10n.t(item.titleKey),
              style: TextStyle(
                fontWeight:
                    isItemSelected ? FontWeight.bold : FontWeight.normal,
                color: isItemSelected ? primaryColor : null,
              ),
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.t(category.titleKey),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white70 : Colors.black54),
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

  _NavItem({required this.id, required this.titleKey});
}
