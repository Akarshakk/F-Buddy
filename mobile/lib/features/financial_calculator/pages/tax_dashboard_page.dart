import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';

class TaxDashboardPage extends StatefulWidget {
  const TaxDashboardPage({super.key});

  @override
  State<TaxDashboardPage> createState() => _TaxDashboardPageState();
}

class _TaxDashboardPageState extends State<TaxDashboardPage> {
  final _incomeController = TextEditingController();
  final _deductionsController = TextEditingController(); // 80C etc
  final _taxPaidController = TextEditingController();

  double get _income =>
      double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0;
  double get _deductions =>
      double.tryParse(_deductionsController.text.replaceAll(',', '')) ?? 0;
  double get _taxPaid =>
      double.tryParse(_taxPaidController.text.replaceAll(',', '')) ?? 0;

  // Simple estimation (New Regime slabs 2025-26 approximation)
  double get _estimatedTax {
    double taxable = _income - _deductions;
    // New regime standard deduction
    taxable -= 75000;
    if (taxable <= 0) return 0;

    // Very rough slab for visualization (this is Dashboard, not the precise Calculator)
    // 0-4L: 0
    // 4-8L: 5%
    // 8-12L: 10%
    // 12-16L: 15%
    // 16-20L: 20%
    // 20-24L: 25%
    // >24L: 30%

    double tax = 0;
    // ... Simplified logic or just manual input.
    // Let's assume user wants to TRACK, so maybe they input 'Tax Liability' manually?
    // Or we provide a rough auto-calc.
    // I'll use a simplified calc for the visual.

    // Using 2025 slabs rough
    if (taxable > 2400000) {
      tax += (taxable - 2400000) * 0.30;
      taxable = 2400000;
    }
    if (taxable > 2000000) {
      tax += (taxable - 2000000) * 0.25;
      taxable = 2000000;
    }
    if (taxable > 1600000) {
      tax += (taxable - 1600000) * 0.20;
      taxable = 1600000;
    }
    if (taxable > 1200000) {
      tax += (taxable - 1200000) * 0.15;
      taxable = 1200000;
    }
    if (taxable > 800000) {
      tax += (taxable - 800000) * 0.10;
      taxable = 800000;
    }
    if (taxable > 400000) {
      tax += (taxable - 400000) * 0.05;
      taxable = 400000;
    }

    // Rebate 87A if income <= 12L (New Regime 2025)
    if (_income <= 1200000) tax = 0;

    // Cess 4%
    return tax * 1.04;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = FinzoTheme.surface(context);

    final estTax = _estimatedTax;
    final due = estTax - _taxPaid;
    final disposable = _income - estTax;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [FinzoColors.brandSecondary, FinzoColors.brandSecondary.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: FinzoColors.brandSecondary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryVal(
                    'Tax Liability', '₹${estTax.toStringAsFixed(0)}'),
                _buildSummaryVal(
                    'Tax Due', '₹${due > 0 ? due.toStringAsFixed(0) : "0"}',
                    color: due > 0 ? Colors.white70 : Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            color: surfaceColor,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Annual Income',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _deductionsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Deductions (80C, etc.)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _taxPaidController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Taxes Paid (TDS/Advance)',
                          border: OutlineInputBorder())),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Distribution Chart
          if (_income > 0) ...[
            const Text('Income Allocation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: surfaceColor, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (estTax > 0)
                            PieChartSectionData(
                                color: Colors.red,
                                value: estTax,
                                title:
                                    '${((estTax / _income) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          if (_taxPaid > 0 && _taxPaid < estTax)
                            PieChartSectionData(
                                color: Colors.green,
                                value: _taxPaid,
                                title: 'Paid',
                                radius: 45,
                                showTitle: false),
                          if (disposable > 0)
                            PieChartSectionData(
                                color: Colors.blue,
                                value: disposable,
                                title:
                                    '${((disposable / _income) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegend(Colors.red, 'Tax Liability'),
                        _buildLegend(Colors.blue, 'Disposable Income'),
                        _buildLegend(Colors.green, 'Tax Paid'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSummaryVal(String label, String val,
      {Color color = Colors.white}) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}


