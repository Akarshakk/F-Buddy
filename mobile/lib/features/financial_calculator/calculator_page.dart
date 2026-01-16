import 'package:flutter/material.dart';
import 'dart:math';

/// Financial Calculator Page
///
/// A self-contained calculator widget that provides various financial calculations:
/// - Inflation Adjusted Future Value (Purchasing Power)
/// - Lump Sum Value After Inflation
/// - Annual Investment for Goal
/// - Annual Investment for Actual Goal (inflation-adjusted)
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String calculatorType = '';

  final pvController = TextEditingController();
  final fvController = TextEditingController();
  final rController = TextEditingController();
  final iController = TextEditingController();
  final nController = TextEditingController();

  String result = '';

  @override
  void dispose() {
    pvController.dispose();
    fvController.dispose();
    rController.dispose();
    iController.dispose();
    nController.dispose();
    super.dispose();
  }

  void calculate() {
    final pv = double.tryParse(pvController.text) ?? 0;
    final fv = double.tryParse(fvController.text) ?? 0;
    final r = (double.tryParse(rController.text) ?? 0) / 100;
    final i = (double.tryParse(iController.text) ?? 0) / 100;
    final n = double.tryParse(nController.text) ?? 0;

    double output;

    // 1️⃣ Purchasing Power After Inflation (CORRECT)
    if (calculatorType == 'inflation') {
      output = pv / pow(1 + i, n);
      result =
          'Purchasing Power After $n Years:\n₹${output.toStringAsFixed(2)}';
    }

    // 2️⃣ Lump Sum REAL Value after inflation + returns
    else if (calculatorType == 'actual') {
      output = pv * pow((1 + r) / (1 + i), n);
      result = 'Real Value After Inflation:\n₹${output.toStringAsFixed(2)}';
    }

    // 3️⃣ Annual Investment for Goal (Nominal)
    else if (calculatorType == 'reverse') {
      if (r <= 0) {
        result = 'Return rate must be greater than 0';
      } else {
        output = ((fv * r) / (pow(1 + r, n) - 1));
        result =
            'Annual Investment Required:\n₹${output.toStringAsFixed(2)} per year';
      }
    }

    // 4️⃣ Annual Investment for Actual Goal (Real)
    else if (calculatorType == 'annual_actual') {
      final realRate = (r - i) / (1 + i);

      if (realRate <= 0) {
        result = 'Return must be greater than inflation';
      } else {
        output = (fv * realRate) / (pow(1 + realRate, n) - 1);
        result =
            'Annual Investment (Real):\n₹${output.toStringAsFixed(2)} per year';
      }
    }

    setState(() {});
  }

  Widget input(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void clearAll() {
    pvController.clear();
    fvController.clear();
    rController.clear();
    iController.clear();
    nController.clear();
    result = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Financial Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Calculator',
                    border: OutlineInputBorder(),
                  ),
                  value: calculatorType.isEmpty ? null : calculatorType,
                  items: const [
                    DropdownMenuItem(
                      value: 'inflation',
                      child: Text(
                          'Inflation Adjusted Future Value (Purchasing Power)'),
                    ),
                    DropdownMenuItem(
                      value: 'actual',
                      child: Text('Lump Sum Value After Inflation'),
                    ),
                    DropdownMenuItem(
                      value: 'reverse',
                      child: Text('Annual Investment for Goal'),
                    ),
                    DropdownMenuItem(
                      value: 'annual_actual',
                      child: Text('Annual Investment for Actual Goal'),
                    ),
                  ],
                  onChanged: (value) {
                    calculatorType = value!;
                    clearAll();
                    setState(() {});
                  },
                ),
                if (calculatorType == 'inflation') ...[
                  input(pvController, 'Present Value (Today ₹)'),
                  input(iController, 'Inflation Rate (%)'),
                  input(nController, 'Years'),
                ],
                if (calculatorType == 'actual') ...[
                  input(pvController, 'Present Value (PV)'),
                  input(rController, 'Return Rate (%)'),
                  input(iController, 'Inflation Rate (%)'),
                  input(nController, 'Years'),
                ],
                if (calculatorType == 'reverse') ...[
                  input(fvController, 'Goal Amount (FV)'),
                  input(rController, 'Return Rate (%)'),
                  input(nController, 'Years'),
                ],
                if (calculatorType == 'annual_actual') ...[
                  input(fvController, 'Target Actual Value (FV)'),
                  input(rController, 'Return Rate (%)'),
                  input(iController, 'Inflation Rate (%)'),
                  input(nController, 'Years'),
                ],
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: calculatorType.isEmpty ? null : calculate,
                  child: const Text('Calculate'),
                ),
                const SizedBox(height: 15),
                Text(
                  result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
