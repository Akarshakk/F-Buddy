import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// ITR Filing Page with step-by-step guide
class ItrFilingPage extends StatelessWidget {
  const ItrFilingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade500]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.description, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ITR Filing Guide',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      Text('Step-by-step process for AY 2026-27',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Step 1: Document Collection
          _buildStep(1, 'Document Collection', Colors.blue, Icons.folder, [
            _StepItem('Form 16', 'Salary & TDS details from employer'),
            _StepItem(
                'AIS & TIS', 'Annual Information Statement from IT portal'),
            _StepItem('Bank Certificates', 'Interest from savings & FDs'),
            _StepItem('Capital Gains', 'Reports from broker/mutual fund'),
            _StepItem(
                'Investment Proofs', 'Insurance & other tax-saving receipts'),
          ]),

          // Step 2: Portal Access
          _buildPortalAccessStep(),

          // Step 3: ITR Form Selection
          _buildItrFormTable(),

          // Step 4: Assessment Year
          _buildStep(
              4, 'Assessment Year', Colors.orange, Icons.calendar_month, [
            _StepItem('FY 2025-26', 'April 1, 2025 to March 31, 2026'),
            _StepItem('AY 2026-27', 'Applicable assessment year for filing'),
          ]),

          // Step 5: Pre-filled Data
          _buildStep(
              5, 'Verify Pre-Filled Data', Colors.cyan, Icons.fact_check, [
            _StepItem('Auto-filled', 'Salary, interest, TDS are pre-populated'),
            _StepItem('Cross-verify', 'Match with Form 16 and AIS'),
            _StepItem('Report errors', 'Fix discrepancies before proceeding'),
          ]),

          // Step 6: Deductions
          _buildStep(6, 'Submit Deductions (Old Regime)', Colors.green,
              Icons.savings, [
            _StepItem('80C', 'Investments, insurance, home loan principal'),
            _StepItem('80D', 'Medical insurance premiums'),
            _StepItem('80CCD(1B)', 'Additional NPS contributions'),
            _StepItem('Section 24', 'Home loan interest'),
            _StepItem('80G', 'Charitable donations'),
          ]),

          // Step 7: Tax Computation
          _buildStep(7, 'Tax Computation', Colors.indigo, Icons.calculate, [
            _StepItem('Compare', 'Check tax under Old vs New regime'),
            _StepItem('Choose wisely', 'Select regime with lower tax'),
          ]),

          // Step 8: Pay Outstanding Tax
          _buildStep(8, 'Pay Outstanding Tax', Colors.red, Icons.payment, [
            _StepItem('Check liability', 'Total tax - TDS - Advance tax paid'),
            _StepItem('Self-assessment', 'Pay balance before submission'),
            _StepItem('Avoid penalties', 'Late payment attracts interest'),
          ]),

          // Step 9: E-Verification
          _buildStep(9, 'E-Verification (Mandatory)', Colors.amber.shade700,
              Icons.verified, [
            _StepItem('Deadline', 'Within 30 days of filing'),
            _StepItem('Aadhaar OTP', 'Quick verification via Aadhaar'),
            _StepItem('Net Banking', 'Through bank account EVC'),
            _StepItem('DSC', 'Digital Signature Certificate'),
          ]),

          // Step 10: Acknowledgment
          _buildStep(10, 'Save Acknowledgment', Colors.teal, Icons.download, [
            _StepItem('ITR-V', 'Download after successful verification'),
            _StepItem('Proof', 'Required for loans & visa applications'),
            _StepItem('Keep safe', 'Store for at least 6 years'),
          ]),

          // Essential Rules
          _buildRulesSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, Color color, IconData icon,
      List<_StepItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$number',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_right, size: 18, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                  children: [
                                    TextSpan(
                                        text: '${item.title}: ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: item.desc),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalAccessStep() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: Colors.purple, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('2',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.login, color: Colors.purple),
                const SizedBox(width: 8),
                const Text('Portal Access',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPortalItem(
                    'Website', 'https://www.incometax.gov.in/iec/foportal/'),
                _buildNormalItem('User ID', 'Your PAN number'),
                _buildNormalItem('Authentication', 'Password or OTP to mobile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalItem(String title, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 18, color: Colors.purple),
          const SizedBox(width: 8),
          Text('$title: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: InkWell(
              onTap: () => _launchUrl(url),
              child: Text(
                url,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 18, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Fallback: try without mode parameter
      await launchUrl(url);
    }
  }

  Widget _buildItrFormTable() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.deepPurple, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('3',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Icon(Icons.assignment, color: Colors.deepPurple.shade700),
                const SizedBox(width: 8),
                Text('Select Correct ITR Form',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFormRow('ITR-1', 'Salary + 1 House + Interest (≤₹50L)',
                    Colors.blue),
                _buildFormRow('ITR-2', 'Capital Gains / Foreign Assets / >₹50L',
                    Colors.orange),
                _buildFormRow(
                    'ITR-3', 'Business / Professional Income', Colors.green),
                _buildFormRow(
                    'ITR-4', 'Presumptive Income (44AD/44ADA)', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(String form, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: Text(form,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(description, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text('Essential Compliance Rules',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700)),
              ],
            ),
            const SizedBox(height: 12),
            _buildRuleItem('Full Disclosure', 'Never omit any income source'),
            _buildRuleItem('Declare Losses',
                'Capital losses can offset gains for 8 years'),
            _buildRuleItem('Keep Records', 'Maintain proofs for 6 years'),
            _buildRuleItem(
                'Zero-Tax Returns', 'File even if income is below limit'),
            _buildRuleItem('Early Filing', 'Avoid deadline-day portal issues'),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem {
  final String title;
  final String desc;
  _StepItem(this.title, this.desc);
}
