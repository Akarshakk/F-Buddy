import 'package:flutter/material.dart';
import 'package:f_buddy/l10n/app_localizations.dart';
import 'package:f_buddy/widgets/auto_translated_text.dart';

/// Motor Insurance Premium Calculator
class MotorInsuranceCalculator extends StatefulWidget {
  const MotorInsuranceCalculator({super.key});

  @override
  State<MotorInsuranceCalculator> createState() =>
      _MotorInsuranceCalculatorState();
}

class _MotorInsuranceCalculatorState extends State<MotorInsuranceCalculator> {
  String _vehicleType = 'car';
  String _vehicleAge = '0-1';
  String _fuelType = 'petrol';
  final _idvController = TextEditingController();
  String _result = '';

  final Map<String, double> _vehicleMultipliers = {
    'two_wheeler': 0.8,
    'car': 1.0,
    'suv': 1.3,
    'commercial': 1.5,
  };

  final Map<String, double> _ageMultipliers = {
    '0-1': 1.0,
    '1-3': 0.9,
    '3-5': 0.8,
    '5+': 0.7,
  };

  final Map<String, double> _fuelMultipliers = {
    'petrol': 1.0,
    'diesel': 1.1,
    'electric': 0.85,
    'cng': 0.95,
  };

  @override
  void dispose() {
    _idvController.dispose();
    super.dispose();
  }

  void _calculate() {
    final idv = double.tryParse(_idvController.text);

    if (idv == null || idv <= 0) {
      setState(() => _result = 'Please enter valid IDV amount');
      return;
    }

    // Base rate: 2.5% of IDV for comprehensive
    final baseRate = 0.025;
    final basePremium = idv * baseRate;

    final vehicleMultiplier = _vehicleMultipliers[_vehicleType]!;
    final ageMultiplier = _ageMultipliers[_vehicleAge]!;
    final fuelMultiplier = _fuelMultipliers[_fuelType]!;

    final annualPremium =
        basePremium * vehicleMultiplier * ageMultiplier * fuelMultiplier;
    final thirdParty =
        _vehicleType == 'two_wheeler' ? 1850 : 2094; // Standard TP rates

    setState(() {
      _result = 'Comprehensive Premium: ₹${annualPremium.toStringAsFixed(2)}\n'
          'Third Party: ₹$thirdParty\n\n'
          'Total Annual Premium: ₹${(annualPremium + thirdParty).toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorCard(
      title: context.l10n.t('motor_insurance'),
      subtitle: 'Estimate your vehicle insurance premium',
      children: [
        _buildDropdown(
          'Vehicle Type',
          _vehicleType,
          {
            'two_wheeler': 'Two Wheeler',
            'car': 'Car',
            'suv': 'SUV',
            'commercial': 'Commercial'
          },
          (v) => setState(() => _vehicleType = v!),
        ),
        _buildDropdown(
          'Vehicle Age',
          _vehicleAge,
          {
            '0-1': '0-1 Years',
            '1-3': '1-3 Years',
            '3-5': '3-5 Years',
            '5+': '5+ Years'
          },
          (v) => setState(() => _vehicleAge = v!),
        ),
        _buildDropdown(
          'Fuel Type',
          _fuelType,
          {
            'petrol': 'Petrol',
            'diesel': 'Diesel',
            'electric': 'Electric',
            'cng': 'CNG'
          },
          (v) => setState(() => _fuelType = v!),
        ),
        _buildInput(_idvController, 'Insured Declared Value (IDV) ₹'),
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
