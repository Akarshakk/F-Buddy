import 'package:flutter/material.dart';
import 'dart:math';

/// SIP Calculator
/// Formula: M = P × (1 + i) × [((1 + i)^n − 1) / i]
/// where n = Years × 12, i = annual rate / 12 / 100
class SipCalculator extends StatefulWidget {
  const SipCalculator({super.key});

  @override
  State<SipCalculator> createState() => _SipCalculatorState();
}

class _SipCalculatorState extends State<SipCalculator> {
  final _monthlyController = TextEditingController();
  final _rateController = TextEditingController();
  final _yearsController = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _monthlyController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final monthly = double.tryParse(_monthlyController.text);
    final annualRate = double.tryParse(_rateController.text);
    final years = double.tryParse(_yearsController.text);

    if (monthly == null || annualRate == null || years == null) {
      setState(() => _result = 'Please fill all fields');
      return;
    }
    if (monthly < 0 || annualRate < 0 || years < 0) {
      setState(() => _result = 'Values cannot be negative');
      return;
    }

    final n = years * 12;
    final i = annualRate / 12 / 100;

    double maturity;
    if (i == 0) {
      maturity = monthly * n;
    } else {
      maturity = monthly * (1 + i) * ((pow(1 + i, n) - 1) / i);
    }

    final totalInvested = monthly * n;
    final returns = maturity - totalInvested;

    setState(() {
      _result = 'Maturity Value: ₹${_formatNumber(maturity)}\n\n'
          'Total Invested: ₹${_formatNumber(totalInvested)}\n'
          'Returns: ₹${_formatNumber(returns)}';
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
      title: 'SIP Calculator',
      subtitle: 'Calculate SIP maturity value',
      children: [
        _buildInput(_monthlyController, 'Monthly Investment (₹)'),
        _buildInput(_rateController, 'Expected Annual Return (%)'),
        _buildInput(_yearsController, 'Investment Duration (Years)'),
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
            Text(subtitle,
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
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
        child: const Text('Calculate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      child: Text(
        _result,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
