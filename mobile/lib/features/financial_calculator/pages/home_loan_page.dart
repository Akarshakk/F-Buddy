import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Home Loan Affordability Calculator using 3-20-30-40 Rule
class HomeLoanPage extends StatefulWidget {
  const HomeLoanPage({super.key});

  @override
  State<HomeLoanPage> createState() => _HomeLoanPageState();
}

class _HomeLoanPageState extends State<HomeLoanPage> {
  final _monthlyIncomeController = TextEditingController();
  bool _showResult = false;

  double _maxEmi = 0;
  double _maxHomePrice = 0;
  double _recommendedDownPayment = 0;
  double _loanAmount = 0;

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

    final annualIncome = monthlyIncome * 12;

    setState(() {
      // 3-20-30-40 Rule
      _maxHomePrice = annualIncome * 3; // 3x annual income
      _maxEmi = monthlyIncome * 0.30; // 30% of monthly income
      _recommendedDownPayment = _maxHomePrice * 0.40; // 40% down payment
      _loanAmount = _maxHomePrice - _recommendedDownPayment;
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
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'The 3-20-30-40 Rule',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A balanced approach recommended by financial planners in India:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildRuleItem(
                      '3', 'Home Price', 'Should be ≤ 3x your annual income'),
                  _buildRuleItem('20', 'Tenure',
                      'Limit loan tenure to 20 years (saves lakhs in interest)'),
                  _buildRuleItem('30', 'EMI',
                      'Keep all EMIs under 30% of monthly take-home pay'),
                  _buildRuleItem('40', 'Down Payment',
                      'Aim for 40% down payment to reduce debt burden'),
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
                    'Calculate Your Home Budget',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _monthlyIncomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Your Monthly Take-Home Income (₹)',
                      hintText: 'e.g. 100000',
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Calculate My Home Budget',
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
                        Icon(Icons.home,
                            color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Your Home Buying Budget',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildResultRow(
                        'Maximum Home Price',
                        _formatCurrency(_maxHomePrice),
                        Colors.blue,
                        Icons.home),
                    _buildResultRow(
                        'Recommended Down Payment (40%)',
                        _formatCurrency(_recommendedDownPayment),
                        Colors.orange,
                        Icons.savings),
                    _buildResultRow(
                        'Maximum Loan Amount',
                        _formatCurrency(_loanAmount),
                        Colors.purple,
                        Icons.account_balance),
                    _buildResultRow('Maximum Monthly EMI',
                        _formatCurrency(_maxEmi), Colors.green, Icons.payment),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tips_and_updates,
                              color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pro Tip: A 20-year loan saves you 30-40% interest compared to a 30-year loan!',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.amber.shade900),
                            ),
                          ),
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
}


