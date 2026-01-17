import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/auto_translated_text.dart';

/// Comprehensive Tax Calculator for FY 2025-26
/// Calculates taxes under both Old and New regimes
class TaxCalculatorPage extends StatefulWidget {
  const TaxCalculatorPage({super.key});

  @override
  State<TaxCalculatorPage> createState() => _TaxCalculatorPageState();
}

class _TaxCalculatorPageState extends State<TaxCalculatorPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // --- Personal Details ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // --- Compliance Questions ---
  bool _panAadhaarLinked = true;
  bool _bankPreValidated = true;
  String _residentialStatus = 'Resident';
  String _assessmentYear = 'AY 2026-27 (FY 2025-26)';

  // --- Employment & Property ---
  bool _multipleEmployers = false;
  bool _multipleHouseProperties = false;
  bool _soldAssetsCapitalGains = false;
  bool _hasDividendAgriIncome = false;
  bool _hasFreelanceIncome = false;
  bool _form16MatchesAIS = true;
  bool _tdsReflectedIn26AS = true;
  bool _highValueTransactions = false;

  // --- Income Inputs ---
  final _salaryController = TextEditingController();
  final _interestIncomeController = TextEditingController();
  final _otherIncomeController = TextEditingController();
  final _rentalIncomeController = TextEditingController();
  final _capitalGainsController = TextEditingController();
  final _freelanceIncomeController = TextEditingController();

  // --- Deduction Inputs (Old Regime) ---
  final _section80CController = TextEditingController();
  final _section80DController = TextEditingController();
  final _section80CCD1BController = TextEditingController();
  final _section24bController = TextEditingController();
  final _section80EController = TextEditingController();
  final _section80GController = TextEditingController();

  // --- HRA Inputs ---
  bool _livesInRentedHouse = false;
  bool _isMetroCity = false;
  final _basicSalaryController = TextEditingController();
  final _hraReceivedController = TextEditingController();
  final _rentPaidController = TextEditingController();

  // --- Results ---
  Map<String, dynamic>? _taxResults;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _interestIncomeController.dispose();
    _otherIncomeController.dispose();
    _rentalIncomeController.dispose();
    _capitalGainsController.dispose();
    _freelanceIncomeController.dispose();
    _section80CController.dispose();
    _section80DController.dispose();
    _section80CCD1BController.dispose();
    _section24bController.dispose();
    _section80EController.dispose();
    _section80GController.dispose();
    _basicSalaryController.dispose();
    _hraReceivedController.dispose();
    _rentPaidController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateTax();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  double _parseDouble(String text) {
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  void _calculateTax() {
    // Gather all inputs
    final salary = _parseDouble(_salaryController.text);
    final interestIncome = _parseDouble(_interestIncomeController.text);
    final otherIncome = _parseDouble(_otherIncomeController.text);
    final rentalIncome = _parseDouble(_rentalIncomeController.text);
    final capitalGains = _parseDouble(_capitalGainsController.text);
    final freelanceIncome = _parseDouble(_freelanceIncomeController.text);

    final grossIncome = salary +
        interestIncome +
        otherIncome +
        rentalIncome +
        capitalGains +
        freelanceIncome;

    // Deductions
    final section80C =
        _parseDouble(_section80CController.text).clamp(0, 150000);
    final section80D = _parseDouble(_section80DController.text);
    final section80CCD1B =
        _parseDouble(_section80CCD1BController.text).clamp(0, 50000);
    final section24b =
        _parseDouble(_section24bController.text).clamp(0, 200000);
    final section80E = _parseDouble(_section80EController.text);
    final section80G = _parseDouble(_section80GController.text);

    // HRA Exemption calculation
    double hraExemption = 0;
    if (_livesInRentedHouse) {
      final basicSalary = _parseDouble(_basicSalaryController.text);
      final hraReceived =
          _parseDouble(_hraReceivedController.text) * 12; // Yearly
      final rentPaid = _parseDouble(_rentPaidController.text) * 12; // Yearly

      if (basicSalary > 0 && rentPaid > 0) {
        final basicYearly = basicSalary * 12;
        final tenPercentBasic = basicYearly * 0.1;
        final hraPercent = _isMetroCity ? 0.5 : 0.4;

        // HRA exemption is minimum of:
        // 1. Actual HRA received
        // 2. Rent paid - 10% of Basic
        // 3. 50% (Metro) or 40% (Non-Metro) of Basic
        hraExemption = [
          hraReceived,
          (rentPaid - tenPercentBasic).clamp(0.0, double.infinity).toDouble(),
          basicYearly * hraPercent,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final totalDeductions = section80C +
        section80D +
        section80CCD1B +
        section24b +
        section80E +
        section80G +
        hraExemption;

    // --- NEW REGIME CALCULATION (FY 2025-26) ---
    final newRegimeStandardDeduction = 75000.0;
    final newRegimeTaxableIncome = (grossIncome - newRegimeStandardDeduction)
        .clamp(0.0, double.infinity)
        .toDouble();

    double newRegimeTax = _calculateNewRegimeTax(newRegimeTaxableIncome);

    // Section 87A Rebate for New Regime (if taxable income <= 12L)
    if (newRegimeTaxableIncome <= 1200000) {
      newRegimeTax = 0;
    }

    // Add Cess (4%)
    final newRegimeCess = newRegimeTax * 0.04;
    final newRegimeTotalTax = newRegimeTax + newRegimeCess;

    // --- OLD REGIME CALCULATION ---
    final oldRegimeStandardDeduction = 50000.0;
    final oldRegimeTaxableIncome =
        (grossIncome - oldRegimeStandardDeduction - totalDeductions)
            .clamp(0.0, double.infinity)
            .toDouble();

    double oldRegimeTax = _calculateOldRegimeTax(oldRegimeTaxableIncome);

    // Section 87A Rebate for Old Regime (if taxable income <= 5L)
    if (oldRegimeTaxableIncome <= 500000) {
      oldRegimeTax = 0;
    }

    // Add Cess (4%)
    final oldRegimeCess = oldRegimeTax * 0.04;
    final oldRegimeTotalTax = oldRegimeTax + oldRegimeCess;

    // Determine better regime
    final betterRegime =
        newRegimeTotalTax <= oldRegimeTotalTax ? 'New Regime' : 'Old Regime';
    final savings = (newRegimeTotalTax - oldRegimeTotalTax).abs();

    setState(() {
      _taxResults = {
        'grossIncome': grossIncome,
        'totalDeductions': totalDeductions,
        'hraExemption': hraExemption,
        'newRegime': {
          'standardDeduction': newRegimeStandardDeduction,
          'taxableIncome': newRegimeTaxableIncome,
          'tax': newRegimeTax,
          'cess': newRegimeCess,
          'totalTax': newRegimeTotalTax,
        },
        'oldRegime': {
          'standardDeduction': oldRegimeStandardDeduction,
          'deductions': totalDeductions,
          'taxableIncome': oldRegimeTaxableIncome,
          'tax': oldRegimeTax,
          'cess': oldRegimeCess,
          'totalTax': oldRegimeTotalTax,
        },
        'betterRegime': betterRegime,
        'savings': savings,
      };
      _currentStep = _totalSteps - 1;
    });

    _pageController.animateToPage(
      _totalSteps - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Save tax data if email matches logged-in user
    _saveTaxDataIfEmailMatches(
      grossIncome: grossIncome,
      section80C: section80C.toDouble(),
      section80D: section80D,
      section80CCD1B: section80CCD1B.toDouble(),
      section24b: section24b.toDouble(),
      section80E: section80E,
      section80G: section80G,
      totalDeductions: totalDeductions.toDouble(),
      hraExemption: hraExemption,
      newRegimeTotalTax: newRegimeTotalTax,
      oldRegimeTotalTax: oldRegimeTotalTax,
      betterRegime: betterRegime,
      savings: savings,
      salary: salary,
      interestIncome: interestIncome,
      rentalIncome: rentalIncome,
      capitalGains: capitalGains,
      freelanceIncome: freelanceIncome,
      otherIncome: otherIncome,
    );
  }

  Future<void> _saveTaxDataIfEmailMatches({
    required double grossIncome,
    required double section80C,
    required double section80D,
    required double section80CCD1B,
    required double section24b,
    required double section80E,
    required double section80G,
    required double totalDeductions,
    required double hraExemption,
    required double newRegimeTotalTax,
    required double oldRegimeTotalTax,
    required String betterRegime,
    required double savings,
    required double salary,
    required double interestIncome,
    required double rentalIncome,
    required double capitalGains,
    required double freelanceIncome,
    required double otherIncome,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) return;

      // Check if the entered email matches the logged-in user's email
      final enteredEmail = _emailController.text.trim().toLowerCase();
      final userEmail = user.email.toLowerCase();

      if (enteredEmail != userEmail) {
        print('[TaxCalculator] Email mismatch - not saving to database');
        return;
      }

      print('[TaxCalculator] Email matches - saving to database');

      final taxData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'assessmentYear': _assessmentYear,
        'residentialStatus': _residentialStatus,

        // Compliance
        'panAadhaarLinked': _panAadhaarLinked,
        'bankPreValidated': _bankPreValidated,
        'multipleEmployers': _multipleEmployers,
        'multipleHouseProperties': _multipleHouseProperties,
        'soldAssetsCapitalGains': _soldAssetsCapitalGains,
        'hasDividendAgriIncome': _hasDividendAgriIncome,
        'hasFreelanceIncome': _hasFreelanceIncome,

        // Income
        'salaryIncome': salary,
        'interestIncome': interestIncome,
        'rentalIncome': rentalIncome,
        'capitalGains': capitalGains,
        'freelanceIncome': freelanceIncome,
        'otherIncome': otherIncome,
        'grossIncome': grossIncome,

        // Deductions
        'section80C': section80C,
        'section80D': section80D,
        'section80CCD1B': section80CCD1B,
        'section24b': section24b,
        'section80E': section80E,
        'section80G': section80G,
        'totalDeductions': totalDeductions,

        // HRA
        'livesInRentedHouse': _livesInRentedHouse,
        'isMetroCity': _isMetroCity,
        'basicSalary': _parseDouble(_basicSalaryController.text),
        'hraReceived': _parseDouble(_hraReceivedController.text),
        'rentPaid': _parseDouble(_rentPaidController.text),
        'hraExemption': hraExemption,

        // Results
        'newRegimeTax': newRegimeTotalTax,
        'oldRegimeTax': oldRegimeTotalTax,
        'betterRegime': betterRegime,
        'savings': savings,
      };

      final response =
          await ApiService.post(ApiConstants.taxSave, body: taxData);

      if (response['success'] == true) {
        print('[TaxCalculator] Tax data saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Tax calculation saved to your account'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('[TaxCalculator] Failed to save: ${response['message']}');
      }
    } catch (e) {
      print('[TaxCalculator] Error saving tax data: $e');
    }
  }

  double _calculateNewRegimeTax(double taxableIncome) {
    // New Regime Slabs (FY 2025-26)
    // Up to ₹4,00,000: Nil
    // ₹4,00,001 – ₹8,00,000: 5%
    // ₹8,00,001 – ₹12,00,000: 10%
    // ₹12,00,001 – ₹16,00,000: 15%
    // ₹16,00,001 – ₹20,00,000: 20%
    // ₹20,00,001 – ₹24,00,000: 25%
    // Above ₹24,00,000: 30%

    double tax = 0;

    if (taxableIncome > 2400000) {
      tax += (taxableIncome - 2400000) * 0.30;
      taxableIncome = 2400000;
    }
    if (taxableIncome > 2000000) {
      tax += (taxableIncome - 2000000) * 0.25;
      taxableIncome = 2000000;
    }
    if (taxableIncome > 1600000) {
      tax += (taxableIncome - 1600000) * 0.20;
      taxableIncome = 1600000;
    }
    if (taxableIncome > 1200000) {
      tax += (taxableIncome - 1200000) * 0.15;
      taxableIncome = 1200000;
    }
    if (taxableIncome > 800000) {
      tax += (taxableIncome - 800000) * 0.10;
      taxableIncome = 800000;
    }
    if (taxableIncome > 400000) {
      tax += (taxableIncome - 400000) * 0.05;
    }

    return tax;
  }

  double _calculateOldRegimeTax(double taxableIncome) {
    // Old Regime Slabs
    // Up to ₹2,50,000: Nil
    // ₹2,50,001 – ₹5,00,000: 5%
    // ₹5,00,001 – ₹10,00,000: 20%
    // Above ₹10,00,000: 30%

    double tax = 0;

    if (taxableIncome > 1000000) {
      tax += (taxableIncome - 1000000) * 0.30;
      taxableIncome = 1000000;
    }
    if (taxableIncome > 500000) {
      tax += (taxableIncome - 500000) * 0.20;
      taxableIncome = 500000;
    }
    if (taxableIncome > 250000) {
      tax += (taxableIncome - 250000) * 0.05;
    }

    return tax;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final surfaceColor = isDark ? AppColorsDark.surface : Colors.white;

    // Get available height for proper sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 200; // Account for app bar and nav

    return SizedBox(
      height: availableHeight,
      child: Column(
        children: [
          // Progress indicator header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _getStepTitle(_currentStep),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Form pages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPersonalDetailsStep(),
                    _buildComplianceStep(),
                    _buildIncomeStep(),
                    _buildDeductionsStep(),
                    _buildHRAStep(),
                    _buildResultsStep(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          if (_currentStep < _totalSteps - 1 || _taxResults == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _prevStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const AutoTranslatedText('Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: Icon(_currentStep == _totalSteps - 2
                          ? Icons.calculate
                          : Icons.arrow_forward),
                      label: AutoTranslatedText(
                        _currentStep == _totalSteps - 2
                            ? 'Calculate Tax'
                            : 'Next',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Details';
      case 1:
        return 'Compliance Check';
      case 2:
        return 'Income Details';
      case 3:
        return 'Deductions';
      case 4:
        return 'HRA Calculation';
      case 5:
        return 'Tax Results';
      default:
        return '';
    }
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('👤 Personal Details',
              'Enter your basic information for the tax estimation'),
          const SizedBox(height: 24),

          // Name field
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name as per PAN',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),

          // Email field
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email address',
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your details will be used to generate a personalized tax estimation report for FY 2025-26.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildComplianceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📋 Compliance Verification',
              'Ensure these are in place for smooth ITR filing'),
          const SizedBox(height: 16),
          _buildToggleQuestion(
            'Is your PAN linked to Aadhaar?',
            'Mandatory for ITR processing',
            _panAadhaarLinked,
            (v) => setState(() => _panAadhaarLinked = v),
          ),
          _buildToggleQuestion(
            'Is your bank account pre-validated?',
            'Required for receiving tax refunds',
            _bankPreValidated,
            (v) => setState(() => _bankPreValidated = v),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('📍 Basic Details', 'Your tax filing profile'),
          const SizedBox(height: 16),
          _buildDropdownField(
            'Residential Status',
            _residentialStatus,
            ['Resident', 'Non-Resident (NRI)', 'RNOR'],
            (v) => setState(() => _residentialStatus = v!),
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            'Assessment Year',
            _assessmentYear,
            ['AY 2026-27 (FY 2025-26)', 'AY 2025-26 (FY 2024-25)'],
            (v) => setState(() => _assessmentYear = v!),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('📝 Employment & Income Sources',
              'Help us determine the right ITR form'),
          const SizedBox(height: 16),
          _buildToggleQuestion(
            'Did you have multiple employers this year?',
            'Need Form 16 from all employers',
            _multipleEmployers,
            (v) => setState(() => _multipleEmployers = v),
          ),
          _buildToggleQuestion(
            'Do you own more than one house property?',
            'May require ITR-2 instead of ITR-1',
            _multipleHouseProperties,
            (v) => setState(() => _multipleHouseProperties = v),
          ),
          _buildToggleQuestion(
            'Did you sell shares, mutual funds, or real estate?',
            'Triggers Capital Gains tax',
            _soldAssetsCapitalGains,
            (v) => setState(() => _soldAssetsCapitalGains = v),
          ),
          _buildToggleQuestion(
            'Did you receive dividends or agricultural income?',
            'Agricultural income > ₹5,000 requires ITR-2',
            _hasDividendAgriIncome,
            (v) => setState(() => _hasDividendAgriIncome = v),
          ),
          _buildToggleQuestion(
            'Do you have freelancing or business income?',
            'Requires ITR-3 or ITR-4',
            _hasFreelanceIncome,
            (v) => setState(() => _hasFreelanceIncome = v),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
              '✅ Document Verification', 'Cross-check your tax documents'),
          const SizedBox(height: 16),
          _buildToggleQuestion(
            'Does Form 16 match your AIS?',
            'Annual Information Statement verification',
            _form16MatchesAIS,
            (v) => setState(() => _form16MatchesAIS = v),
          ),
          _buildToggleQuestion(
            'Is all TDS reflected in Form 26AS?',
            'Check TDS from employer, bank, clients',
            _tdsReflectedIn26AS,
            (v) => setState(() => _tdsReflectedIn26AS = v),
          ),
          _buildToggleQuestion(
            'Any high-value transactions in TIS?',
            'Check Taxpayer Information Summary',
            _highValueTransactions,
            (v) => setState(() => _highValueTransactions = v),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildIncomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              '💰 Income Sources', 'Enter your annual income details'),
          const SizedBox(height: 16),
          _buildAmountField(
            'Annual Salary Income',
            'Your gross salary from Form 16',
            _salaryController,
            Icons.work,
          ),
          _buildAmountField(
            'Interest Income',
            'From Savings, FD, Post Office schemes',
            _interestIncomeController,
            Icons.account_balance,
          ),
          _buildAmountField(
            'Rental Income',
            'Net annual rent received (if any)',
            _rentalIncomeController,
            Icons.home,
          ),
          if (_soldAssetsCapitalGains)
            _buildAmountField(
              'Capital Gains',
              'From sale of shares, MF, property',
              _capitalGainsController,
              Icons.trending_up,
            ),
          if (_hasFreelanceIncome)
            _buildAmountField(
              'Freelance/Business Income',
              'Net income from side business',
              _freelanceIncomeController,
              Icons.laptop_mac,
            ),
          _buildAmountField(
            'Other Income',
            'Dividends, gifts, interest from other sources',
            _otherIncomeController,
            Icons.more_horiz,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDeductionsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🎯 Deductions (For Old Regime)',
              'These reduce your taxable income under the Old Regime'),
          const SizedBox(height: 16),
          _buildAmountFieldWithLimit(
            'Section 80C',
            'EPF, ELSS, PPF, LIC, Home Loan Principal',
            _section80CController,
            Icons.savings,
            150000,
          ),
          _buildAmountField(
            'Section 80D',
            'Health Insurance Premium (Self/Family/Parents)',
            _section80DController,
            Icons.health_and_safety,
          ),
          _buildAmountFieldWithLimit(
            'Section 80CCD(1B)',
            'Self contribution to NPS (Additional)',
            _section80CCD1BController,
            Icons.account_balance_wallet,
            50000,
          ),
          _buildAmountFieldWithLimit(
            'Section 24(b)',
            'Home Loan Interest Payment',
            _section24bController,
            Icons.home_work,
            200000,
          ),
          _buildAmountField(
            'Section 80E',
            'Education Loan Interest',
            _section80EController,
            Icons.school,
          ),
          _buildAmountField(
            'Section 80G',
            'Donations to eligible charities',
            _section80GController,
            Icons.volunteer_activism,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHRAStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🏠 HRA Exemption',
              'Calculate your House Rent Allowance exemption'),
          const SizedBox(height: 16),
          _buildToggleQuestion(
            'Do you live in a rented house?',
            'Required for HRA exemption claim',
            _livesInRentedHouse,
            (v) => setState(() => _livesInRentedHouse = v),
          ),
          if (_livesInRentedHouse) ...[
            const SizedBox(height: 20),
            _buildAmountField(
              'Monthly Basic Salary',
              'Your basic salary component',
              _basicSalaryController,
              Icons.account_balance_wallet,
            ),
            _buildAmountField(
              'Monthly HRA Received',
              'HRA component in your salary',
              _hraReceivedController,
              Icons.home,
            ),
            _buildAmountField(
              'Monthly Rent Paid',
              'Actual rent you pay',
              _rentPaidController,
              Icons.receipt_long,
            ),

            const SizedBox(height: 16),
            _buildToggleQuestion(
              'Is the rented house in a Metro City?',
              'Delhi, Mumbai, Kolkata, Chennai',
              _isMetroCity,
              (v) => setState(() => _isMetroCity = v),
            ),

            // HRA Calculation Preview
            _buildHRAPreview(),
          ] else ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If you don\'t receive HRA but pay rent, you can claim up to ₹60,000/year under Section 80GG.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHRAPreview() {
    final basicSalary = _parseDouble(_basicSalaryController.text);
    final hraReceived = _parseDouble(_hraReceivedController.text) * 12;
    final rentPaid = _parseDouble(_rentPaidController.text) * 12;

    if (basicSalary <= 0 || rentPaid <= 0) {
      return const SizedBox.shrink();
    }

    final basicYearly = basicSalary * 12;
    final tenPercentBasic = basicYearly * 0.1;
    final hraPercent = _isMetroCity ? 0.5 : 0.4;

    final option1 = hraReceived;
    final option2 =
        (rentPaid - tenPercentBasic).clamp(0.0, double.infinity).toDouble();
    final option3 = basicYearly * hraPercent;

    final exemption =
        [option1, option2, option3].reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'HRA Exemption Calculation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHRARow('Actual HRA Received', option1),
          _buildHRARow('Rent - 10% of Basic', option2),
          _buildHRARow(
              '${_isMetroCity ? "50" : "40"}% of Basic Salary', option3),
          const Divider(),
          _buildHRARow('HRA Exemption (Minimum)', exemption, isBold: true),
        ],
      ),
    );
  }

  Widget _buildHRARow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₹${_formatNumber(value)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_taxResults == null) {
      return const Center(
        child: AutoTranslatedText('Complete the form to see results'),
      );
    }

    final results = _taxResults!;
    final newRegime = results['newRegime'] as Map<String, dynamic>;
    final oldRegime = results['oldRegime'] as Map<String, dynamic>;
    final betterRegime = results['betterRegime'] as String;
    final savings = results['savings'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendation Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: betterRegime == 'New Regime'
                    ? [Colors.blue.shade600, Colors.blue.shade400]
                    : [Colors.orange.shade600, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  '🎯 $betterRegime is Better!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You save ₹${_formatNumber(savings)} compared to the other regime',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Income Summary
          _buildResultCard(
            '💰 Income Summary',
            [
              _buildResultRow('Gross Income', results['grossIncome']),
              if (results['totalDeductions'] > 0)
                _buildResultRow('Total Deductions', results['totalDeductions'],
                    isDeduction: true),
              if (results['hraExemption'] > 0)
                _buildResultRow('HRA Exemption', results['hraExemption'],
                    isDeduction: true),
            ],
          ),

          const SizedBox(height: 16),

          // New Regime Card
          _buildTaxRegimeCard(
            'New Regime',
            newRegime,
            isRecommended: betterRegime == 'New Regime',
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Old Regime Card
          _buildTaxRegimeCard(
            'Old Regime',
            oldRegime,
            isRecommended: betterRegime == 'Old Regime',
            color: Colors.orange,
          ),

          const SizedBox(height: 24),

          // Important Notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Important Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNote(
                    'This is an estimated calculation for reference only'),
                _buildNote('Actual tax may vary based on additional factors'),
                _buildNote('Consult a tax professional for final filing'),
                _buildNote('New Regime is simpler but has fewer deductions'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recalculate Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _taxResults = null;
                  _currentStep = 0;
                });
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.refresh),
              label: const AutoTranslatedText('Recalculate'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTaxRegimeCard(
    String title,
    Map<String, dynamic> data, {
    required bool isRecommended,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? color : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isRecommended ? color.withOpacity(0.1) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isRecommended
                      ? Icons.check_circle
                      : Icons.remove_circle_outline,
                  color: isRecommended ? color : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isRecommended ? color : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildResultRow(
                    'Standard Deduction', data['standardDeduction']),
                _buildResultRow('Taxable Income', data['taxableIncome']),
                _buildResultRow('Tax', data['tax']),
                _buildResultRow('Cess (4%)', data['cess']),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Tax Payable',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '₹${_formatNumber(data['totalTax'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double value,
      {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${isDeduction ? "-" : ""}₹${_formatNumber(value)}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDeduction ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else {
      return value.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleQuestion(
      String question, String hint, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(hint,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: options
            .map((o) => DropdownMenuItem(
                value: o, child: Text(o, style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAmountField(String label, String hint,
      TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          prefixText: '₹ ',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountFieldWithLimit(String label, String hint,
      TextEditingController controller, IconData icon, double limit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon),
              prefixText: '₹ ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              'Maximum limit: ₹${_formatNumber(limit)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
