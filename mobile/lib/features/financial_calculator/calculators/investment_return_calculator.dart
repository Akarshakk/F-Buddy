import 'package:flutter/material.dart';
import 'package:f_buddy/l10n/app_localizations.dart';
import 'package:f_buddy/widgets/auto_translated_text.dart';
import 'dart:math';

/// Investment Return Calculator (Inflation Adjusted)
/// Formula: Real FV = PV × ((1 + g) / (1 + i))^n
class InvestmentReturnCalculator extends StatefulWidget {
  const InvestmentReturnCalculator({super.key});

  @override
  State<InvestmentReturnCalculator> createState() =>
      _InvestmentReturnCalculatorState();
}

class _InvestmentReturnCalculatorState
    extends State<InvestmentReturnCalculator> {
  final _pvController = TextEditingController();
  final _growthController = TextEditingController();
  final _inflationController = TextEditingController();
  final _yearsController = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _pvController.dispose();
    _growthController.dispose();
    _inflationController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final pv = double.tryParse(_pvController.text);
    final growth = double.tryParse(_growthController.text);
    final inflation = double.tryParse(_inflationController.text);
    final years = double.tryParse(_yearsController.text);

    if (pv == null || growth == null || inflation == null || years == null) {
      setState(() => _result = context.l10n.t('please_fill_all_fields'));
      return;
    }
    if (pv < 0 || growth < 0 || inflation < 0 || years < 0) {
      setState(() => _result = context.l10n.t('values_cannot_be_negative'));
      return;
    }

    final g = growth / 100;
    final i = inflation / 100;
    final realFV = pv * pow((1 + g) / (1 + i), years);

    setState(() {
      _result = 'Real Future Value:\n₹${realFV.toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorCard(
      title: context.l10n.t('investment_return'),
      subtitle: 'Inflation-adjusted investment returns',
      children: [
        _buildInput(_pvController, 'Present Value (₹)'),
        _buildInput(_growthController, 'Expected Growth Rate (%)'),
        _buildInput(_inflationController, 'Expected Inflation Rate (%)'),
        _buildInput(_yearsController, 'Number of Years'),
        const SizedBox(height: 20),
        _buildCalculateButton(),
        if (_result.isNotEmpty) _buildResult(),
      ],
    );
  }

  Widget _buildCalculatorCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            AutoTranslatedText(subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4),
            child: AutoTranslatedText(
              label,
              style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _calculate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(context.l10n.t('calculate'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: AutoTranslatedText(
        _result,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
