import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/app_theme.dart';

class LoanDashboardPage extends StatefulWidget {
  const LoanDashboardPage({super.key});

  @override
  State<LoanDashboardPage> createState() => _LoanDashboardPageState();
}

class _LoanDashboardPageState extends State<LoanDashboardPage> {
  final List<Map<String, dynamic>> _loans = [];
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _emiController = TextEditingController();

  void _addLoan() {
    if (_nameController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      setState(() {
        _loans.add({
          'name': _nameController.text,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'emi': double.tryParse(_emiController.text) ?? 0.0,
        });
        _nameController.clear();
        _amountController.clear();
        _emiController.clear();
      });
    }
  }

  String _formatNumber(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)} Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)} L';
    return value.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _emiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = FinzoTheme.surface(context);

    // Calculations
    final totalDebt =
        _loans.fold<double>(0, (sum, l) => sum + (l['amount'] as double));
    final totalMonthlyEmi =
        _loans.fold<double>(0, (sum, l) => sum + (l['emi'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [FinzoColors.brandSecondary, FinzoColors.brandSecondary.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: FinzoColors.brandSecondary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryVal('Total Debt', '₹${_formatNumber(totalDebt)}'),
                _buildSummaryVal(
                    'Monthly EMI', '₹${_formatNumber(totalMonthlyEmi)}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add Loan Section
          Card(
            color: surfaceColor,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Loan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Loan Name',
                          border: OutlineInputBorder(),
                          isDense: true)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Amount (₹)',
                                  border: OutlineInputBorder(),
                                  isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: _emiController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'EMI (₹)',
                                  border: OutlineInputBorder(),
                                  isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addLoan,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Loan'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: FinzoColors.brandSecondary, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Chart
          if (_loans.isNotEmpty) ...[
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: surfaceColor, borderRadius: BorderRadius.circular(16)),
              child: PieChart(
                PieChartData(
                  sections: _loans.asMap().entries.map((e) {
                    final val = e.value['amount'] as double;
                    return PieChartSectionData(
                      value: val,
                      title: '${((val / totalDebt) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      color: Colors.primaries[e.key % Colors.primaries.length],
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Loan List
          if (_loans.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loans.length,
              itemBuilder: (ctx, i) {
                final l = _loans[i];
                return Card(
                  color: surfaceColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.red)),
                    title: Text(l['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('EMI: ₹${_formatNumber(l['emi'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${_formatNumber(l['amount'])}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () =>
                                setState(() => _loans.removeAt(i))),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryVal(String label, String val) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}


