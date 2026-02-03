import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/stock.dart';
import '../../models/paper_portfolio.dart';
import '../../services/markets_service.dart';
import '../../widgets/auto_translated_text.dart';
import 'stock_detail_screen.dart';
import 'portfolio_screen.dart';
import 'trade_history_screen.dart';

class MarketsLabHomeScreen extends StatefulWidget {
  const MarketsLabHomeScreen({super.key});

  @override
  State<MarketsLabHomeScreen> createState() => _MarketsLabHomeScreenState();
}

class _MarketsLabHomeScreenState extends State<MarketsLabHomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  MarketOverview? _marketOverview;
  List<Stock> _stocks = [];
  PaperPortfolio? _portfolio;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state
  String _selectedFilter = 'gainers'; // 'gainers', 'losers', 'marketcap'
  String _selectedMarketCap = 'large'; // 'large', 'mid', 'small'

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      final results = await Future.wait([
        MarketsService.getMarketOverview(),
        MarketsService.getStocks(),
        MarketsService.getPortfolio(),
      ]).timeout(const Duration(seconds: 15));
      
      if (mounted) {
        setState(() {
          _marketOverview = results[0] as MarketOverview?;
          _stocks = results[1] as List<Stock>;
          _portfolio = results[2] as PaperPortfolio?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.candlestick_chart, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Markets Lab',
                  style: AppTextStyles.heading3.copyWith(color: textPrimary),
                ),
                Text(
                  'Paper Trading',
                  style: AppTextStyles.caption.copyWith(color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_balance_wallet, color: primaryColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PortfolioScreen()),
            ).then((_) => _loadData()),
            tooltip: 'Portfolio',
          ),
          IconButton(
            icon: Icon(Icons.history, color: primaryColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TradeHistoryScreen()),
            ),
            tooltip: 'Trade History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Loading market data...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load market data'),
                      const SizedBox(height: 8),
                      Text(_errorMessage, style: TextStyle(color: textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Virtual Money Banner
                    _buildVirtualMoneyBanner(isDark, primaryColor),
                    
                    // Portfolio Summary Card
                    if (_portfolio != null) _buildPortfolioCard(isDark, surfaceColor, textPrimary, textSecondary),
                    
                    // Market Indices
                    if (_marketOverview != null) _buildIndicesSection(isDark, surfaceColor, textPrimary, textSecondary),
                    
                    // Search Bar
                    _buildSearchBar(isDark, surfaceColor, textPrimary, textSecondary),
                    
                    // Filter Buttons (Gainers, Losers, Market Cap)
                    if (_searchQuery.isEmpty)
                      _buildFilterButtons(isDark, surfaceColor, textPrimary, textSecondary),
                    
                    // Filtered Stocks List
                    _buildFilteredStocksSection(isDark, surfaceColor, textPrimary, textSecondary),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVirtualMoneyBanner(bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📚 Learning Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Practice trading with ₹10 Lakh virtual money. No real money involved!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PortfolioScreen()),
      ).then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Portfolio',
                  style: AppTextStyles.body1.copyWith(color: textSecondary),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Worth',
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      Text(
                        _portfolio!.formattedNetWorth,
                        style: AppTextStyles.heading2.copyWith(color: textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _portfolio!.isProfitable 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _portfolio!.isProfitable ? Icons.trending_up : Icons.trending_down,
                        color: _portfolio!.isProfitable ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _portfolio!.formattedPnlPercent,
                        style: TextStyle(
                          color: _portfolio!.isProfitable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPortfolioStat('Available', _portfolio!.formattedBalance, Colors.blue, textSecondary),
                const SizedBox(width: 20),
                _buildPortfolioStat('Invested', _portfolio!.formattedInvested, Colors.orange, textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioStat(String label, String value, Color color, Color textSecondary) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: textSecondary)),
              Text(value, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicesSection(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Market Indices',
            style: AppTextStyles.heading3.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _marketOverview!.indices.length,
              itemBuilder: (context, index) {
                final idx = _marketOverview!.indices[index];
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(right: index < _marketOverview!.indices.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: idx.isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        idx.name,
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idx.formattedValue,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${idx.formattedChange} (${idx.formattedChangePercent})',
                        style: TextStyle(
                          color: idx.isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textPrimary),
        decoration: InputDecoration(
          hintText: 'Search stocks (e.g., RELIANCE, TCS)',
          hintStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(Icons.search, color: textSecondary),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildFilterButtons(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Gainers Button
          Expanded(
            child: _buildFilterButton(
              label: '🚀 Gainers',
              isSelected: _selectedFilter == 'gainers',
              color: Colors.green,
              onTap: () => setState(() => _selectedFilter = 'gainers'),
            ),
          ),
          const SizedBox(width: 8),
          // Losers Button
          Expanded(
            child: _buildFilterButton(
              label: '📉 Losers',
              isSelected: _selectedFilter == 'losers',
              color: Colors.red,
              onTap: () => setState(() => _selectedFilter = 'losers'),
            ),
          ),
          const SizedBox(width: 8),
          // Market Cap Dropdown
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _selectedFilter == 'marketcap' 
                    ? Colors.orange 
                    : surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFilter == 'marketcap' 
                      ? Colors.orange 
                      : Colors.grey.withOpacity(0.3),
                  width: _selectedFilter == 'marketcap' ? 2 : 1,
                ),
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = 'marketcap';
                    _selectedMarketCap = value;
                  });
                },
                offset: const Offset(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  _buildCapMenuItem('large', '🏢 Large Cap', 'Market Cap > ₹20K Cr'),
                  _buildCapMenuItem('mid', '🏛️ Mid Cap', '₹5K - ₹20K Cr'),
                  _buildCapMenuItem('small', '🏠 Small Cap', 'Market Cap < ₹5K Cr'),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedFilter == 'marketcap'
                            ? '${_selectedMarketCap[0].toUpperCase()}${_selectedMarketCap.substring(1)} Cap'
                            : 'Cap ▼',
                        style: TextStyle(
                          color: _selectedFilter == 'marketcap' 
                              ? Colors.white 
                              : textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildCapMenuItem(String value, String title, String subtitle) {
    return PopupMenuItem<String>(
      value: value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  List<Stock> get _getFilteredStocks {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      return _stocks.where((stock) =>
        stock.symbol.toLowerCase().contains(query) ||
        stock.name.toLowerCase().contains(query)
      ).toList();
    }

    switch (_selectedFilter) {
      case 'gainers':
        return _marketOverview?.topGainers ?? [];
      case 'losers':
        return _marketOverview?.topLosers ?? [];
      case 'marketcap':
        // Return filtered stocks by market cap category from the full list
        return _getStocksByMarketCap(_selectedMarketCap);
      default:
        return _marketOverview?.topGainers ?? [];
    }
  }

  List<Stock> _getStocksByMarketCap(String cap) {
    // Market cap categorization based on typical Indian stock classification
    // Large Cap: > 20,000 Cr (typically Nifty 50 stocks)
    // Mid Cap: 5,000 - 20,000 Cr
    // Small Cap: < 5,000 Cr
    
    // For demonstration, we'll categorize based on stock price as a proxy
    // In real implementation, you'd have actual market cap data
    final Map<String, List<String>> capCategories = {
      'large': ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'ICICIBANK', 'HINDUNILVR', 'BHARTIARTL', 'SBIN', 'KOTAKBANK', 'LT'],
      'mid': ['TITAN', 'BAJFINANCE', 'ASIANPAINT', 'MARUTI', 'AXISBANK', 'HCLTECH', 'WIPRO', 'SUNPHARMA', 'ITC'],
      'small': ['TATAMOTORS', 'INDUSINDBK', 'HINDALCO', 'ADANIPORTS', 'BPCL', 'NTPC', 'ONGC', 'GRASIM', 'JSWSTEEL', 'COALINDIA'],
    };

    final targetSymbols = capCategories[cap] ?? [];
    
    // Filter from available stocks
    final filteredFromStocks = _stocks.where((s) => 
      targetSymbols.any((t) => s.symbol.toUpperCase().contains(t))
    ).toList();

    // If we have matching stocks, return them
    if (filteredFromStocks.isNotEmpty) {
      return filteredFromStocks;
    }

    // Fallback: divide the available stocks by price tiers
    final sortedByPrice = [..._stocks]..sort((a, b) => b.price.compareTo(a.price));
    final third = (sortedByPrice.length / 3).ceil();
    
    switch (cap) {
      case 'large':
        return sortedByPrice.take(third).toList();
      case 'mid':
        return sortedByPrice.skip(third).take(third).toList();
      case 'small':
        return sortedByPrice.skip(third * 2).toList();
      default:
        return sortedByPrice;
    }
  }

  Widget _buildFilteredStocksSection(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    final stocks = _getFilteredStocks;
    
    String title;
    Color? accentColor;
    
    if (_searchQuery.isNotEmpty) {
      title = '🔍 Search Results';
      accentColor = Colors.orange;
    } else {
      switch (_selectedFilter) {
        case 'gainers':
          title = '🚀 Top Gainers';
          accentColor = Colors.green;
          break;
        case 'losers':
          title = '📉 Top Losers';
          accentColor = Colors.red;
          break;
        case 'marketcap':
          final capEmoji = _selectedMarketCap == 'large' ? '🏢' : (_selectedMarketCap == 'mid' ? '🏛️' : '🏠');
          title = '$capEmoji ${_selectedMarketCap[0].toUpperCase()}${_selectedMarketCap.substring(1)} Cap Stocks';
          accentColor = Colors.orange;
          break;
        default:
          title = '📈 Stocks';
          accentColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.heading3.copyWith(color: textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stocks.length} stocks',
                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stocks.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'No stocks found',
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                return _buildStockListItem(stock, surfaceColor, textPrimary, textSecondary, accentColor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStockListItem(Stock stock, Color surfaceColor, Color textPrimary, Color textSecondary, Color? accentColor) {
    final displayColor = accentColor ?? (stock.isPositive ? Colors.green : Colors.red);
    
    return GestureDetector(
      onTap: () => _navigateToStockDetail(stock),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: displayColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: stock.isPositive 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stock.symbol.substring(0, stock.symbol.length > 2 ? 2 : stock.symbol.length),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: stock.isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    stock.name,
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.formattedPrice,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stock.isPositive 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stock.formattedChangePercent,
                    style: TextStyle(
                      color: stock.isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }

  void _navigateToStockDetail(Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailScreen(symbol: stock.symbol, name: stock.name),
      ),
    ).then((_) => _loadData());
  }
}
