import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Vehicle Loan Affordability Calculator using 20/4/10 Rule
class VehicleLoanPage extends StatefulWidget {
  const VehicleLoanPage({super.key});

  @override
  State<VehicleLoanPage> createState() => _VehicleLoanPageState();
}

class _VehicleLoanPageState extends State<VehicleLoanPage> {
  final _monthlyIncomeController = TextEditingController();
  bool _showResult = false;

  double _maxTotalCarExpense = 0;
  double _maxVehiclePrice = 0;
  double _recommendedDownPayment = 0;
  double _maxLoanAmount = 0;
  double _maxEmi = 0;

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final monthlyIncome = double.tryParse(_monthlyIncomeController.text) ?? 0;

    if (monthlyIncome <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your monthly income')),
      );
      return;
    }

    setState(() {
      // 20/4/10 Rule
      _maxTotalCarExpense = monthlyIncome *
          0.10; // 10% of gross monthly income for all car expenses
      _maxEmi = _maxTotalCarExpense *
          0.60; // ~60% of car budget for EMI (rest for fuel, insurance, maintenance)

      // Calculate vehicle price based on 48-month tenure at ~9% interest
      // Using simplified formula: Loan = EMI * 42 (approximate factor for 4 years @ 9%)
      _maxLoanAmount = _maxEmi * 42;
      _recommendedDownPayment =
          _maxLoanAmount * 0.25; // 20% down payment means loan is 80%
      _maxVehiclePrice = _maxLoanAmount + _recommendedDownPayment;

      _showResult = true;
    });
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)} L';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theory Card
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'The 20/4/10 Rule',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The gold standard for vehicle buying - ensures you don\'t overstretch for a depreciating asset:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem('20%', 'Down Payment',
                      'Pay at least 20% upfront to cover initial depreciation hit'),
                  _buildRuleItem('4', 'Years Max',
                      'Limit loan to 4 years (48 months) - longer loans = more interest for less value'),
                  _buildRuleItem('10%', 'Monthly Cap',
                      'Total car expenses (EMI + Fuel + Insurance) < 10% of gross income'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Input Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calculate Your Vehicle Budget',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _monthlyIncomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Your Gross Monthly Income (₹)',
                      hintText: 'e.g. 80000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Calculate My Vehicle Budget',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results
          if (_showResult) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car,
                            color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Your Vehicle Buying Budget',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildResultRow(
                        'Maximum On-Road Price',
                        _formatCurrency(_maxVehiclePrice),
                        Colors.blue,
                        Icons.directions_car),
                    _buildResultRow(
                        'Recommended Down Payment (20%)',
                        _formatCurrency(_recommendedDownPayment),
                        Colors.orange,
                        Icons.savings),
                    _buildResultRow(
                        'Maximum Loan Amount',
                        _formatCurrency(_maxLoanAmount),
                        Colors.purple,
                        Icons.account_balance),
                    _buildResultRow('Maximum Monthly EMI',
                        _formatCurrency(_maxEmi), Colors.green, Icons.payment),
                    _buildResultRow(
                        'Total Monthly Car Budget',
                        _formatCurrency(_maxTotalCarExpense),
                        Colors.teal,
                        Icons.pie_chart),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Remember: A car loses 15-20% value in the first year. Don\'t overbuy!',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Car Budget Breakdown:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildBreakdownRow('EMI', _maxEmi, 0.60),
                          _buildBreakdownRow(
                              'Fuel', _maxTotalCarExpense * 0.25, 0.25),
                          _buildBreakdownRow('Insurance & Maintenance',
                              _maxTotalCarExpense * 0.15, 0.15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
          const SizedBox(width: 12),
          Text(_formatCurrency(amount),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


