import 'package:flutter/material.dart';
import 'package:f_buddy/l10n/app_localizations.dart';
import 'package:f_buddy/widgets/auto_translated_text.dart';

/// Term Insurance Cover Calculator
/// Formula: Recommended Term Cover = 30 × Annual Income
class TermInsuranceCalculator extends StatefulWidget {
  const TermInsuranceCalculator({super.key});

  @override
  State<TermInsuranceCalculator> createState() =>
      _TermInsuranceCalculatorState();
}

class _TermInsuranceCalculatorState extends State<TermInsuranceCalculator> {
  final _incomeController = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeController.text);

    if (income == null) {
      setState(() => _result = 'Please enter annual income');
      return;
    }
    if (income < 0) {
      setState(() => _result = context.l10n.t('values_cannot_be_negative'));
      return;
    }

    final cover = 30 * income;

    setState(() {
      _result =
          'Recommended Term Cover:\n₹${_formatNumber(cover)}\n\n(30x your annual income)';
    });
  }

  String _formatNumber(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorCard(
      title: context.l10n.t('term_insurance'),
      subtitle: 'Calculate your ideal term insurance cover',
      children: [
        _buildInput(_incomeController, 'Annual Income (₹)'),
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
