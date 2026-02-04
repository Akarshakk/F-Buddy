import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../widgets/auto_translated_text.dart';

/// Live Finance Tracking Screen
/// Shows user's financial overview with loans, SIPs, investments, and income
class LiveFinanceTrackingScreen extends StatefulWidget {
  const LiveFinanceTrackingScreen({super.key});

  @override
  State<LiveFinanceTrackingScreen> createState() =>
      _LiveFinanceTrackingScreenState();
}

class _LiveFinanceTrackingScreenState extends State<LiveFinanceTrackingScreen> {
  // Income
  final _annualIncomeController = TextEditingController();

  // Loans
  final List<Map<String, dynamic>> _loans = [];
  final _loanNameController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _loanEmiController = TextEditingController();

  // SIPs
  final List<Map<String, dynamic>> _sips = [];
  final _sipNameController = TextEditingController();
  final _sipAmountController = TextEditingController();

  // Investments
  final List<Map<String, dynamic>> _investments = [];
  final _investNameController = TextEditingController();
  final _investAmountController = TextEditingController();
  final _investTypeController = TextEditingController(text: 'Stocks');

  // Insurance
  final List<Map<String, dynamic>> _insurances = [];
  final _insureNameController = TextEditingController();
  final _insurePremiumController = TextEditingController();
  final _insureCoverController = TextEditingController();
  String _insureFrequency = 'Yearly';

  // Track if we have data to show charts
  bool get _hasData =>
      _loans.isNotEmpty ||
      _sips.isNotEmpty ||
      _investments.isNotEmpty ||
      _insurances.isNotEmpty ||
      (_annualIncomeController.text.isNotEmpty &&
          double.tryParse(_annualIncomeController.text) != null);

  @override
  void dispose() {
    _annualIncomeController.dispose();
    _loanNameController.dispose();
    _loanAmountController.dispose();
    _loanEmiController.dispose();
    _sipNameController.dispose();
    _sipAmountController.dispose();
    _investNameController.dispose();
    _investAmountController.dispose();
    _investTypeController.dispose();
    _insureNameController.dispose();
    _insurePremiumController.dispose();
    _insureCoverController.dispose();
    super.dispose();
  }

  double _parseDouble(String text) =>
      double.tryParse(text.replaceAll(',', '')) ?? 0;

  void _addLoan() {
    if (_loanNameController.text.isNotEmpty &&
        _loanAmountController.text.isNotEmpty) {
      setState(() {
        _loans.add({
          'name': _loanNameController.text,
          'amount': _parseDouble(_loanAmountController.text),
          'emi': _parseDouble(_loanEmiController.text),
        });
        _loanNameController.clear();
        _loanAmountController.clear();
        _loanEmiController.clear();
      });
    }
  }

  void _addSip() {
    if (_sipNameController.text.isNotEmpty &&
        _sipAmountController.text.isNotEmpty) {
      setState(() {
        _sips.add({
          'name': _sipNameController.text,
          'amount': _parseDouble(_sipAmountController.text),
        });
        _sipNameController.clear();
        _sipAmountController.clear();
      });
    }
  }

  void _addInvestment() {
    if (_investNameController.text.isNotEmpty &&
        _investAmountController.text.isNotEmpty) {
      setState(() {
        _investments.add({
          'name': _investNameController.text,
          'amount': _parseDouble(_investAmountController.text),
          'type': _investTypeController.text,
        });
        _investNameController.clear();
        _investAmountController.clear();
      });
    }
  }

