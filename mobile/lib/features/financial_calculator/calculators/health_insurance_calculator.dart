import 'package:flutter/material.dart';
import 'package:f_buddy/l10n/app_localizations.dart';
import 'package:f_buddy/widgets/auto_translated_text.dart';

/// Health Insurance Premium Calculator
/// Formula: Annual Premium = Base × Age × SumInsured × City × Family multipliers
class HealthInsuranceCalculator extends StatefulWidget {
  const HealthInsuranceCalculator({super.key});

  @override
  State<HealthInsuranceCalculator> createState() =>
      _HealthInsuranceCalculatorState();
}

class _HealthInsuranceCalculatorState extends State<HealthInsuranceCalculator> {
  final _ageController = TextEditingController();
  String _sumInsured = '500000';
  String _cityType = 'tier2';
  String _familyType = 'individual';
  String _result = '';

  final Map<String, double> _sumMultipliers = {
    '500000': 1.0,
    '1000000': 1.7,
    '1500000': 2.2,
    '2000000': 2.8,
  };

  final Map<String, double> _cityMultipliers = {
    'tier2': 1.0,
    'metro': 1.15,
  };

  final Map<String, double> _familyMultipliers = {
    'individual': 1.0,
    'couple': 1.8,
    'couple+1': 2.2,
    'couple+2': 2.6,
  };

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  double _getAgeMultiplier(int age) {
    if (age >= 18 && age <= 25) return 1.0;
    if (age >= 26 && age <= 30) return 1.2;
    if (age >= 31 && age <= 35) return 1.5;
    if (age >= 36 && age <= 40) return 2.0;
    if (age >= 41 && age <= 45) return 2.7;
    if (age >= 46 && age <= 50) return 3.5;
    if (age >= 51 && age <= 55) return 4.5;
    if (age >= 56 && age <= 60) return 6.0;
    return 1.0;
  }

  void _calculate() {
    final age = int.tryParse(_ageController.text);

    if (age == null) {
      setState(() => _result = 'Please enter a valid age');
      return;
    }
    if (age < 18 || age > 60) {
      setState(() => _result = 'Age must be between 18 and 60');
      return;
    }

    final sumInsured = double.parse(_sumInsured);
    final basePremium = 1200 * (sumInsured / 100000);

    final ageMultiplier = _getAgeMultiplier(age);
    final sumMultiplier = _sumMultipliers[_sumInsured]!;
    final cityMultiplier = _cityMultipliers[_cityType]!;
    final familyMultiplier = _familyMultipliers[_familyType]!;

    final annualPremium = basePremium *
        ageMultiplier *
        sumMultiplier *
        cityMultiplier *
        familyMultiplier;

    setState(() {
      _result =
          'Estimated Annual Premium:\n₹${annualPremium.toStringAsFixed(2)}\n\n'
          'Monthly: ₹${(annualPremium / 12).toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorCard(
      title: context.l10n.t('health_insurance'),
      subtitle: 'Estimate your health insurance premium',
      children: [
        _buildInput(_ageController, 'Age (18-60)'),
        _buildDropdown(
          'Sum Insured',
          _sumInsured,
          {
            '500000': '₹5 Lakh',
            '1000000': '₹10 Lakh',
            '1500000': '₹15 Lakh',
            '2000000': '₹20 Lakh'
          },
          (v) => setState(() => _sumInsured = v!),
        ),
        _buildDropdown(
          'City Type',
          _cityType,
          {'tier2': 'Tier 2/3 City', 'metro': 'Metro City'},
          (v) => setState(() => _cityType = v!),
        ),
        _buildDropdown(
          'Family Type',
          _familyType,
          {
            'individual': 'Individual',
            'couple': 'Couple',
            'couple+1': 'Couple + 1 Child',
            'couple+2': 'Couple + 2 Children'
          },
          (v) => setState(() => _familyType = v!),
        ),
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
            keyboardType: TextInputType.number,
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

  Widget _buildDropdown(String label, String value, Map<String, String> items,
      ValueChanged<String?> onChanged) {
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
          DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: items.entries
                .map((e) => DropdownMenuItem(
                    value: e.key, 
                    // Use AutoTranslatedText for dropdown items too!
                    child: AutoTranslatedText(e.value))) 
                .toList(),
            onChanged: onChanged,
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
