import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'calculators/inflation_calculator.dart';
import 'calculators/investment_return_calculator.dart';
import 'calculators/retirement_calculator.dart';
import 'calculators/sip_calculator.dart';
import 'calculators/emi_calculator.dart';
import 'calculators/emergency_fund_calculator.dart';
import 'calculators/health_insurance_calculator.dart';
import 'calculators/term_insurance_calculator.dart';

/// Personal Finance Manager Screen
/// Yellow sidebar with 8 calculator options, content panel on right
class FinanceManagerScreen extends StatefulWidget {
  const FinanceManagerScreen({super.key});

  @override
  State<FinanceManagerScreen> createState() => _FinanceManagerScreenState();
}

class _FinanceManagerScreenState extends State<FinanceManagerScreen> {
  int _selectedIndex = 0;

  final List<_SidebarItem> _menuItems = [
    _SidebarItem(icon: Icons.trending_up, title: 'Inflation Calculator'),
    _SidebarItem(icon: Icons.show_chart, title: 'Investment Return'),
    _SidebarItem(icon: Icons.beach_access, title: 'Retirement Corpus'),
    _SidebarItem(icon: Icons.savings, title: 'SIP Calculator'),
    _SidebarItem(icon: Icons.home, title: 'EMI Calculator'),
    _SidebarItem(icon: Icons.shield, title: 'Emergency Fund'),
    _SidebarItem(icon: Icons.health_and_safety, title: 'Health Insurance'),
    _SidebarItem(icon: Icons.security, title: 'Term Insurance'),
  ];

  Widget _getCalculatorWidget(int index) {
    switch (index) {
      case 0:
        return const InflationCalculator();
      case 1:
        return const InvestmentReturnCalculator();
      case 2:
        return const RetirementCalculator();
      case 3:
        return const SipCalculator();
      case 4:
        return const EmiCalculator();
      case 5:
        return const EmergencyFundCalculator();
      case 6:
        return const HealthInsuranceCalculator();
      case 7:
        return const TermInsuranceCalculator();
      default:
        return const InflationCalculator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: isWide ? null : _buildDrawer(user),
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black87,
              title: Text(_menuItems[_selectedIndex].title),
              elevation: 0,
            ),
      body: isWide
          ? Row(
              children: [
                _buildSidebar(user),
                Expanded(child: _buildContentPanel()),
              ],
            )
          : _buildContentPanel(),
    );
  }

  Widget _buildDrawer(dynamic user) {
    return Drawer(
      backgroundColor: const Color(0xFFFFC107),
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileCard(user),
            const Divider(color: Colors.black12),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) => _buildMenuItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(dynamic user) {
    return Container(
      width: 260,
      color: const Color(0xFFFFC107),
      child: SafeArea(
        child: Column(
          children: [
            // Logo and menu icon
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            _buildProfileCard(user),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) => _buildMenuItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A6EA5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user?.name ?? 'User'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.email ?? 'user@email.com',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final item = _menuItems[index];
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? Colors.white : Colors.black87,
          size: 22,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        onTap: () {
          setState(() => _selectedIndex = index);
          if (MediaQuery.of(context).size.width <= 800) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildContentPanel() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'App',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Text(' / ', style: TextStyle(color: Colors.grey)),
                Text(
                  _menuItems[_selectedIndex].title,
                  style: const TextStyle(
                      color: Colors.teal,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Calculator content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _getCalculatorWidget(_selectedIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String title;

  _SidebarItem({required this.icon, required this.title});
}
