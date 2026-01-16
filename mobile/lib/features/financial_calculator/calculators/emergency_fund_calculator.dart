import 'package:flutter/material.dart';

/// Emergency Fund Calculator
/// Formula: Emergency Fund = Monthly Income × 6
class EmergencyFundCalculator extends StatefulWidget {
  const EmergencyFundCalculator({super.key});

  @override
  State<EmergencyFundCalculator> createState() =>
      _EmergencyFundCalculatorState();
}

class _EmergencyFundCalculatorState extends State<EmergencyFundCalculator> {
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
      setState(() => _result = 'Please enter monthly income');
      return;
    }
    if (income < 0) {
      setState(() => _result = 'Income cannot be negative');
      return;
    }

    final emergencyFund = income * 6;

    setState(() {
      _result =
          'Recommended Emergency Fund:\n₹${_formatNumber(emergencyFund)}\n\n(6 months of expenses)';
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
      title: 'Emergency Fund Calculator',
      subtitle: 'Calculate your emergency fund requirement',
      children: [
        _buildInput(_incomeController, 'Monthly Income (₹)'),
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
