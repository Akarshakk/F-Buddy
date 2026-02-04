import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/markets_service.dart';
import '../../config/theme.dart';
import '../../models/stock.dart';

class StockComparatorScreen extends StatefulWidget {
  const StockComparatorScreen({super.key});

  @override
  State<StockComparatorScreen> createState() => _StockComparatorScreenState();
}

class _StockComparatorScreenState extends State<StockComparatorScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _selectedSymbols = [];
  StockComparison? _comparison;
  bool _isLoading = false;
  bool _isSearching = false;
  List<Stock> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;

  // Popular stocks for quick selection
  final List<Map<String, String>> _popularStocks = [
    {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'sector': 'Energy'},
    {'symbol': 'TCS', 'name': 'Tata Consultancy', 'sector': 'IT'},
    {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'sector': 'Banking'},
    {'symbol': 'INFY', 'name': 'Infosys', 'sector': 'IT'},
    {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'sector': 'Banking'},
    {'symbol': 'SBIN', 'name': 'State Bank of India', 'sector': 'Banking'},
    {'symbol': 'WIPRO', 'name': 'Wipro', 'sector': 'IT'},
    {'symbol': 'ITC', 'name': 'ITC Ltd', 'sector': 'FMCG'},
    {'symbol': 'TATAMOTORS', 'name': 'Tata Motors', 'sector': 'Auto'},
    {'symbol': 'LT', 'name': 'Larsen & Toubro', 'sector': 'Infra'},
    {'symbol': 'MARUTI', 'name': 'Maruti Suzuki', 'sector': 'Auto'},
    {'symbol': 'ASIANPAINT', 'name': 'Asian Paints', 'sector': 'Paints'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _searchStocks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await MarketsService.searchStocks(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _toggleStock(String symbol) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSymbols.contains(symbol)) {
        _selectedSymbols.remove(symbol);
        _comparison = null;
      } else if (_selectedSymbols.length < 3) {
        _selectedSymbols.add(symbol);
        _comparison = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Maximum 3 stocks can be compared'),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  Future<void> _compareStocks() async {
    if (_selectedSymbols.length < 2) return;

    setState(() => _isLoading = true);
    final comparison = await MarketsService.compareStocks(_selectedSymbols);
    setState(() {
      _comparison = comparison;
      _isLoading = false;
    });
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E17) : const Color(0xFFF8F9FA);
    final surfaceColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0A0E17) : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 16, color: textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withOpacity(0.8),
                      isDark ? const Color(0xFF1A1F2E) : const Color(0xFF34D399),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stock Comparator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Compare up to 3 stocks side by side',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_selectedSymbols.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSymbols.clear();
                      _comparison = null;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  label: const Text('Reset', style: TextStyle(color: Colors.white)),
                ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search stocks to compare...',
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _searchStocks('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: _searchStocks,
              ),
            ),
          ),

          // Search Results
          if (_searchResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 180),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final stock = _searchResults[index];
                    final isSelected = _selectedSymbols.contains(stock.symbol);
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                  stock.symbol[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                        ),
                      ),
                      title: Text(stock.symbol, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                      subtitle: Text(stock.name, style: TextStyle(fontSize: 12, color: textSecondary)),
                      trailing: Text(
                        '₹${stock.price.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      onTap: () {
                        _toggleStock(stock.symbol);
                        _searchController.clear();
                        _searchStocks('');
                      },
                    );
                  },
                ),
              ),
            ),

          // Selected Stocks Pills
          if (_selectedSymbols.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Selected Stocks',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedSymbols.length}/3',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSymbols.asMap().entries.map((entry) {
                        final colors = [
                          const Color(0xFF6366F1),
                          const Color(0xFFF59E0B),
                          const Color(0xFFEF4444),
                        ];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors[entry.key].withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors[entry.key].withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors[entry.key],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors[entry.key],
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _toggleStock(entry.value),
                                child: Icon(Icons.close, size: 16, color: colors[entry.key]),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    // Compare Button
                    if (_selectedSymbols.length >= 2 && _comparison == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _compareStocks,
                            icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
                            label: Text(
                              'Compare ${_selectedSymbols.length} Stocks',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Comparison Results or Stock Selection
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF10B981)),
                    SizedBox(height: 16),
                    Text('Analyzing stocks...'),
                  ],
                ),
              ),
            )
          else if (_comparison != null)
            SliverToBoxAdapter(
              child: _buildComparisonResults(isDark, surfaceColor, textPrimary, textSecondary),
            )
          else
            SliverToBoxAdapter(
              child: _buildStockSelection(isDark, surfaceColor, textPrimary, textSecondary),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildStockSelection(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Popular Stocks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to select stocks for comparison',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          
          // Stock Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _popularStocks.length,
            itemBuilder: (context, index) {
              final stock = _popularStocks[index];
              final isSelected = _selectedSymbols.contains(stock['symbol']);
              final selectedIndex = _selectedSymbols.indexOf(stock['symbol']!);
              final colors = [
                const Color(0xFF6366F1),
                const Color(0xFFF59E0B),
                const Color(0xFFEF4444),
              ];

              return GestureDetector(
                onTap: () => _toggleStock(stock['symbol']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors[selectedIndex].withOpacity(0.15)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colors[selectedIndex]
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? colors[selectedIndex].withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors[selectedIndex]
                                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Text(
                                      stock['symbol']![0],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stock['sector']!,
                              style: TextStyle(
                                fontSize: 9,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stock['symbol']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? colors[selectedIndex] : textPrimary,
                        ),
                      ),
                      Text(
                        stock['name']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildComparisonResults(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    final stocks = _comparison!.stocks;
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animValue = Curves.easeOutCubic.transform(_animController.value);
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Cards Row
            Row(
              children: stocks.asMap().entries.map((entry) {
                final stock = entry.value;
                final color = colors[entry.key];
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: entry.key < stocks.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              stock.symbol[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stock.symbol,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '₹${stock.currentPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stock.changePercent >= 0
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stock.changePercent >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Comparison Metrics
            _buildMetricCard('Price Comparison', [
              _buildMetricRow('Current Price', stocks.map((s) => '₹${s.currentPrice.toStringAsFixed(0)}').toList(), colors, stocks.map((s) => s.currentPrice).toList(), true),
              _buildMetricRow('Day High', stocks.map((s) => '₹${s.dayHigh.toStringAsFixed(0)}').toList(), colors, stocks.map((s) => s.dayHigh).toList(), true),
              _buildMetricRow('Day Low', stocks.map((s) => '₹${s.dayLow.toStringAsFixed(0)}').toList(), colors, stocks.map((s) => s.dayLow).toList(), false),
              _buildMetricRow('52W High', stocks.map((s) => '₹${s.yearHigh.toStringAsFixed(0)}').toList(), colors, stocks.map((s) => s.yearHigh).toList(), true),
              _buildMetricRow('52W Low', stocks.map((s) => '₹${s.yearLow.toStringAsFixed(0)}').toList(), colors, stocks.map((s) => s.yearLow).toList(), false),
            ], isDark, surfaceColor, textPrimary, textSecondary),
            
            const SizedBox(height: 12),
            
            _buildMetricCard('Fundamentals', [
              _buildMetricRow('P/E Ratio', stocks.map((s) => s.pe.toStringAsFixed(1)).toList(), colors, stocks.map((s) => s.pe).toList(), false),
              _buildMetricRow('P/B Ratio', stocks.map((s) => s.pb.toStringAsFixed(2)).toList(), colors, stocks.map((s) => s.pb).toList(), false),
              _buildMetricRow('EPS', stocks.map((s) => '₹${s.eps.toStringAsFixed(1)}').toList(), colors, stocks.map((s) => s.eps).toList(), true),
              _buildMetricRow('Div Yield', stocks.map((s) => '${s.dividend.toStringAsFixed(2)}%').toList(), colors, stocks.map((s) => s.dividend).toList(), true),
            ], isDark, surfaceColor, textPrimary, textSecondary),
            
            const SizedBox(height: 12),
            
            _buildMetricCard('Market Data', [
              _buildMetricRow('Volume', stocks.map((s) => _formatVolume(s.volume)).toList(), colors, stocks.map((s) => s.volume.toDouble()).toList(), true),
              _buildMetricRow('Market Cap', stocks.map((s) => s.marketCap).toList(), colors, null, null),
            ], isDark, surfaceColor, textPrimary, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, List<Widget> rows, bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, List<String> values, List<Color> colors, List<double>? numericValues, bool? higherIsBetter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find best value
    int? bestIndex;
    if (numericValues != null && higherIsBetter != null && numericValues.every((v) => v > 0)) {
      if (higherIsBetter) {
        final maxVal = numericValues.reduce((a, b) => a > b ? a : b);
        bestIndex = numericValues.indexOf(maxVal);
      } else {
        final minVal = numericValues.reduce((a, b) => a < b ? a : b);
        bestIndex = numericValues.indexOf(minVal);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ...values.asMap().entries.map((entry) {
            final isBest = bestIndex == entry.key;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: EdgeInsets.only(left: entry.key > 0 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isBest ? colors[entry.key].withOpacity(0.15) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBest)
                      Icon(Icons.emoji_events, size: 12, color: colors[entry.key]),
                    if (isBest) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isBest ? FontWeight.bold : FontWeight.w500,
                          color: isBest ? colors[entry.key] : (isDark ? Colors.white : Colors.black87),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(1)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
}
