import 'package:flutter/material.dart';
import 'package:f_buddy/l10n/app_localizations.dart';
import 'package:f_buddy/widgets/auto_translated_text.dart';
import 'dart:math';

/// Inflation Calculator (Purchasing Power)
/// Formula: Future Value = PV × (1 + r)^n
class InflationCalculator extends StatefulWidget {
  const InflationCalculator({super.key});

  @override
  State<InflationCalculator> createState() => _InflationCalculatorState();
}

class _InflationCalculatorState extends State<InflationCalculator> {
  final _pvController = TextEditingController();
  final _rateController = TextEditingController();
  final _yearsController = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _pvController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final pv = double.tryParse(_pvController.text);
    final rate = double.tryParse(_rateController.text);
    final years = double.tryParse(_yearsController.text);

    if (pv == null || rate == null || years == null) {
      setState(() => _result = context.l10n.t('please_fill_all_fields'));
      return;
    }
    if (pv < 0 || rate < 0 || years < 0) {
      setState(() => _result = context.l10n.t('values_cannot_be_negative'));
      return;
    }

    final r = rate / 100;
    final purchasingPower = pv / pow(1 + r, years);

    setState(() {
      _result =
          'Purchasing Power After ${years.toInt()} Years:\n₹${purchasingPower.toStringAsFixed(2)}\n\n(Today\'s ₹${pv.toStringAsFixed(0)} will be worth this much)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorCard(
      title: context.l10n.t('inflation_calculator'),
      subtitle: 'Calculate purchasing power over time',
      children: [
        _buildInput(_pvController, 'Present Value (₹)'),
        _buildInput(_rateController, 'Inflation Rate (%)'),
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