  void _addInsurance() {
    if (_insureNameController.text.isNotEmpty &&
        _insurePremiumController.text.isNotEmpty) {
      setState(() {
        final premium = _parseDouble(_insurePremiumController.text);
        // Default cover to 0 if empty
        final cover = _insureCoverController.text.isNotEmpty
            ? _parseDouble(_insureCoverController.text)
            : 0.0;

        _insurances.add({
          'name': _insureNameController.text,
          'premium': premium,
          'cover': cover,
          'frequency': _insureFrequency,
        });
        _insureNameController.clear();
        _insurePremiumController.clear();
        _insureCoverController.clear();
        _insureFrequency = 'Yearly';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final surfaceColor = isDark ? AppColorsDark.surface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const AutoTranslatedText('Live Finance Tracking'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Annual Income Section
            _buildSectionCard(
              title: '💰 Annual Income',
              color: Colors.green,
              surfaceColor: surfaceColor,
              child: Column(
                children: [
                  TextFormField(
                    controller: _annualIncomeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Annual Income',
                      hintText: 'Enter your total annual income',
                      prefixText: '₹ ',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loans Section
            _buildSectionCard(
              title: '🏦 Existing Loans',
              color: Colors.red,
              surfaceColor: surfaceColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _loanNameController,
                          decoration: InputDecoration(
                            labelText: 'Loan Name',
                            hintText: 'e.g., Home Loan',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _loanAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Outstanding',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _loanEmiController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Monthly EMI',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addLoan,
                        icon: const Icon(Icons.add_circle),
                        color: Colors.red,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  if (_loans.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._loans
                        .asMap()
                        .entries
                        .map((e) => _buildLoanTile(e.key, e.value)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SIPs Section
            _buildSectionCard(
              title: '📈 SIPs (Systematic Investment Plans)',
              color: Colors.blue,
              surfaceColor: surfaceColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _sipNameController,
                          decoration: InputDecoration(
                            labelText: 'SIP/Fund Name',
                            hintText: 'e.g., Axis Bluechip',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _sipAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Monthly Amount',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addSip,
                        icon: const Icon(Icons.add_circle),
                        color: Colors.blue,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  if (_sips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._sips
                        .asMap()
                        .entries
                        .map((e) => _buildSipTile(e.key, e.value)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Insurance Section
            _buildSectionCard(
              title: '🛡️ Insurance',
              color: Colors.teal,
              surfaceColor: surfaceColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _insureNameController,
                          decoration: InputDecoration(
                            labelText: 'Policy Name',
                            hintText: 'e.g., LIC Jeevan',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _insurePremiumController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Premium',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Yearly', 'Monthly'].map((freq) {
                              final isSelected = _insureFrequency == freq;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ChoiceChip(
                                  label: Text(freq,
                                      style: const TextStyle(fontSize: 10)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _insureFrequency = freq);
                                    }
                                  },
                                  selectedColor: Colors.teal.shade100,
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addInsurance,
                        icon: const Icon(Icons.add_circle),
                        color: Colors.teal,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  if (_insurances.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._insurances
                        .asMap()
                        .entries
                        .map((e) => _buildInsuranceTile(e.key, e.value)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Investments Section
            _buildSectionCard(
              title: '💎 Investments',
              color: Colors.purple,
              surfaceColor: surfaceColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _investNameController,
                          decoration: InputDecoration(
                            labelText: 'Investment Name',
                            hintText: 'e.g., PPF, FD',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _investAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Value',
                            prefixText: '₹ ',
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'Stocks',
                              'Bonds',
                              'FD',
                              'PPF',
                              'Gold',
                              'Real Estate',
                              'Crypto',
                              'Other'
                            ].map((type) {
                              final isSelected =
                                  _investTypeController.text == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(type),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() =>
                                          _investTypeController.text = type);
                                    }
                                  },
                                  selectedColor: Colors.purple.shade100,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.purple.shade900
                                        : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addInvestment,
                        icon: const Icon(Icons.add_circle),
                        color: Colors.purple,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  if (_investments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._investments
                        .asMap()
                        .entries
                        .map((e) => _buildInvestmentTile(e.key, e.value)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Charts Section
            if (_hasData) ...[
              const AutoTranslatedText(
                '📊 Financial Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Fund Distribution Pie Chart
              _buildChartCard(
                title: 'Fund Distribution',
                surfaceColor: surfaceColor,
                child: SizedBox(
                  height: 250,
                  child: _buildFundDistributionChart(),
                ),
              ),

              const SizedBox(height: 16),

              // Income Distribution Pie Chart
              _buildChartCard(
                title: 'Monthly Income Distribution',
                surfaceColor: surfaceColor,
                child: SizedBox(
                  height: 250,
                  child: _buildIncomeDistributionChart(),
                ),
              ),

              const SizedBox(height: 16),

              // Monthly Outflow Pie Chart (Updated label)
              if (_loans.isNotEmpty ||
                  _sips.isNotEmpty ||
                  _insurances.isNotEmpty)
                _buildChartCard(
                  title: 'Monthly Commitments Breakdown',
                  surfaceColor: surfaceColor,
                  child: SizedBox(
                    height: 250,
                    child: _buildMonthlyOutflowChart(),
                  ),
                ),

              const SizedBox(height: 16),

              // Investment Mix Pie Chart
              if (_investments.isNotEmpty)
                _buildChartCard(
                  title: 'Investment Mix',
                  surfaceColor: surfaceColor,
                  child: SizedBox(
                    height: 250,
                    child: _buildInvestmentMixChart(),
                  ),
                ),

              const SizedBox(height: 16),

              // Summary Stats
              _buildSummaryCard(surfaceColor),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required Color surfaceColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChartCard(
      {required String title,
      required Color surfaceColor,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInsuranceTile(int index, Map<String, dynamic> insure) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(insure['frequency'] == 'Yearly' ? 'YR' : 'MO',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insure['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              /*
              if ((insure['cover'] as double) > 0)
                Text('Cover: ₹${_formatNumber(insure['cover'])}', 
                     style: TextStyle(fontSize: 10, color: Colors.grey.shade600))
              */
            ],
          )),
          Text('₹${_formatNumber(insure['premium'])}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            onPressed: () => setState(() => _insurances.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeDistributionChart() {
    final annualIncome = _parseDouble(_annualIncomeController.text);
    final monthlyIncome = annualIncome / 12;

    if (monthlyIncome <= 0) {
      return const Center(
          child: Text('Enter Annual Income to see distribution'));
    }

    final totalMonthlyEmi =
        _loans.fold<double>(0, (sum, l) => sum + (l['emi'] as double));
    final totalMonthlySip =
        _sips.fold<double>(0, (sum, s) => sum + (s['amount'] as double));

    final totalMonthlyInsurance = _insurances.fold<double>(0, (sum, i) {
      final premium = i['premium'] as double;
      return sum + (i['frequency'] == 'Yearly' ? premium / 12 : premium);
    });

    final totalCommitments =
        totalMonthlyEmi + totalMonthlySip + totalMonthlyInsurance;
    final balance = monthlyIncome - totalCommitments;

    final data = <MapEntry<String, double>>[];
    if (totalMonthlyEmi > 0) data.add(MapEntry('EMIs', totalMonthlyEmi));
    if (totalMonthlySip > 0) data.add(MapEntry('SIPs', totalMonthlySip));
    if (totalMonthlyInsurance > 0) {
      data.add(MapEntry('Insurance', totalMonthlyInsurance));
    }
    if (balance > 0) data.add(MapEntry('Disposable/Savings', balance));

    // Colors: Red for Debt, Blue for SIP, Teal for Insurance, Green for Balance
    final colorMap = {
      'EMIs': Colors.red,
      'SIPs': Colors.blue,
      'Insurance': Colors.teal,
      'Disposable/Savings': Colors.green,
    };

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((e) {
                return PieChartSectionData(
                  value: e.value.value,
                  color: colorMap[e.value.key] ?? Colors.grey,
                  radius: 50,
                  title:
                      '${((e.value.value / monthlyIncome) * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: colorMap[e.value.key] ?? Colors.grey,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.value.key,
                            style: const TextStyle(fontSize: 11))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Update existing methods if referenced/needed, but specifically replacing _buildFundDistributionChart isn't strictly requested to be REMOVED, just Income Distribution Added.
  // Although user said "distribute the income... and give a pie chart".
  // I will KEEP Fund Distribution (Wealth view) and ADD Income Distribution (Cashflow view).

  // NOTE: I need to update _buildMonthlyOutflowChart to include Insurance

  Widget _buildMonthlyOutflowChart() {
    final data = <MapEntry<String, double>>[];

    for (var loan in _loans) {
      if ((loan['emi'] as double) > 0) {
        data.add(MapEntry('${loan['name']} (EMI)', loan['emi'] as double));
      }
    }
    for (var sip in _sips) {
      data.add(MapEntry('${sip['name']} (SIP)', sip['amount'] as double));
    }
    for (var ins in _insurances) {
      final premium = ins['premium'] as double;
      final monthly = ins['frequency'] == 'Yearly' ? premium / 12 : premium;
      if (monthly > 0) data.add(MapEntry('${ins['name']} (Ins)', monthly));
    }

    if (data.isEmpty) {
      return const Center(child: Text('No monthly commitments yet'));
    }

    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.orange,
      Colors.purple,
      Colors.indigo,
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((e) {
                final total =
                    data.fold<double>(0, (sum, item) => sum + item.value);
                return PieChartSectionData(
                  value: e.value.value,
                  color: colors[e.key % colors.length],
                  radius: 50,
                  title:
                      '${((e.value.value / total) * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(e.value.key,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTile(int index, Map<String, dynamic> loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(loan['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('?${_formatNumber(loan['amount'])}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Text('EMI: ?${_formatNumber(loan['emi'])}/mo',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            onPressed: () => setState(() => _loans.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildSipTile(int index, Map<String, dynamic> sip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(sip['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('?${_formatNumber(sip['amount'])}/mo',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            onPressed: () => setState(() => _sips.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentTile(int index, Map<String, dynamic> invest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(invest['type'],
                style: TextStyle(fontSize: 11, color: Colors.purple.shade700)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(invest['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('?${_formatNumber(invest['amount'])}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
            onPressed: () => setState(() => _investments.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildFundDistributionChart() {
    final annualIncome = _parseDouble(_annualIncomeController.text);
    final totalLoans =
        _loans.fold<double>(0, (sum, l) => sum + (l['amount'] as double));
    final totalSipsYearly =
        _sips.fold<double>(0, (sum, s) => sum + (s['amount'] as double)) * 12;
    final totalInvestments =
        _investments.fold<double>(0, (sum, i) => sum + (i['amount'] as double));
    final totalEmiYearly =
        _loans.fold<double>(0, (sum, l) => sum + (l['emi'] as double)) * 12;

    final data = <MapEntry<String, double>>[];
    if (totalLoans > 0) data.add(MapEntry('Loans', totalLoans));
    if (totalSipsYearly > 0) {
      data.add(MapEntry('SIPs (Yearly)', totalSipsYearly));
    }
    if (totalInvestments > 0) {
      data.add(MapEntry('Investments', totalInvestments));
    }
    if (annualIncome > 0) {
      final savings = annualIncome - totalEmiYearly - totalSipsYearly;
      if (savings > 0) data.add(MapEntry('Remaining Income', savings));
    }

    if (data.isEmpty) {
      return const Center(child: Text('Add data to see chart'));
    }

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((e) {
                return PieChartSectionData(
                  value: e.value.value,
                  color: colors[e.key % colors.length],
                  radius: 50,
                  title:
                      '${((e.value.value / data.fold<double>(0, (s, m) => s + m.value)) * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.value.key,
                            style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentMixChart() {
    // Group by type
    final typeMap = <String, double>{};
    for (var invest in _investments) {
      final type = invest['type'] as String;
      typeMap[type] = (typeMap[type] ?? 0) + (invest['amount'] as double);
    }

    final data = typeMap.entries.toList();
    if (data.isEmpty) return const Center(child: Text('No investments yet'));

    final colors = [
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.amber,
      Colors.orange
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((e) {
                return PieChartSectionData(
                  value: e.value.value,
                  color: colors[e.key % colors.length],
                  radius: 50,
                  title:
                      '${((e.value.value / data.fold<double>(0, (s, m) => s + m.value)) * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.value.key,
                            style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Color surfaceColor) {
    final annualIncome = _parseDouble(_annualIncomeController.text);
    final monthlyIncome = annualIncome / 12;

    // Assets
    final totalInvestments =
        _investments.fold<double>(0, (sum, i) => sum + (i['amount'] as double));

    // Liabilities
    final totalLoans =
        _loans.fold<double>(0, (sum, l) => sum + (l['amount'] as double));

    // Monthly Flows
    final totalMonthlyEmi =
        _loans.fold<double>(0, (sum, l) => sum + (l['emi'] as double));
    final totalMonthlySip =
        _sips.fold<double>(0, (sum, s) => sum + (s['amount'] as double));
    final totalMonthlyInsurance = _insurances.fold<double>(0, (sum, i) {
      final premium = i['premium'] as double;
      return sum + (i['frequency'] == 'Yearly' ? premium / 12 : premium);
    });

    final totalMonthlyOutflow =
        totalMonthlyEmi + totalMonthlySip + totalMonthlyInsurance;
    final monthlySurplus = monthlyIncome - totalMonthlyOutflow;

    // Ratios
    final debtToIncomeRatio =
        monthlyIncome > 0 ? (totalMonthlyEmi / monthlyIncome) * 100 : 0.0;
    final savingsRatio = monthlyIncome > 0
        ? ((totalMonthlySip + (monthlySurplus > 0 ? monthlySurplus : 0)) /
                monthlyIncome) *
            100
        : 0.0;

    // Colors based on health
    final dtiColor = debtToIncomeRatio < 30
        ? Colors.green
        : (debtToIncomeRatio < 50 ? Colors.orange : Colors.red);
    final savingsColor = savingsRatio > 20
        ? Colors.green
        : (savingsRatio > 10 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.purple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          const Text('?? Financial Health Report',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Net Worth Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryValue(
                  'Net Worth',
                  '?${_formatNumber(totalInvestments - totalLoans)}',
                  (totalInvestments - totalLoans) >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  isLarge: true),
              _buildSummaryValue(
                  'Monthly Surplus',
                  '?${_formatNumber(monthlySurplus)}',
                  monthlySurplus >= 0 ? Colors.white : Colors.redAccent,
                  isLarge: true),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),

          // Ratios Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('${debtToIncomeRatio.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: dtiColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Text('Debt-to-Income',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('(Target: <30%)',
                      style: TextStyle(color: Colors.white30, fontSize: 10)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Column(
                children: [
                  Text('${savingsRatio.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: savingsColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Text('Savings Rate',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('(Target: >20%)',
                      style: TextStyle(color: Colors.white30, fontSize: 10)),
                ],
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 30),

          // Details Grid
          Table(
            children: [
              TableRow(children: [
                _buildSummaryText(
                    'Total Assets',
                    '?${_formatNumber(totalInvestments)}',
                    Colors.blue.shade200),
                _buildSummaryText('Total Liabilities',
                    '?${_formatNumber(totalLoans)}', Colors.red.shade200),
              ]),
              const TableRow(
                  children: [SizedBox(height: 12), SizedBox(height: 12)]),
              TableRow(children: [
                _buildSummaryText('Monthly Income',
                    '?${_formatNumber(monthlyIncome)}', Colors.green.shade200),
                _buildSummaryText(
                    'Monthly Outflow',
                    '?${_formatNumber(totalMonthlyOutflow)}',
                    Colors.orange.shade200),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryValue(String label, String value, Color color,
      {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isLarge ? 20 : 16)),
      ],
    );
  }

  Widget _buildSummaryText(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)} Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)} L';
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}


