import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/paper_portfolio.dart';
import '../../models/stock.dart';
import '../../services/markets_service.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_theme.dart';
import 'stock_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  final int initialTab;
  
  const PortfolioScreen({super.key, this.initialTab = 0});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PaperPortfolio? _portfolio;
  Watchlist? _watchlist;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadData();
    // Start silent refresh timer (3 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadData(silent: true);
    });
  }

  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        MarketsService.getPortfolio(),
        MarketsService.getWatchlist(),
      ]);
      if (mounted) {
        setState(() {
          _portfolio = results[0] as PaperPortfolio?;
          _watchlist = results[1] as Watchlist?;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPortfolio() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Portfolio?'),
        content: const Text(
          'This will reset your virtual portfolio to ₹1,00,000 and remove all holdings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MarketsService.resetPortfolio();
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Portfolio reset successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting portfolio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeFromWatchlist(String symbol) async {
    final result = await MarketsService.removeFromWatchlist(symbol);
    if (result['success'] == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$symbol removed from watchlist'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('portfolio')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: context.l10n.t('retry'),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset Portfolio'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'reset') _resetPortfolio();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[500] 
              : Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 18),
                  const SizedBox(width: 8),
                  Text('${context.l10n.t('holdings')} (${_portfolio?.holdings.length ?? 0})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark, size: 18),
                  const SizedBox(width: 8),
                  Text('${context.l10n.t('watchlist')} (${_watchlist?.count ?? 0})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text('${context.l10n.t('error')}: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text(context.l10n.t('retry')),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Holdings Tab
                    _buildHoldingsTab(colorScheme),
                    // Watchlist Tab
                    _buildWatchlistTab(colorScheme),
                  ],
                ),
    );
  }

  Widget _buildHoldingsTab(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Summary Card
            _buildSummaryCard(colorScheme),
            const SizedBox(height: 24),
            // Holdings List
            _buildHoldingsList(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistTab(ColorScheme colorScheme) {
    final stocks = _watchlist?.stocks ?? [];

    return Column(
      children: [
        // Add Stock Button
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddStockDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Stock to Watchlist', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        // Watchlist content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: stocks.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border, 
                              size: 64, 
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[700] 
                                  : Colors.grey.shade400
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No stocks in watchlist',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Add Stock" above or the bookmark icon on any stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[400] 
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stocks.length,
                    itemBuilder: (context, index) {
                      final stock = stocks[index];
                      return _buildWatchlistCard(stock);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showAddStockDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStockSheet(
        onStockAdded: () {
          _loadData();
        },
      ),
    );
  }

  Widget _buildWatchlistCard(WatchlistItem stock) {
    final isProfitable = stock.isPositive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(
                symbol: stock.symbol,
                name: stock.stockName,
              ),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Stock Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isProfitable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        stock.symbol.substring(0, stock.symbol.length.clamp(0, 2)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isProfitable ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stock Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          stock.stockName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Price & Change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stock.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isProfitable
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stock.formattedChange,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isProfitable ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove, color: Colors.orange),
                    onPressed: () => _showRemoveDialog(stock),
                    tooltip: 'Remove from watchlist',
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWatchlistDetailItem('Day High', stock.formattedDayHigh, Colors.green),
                  _buildWatchlistDetailItem('Day Low', stock.formattedDayLow, Colors.red),
                  _buildWatchlistDetailItem('Change %', stock.formattedChange, isProfitable ? Colors.green : Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(WatchlistItem stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${stock.symbol}?'),
        content: const Text('Are you sure you want to remove this stock from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromWatchlist(stock.symbol);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    final portfolio = _portfolio!;
    final isProfitable = portfolio.totalPnl >= 0;
    // Use dark text on the copper/gold background for visibility
    const textColorPrimary = Color(0xFF1A1A2E);  // Deep navy for main text
    const textColorSecondary = Color(0xFF3D3D5C);  // Slightly lighter for labels

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FinzoColors.brandSecondary,
              FinzoColors.brandSecondary.withOpacity(0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💰 Net Worth',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColorPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🎮 VIRTUAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColorPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_formatCurrency(portfolio.netWorth)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColorPrimary,
              ),
            ),
            Divider(height: 32, color: textColorPrimary.withOpacity(0.2)),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Available Cash',
                    '₹${_formatCurrency(portfolio.virtualBalance)}',
                    Icons.account_balance_wallet,
                    Colors.blue.shade800,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Invested',
                    '₹${_formatCurrency(portfolio.totalInvested)}',
                    Icons.trending_up,
                    Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Current Value',
                    '₹${_formatCurrency(portfolio.currentPortfolioValue)}',
                    Icons.pie_chart,
                    Colors.purple.shade800,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Total P&L',
                    '${isProfitable ? '+' : ''}₹${_formatCurrency(portfolio.totalPnl)}',
                    isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                    isProfitable ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // P&L Percentage Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ((portfolio.totalPnlPercent.abs()) / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isProfitable ? Colors.green.shade700 : Colors.red.shade700,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${isProfitable ? '+' : ''}${portfolio.totalPnlPercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isProfitable ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    const textColorSecondary = Color(0xFF3D3D5C);  // Dark text for visibility on copper background
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: textColorSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingsList(ColorScheme colorScheme) {
    final holdings = _portfolio?.holdings ?? [];

    if (holdings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[700] 
                    : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No holdings yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your paper trading journey by buying some stocks!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: holdings.map((holding) => _buildHoldingCard(holding)).toList(),
    );
  }

  Widget _buildHoldingCard(Holding holding) {
    final isProfitable = holding.pnl >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(
                symbol: holding.symbol,
                name: holding.stockName,
              ),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Stock Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        holding.symbol.substring(0, holding.symbol.length.clamp(0, 2)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stock Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holding.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          holding.stockName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // P&L
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isProfitable ? '+' : ''}₹${holding.pnl.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isProfitable ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        '${isProfitable ? '+' : ''}${holding.pnlPercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isProfitable ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHoldingDetailItem('Qty', '${holding.quantity}'),
                  _buildHoldingDetailItem('Avg Price', '₹${holding.avgPrice.toStringAsFixed(2)}'),
                  _buildHoldingDetailItem('Current', '₹${holding.currentPrice.toStringAsFixed(2)}'),
                  _buildHoldingDetailItem('Value', '₹${_formatCurrency(holding.currentValue)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[400] 
                : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}
/// Bottom sheet for adding stocks to watchlist
class _AddStockSheet extends StatefulWidget {
  final VoidCallback onStockAdded;

  const _AddStockSheet({required this.onStockAdded});

  @override
  State<_AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<_AddStockSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Stock> _searchResults = [];
  List<Stock> _allStocks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  Set<String> _watchedSymbols = {};

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        MarketsService.getStocks(),
        MarketsService.getWatchlist(),
      ]);
      
      final stocks = results[0] as List<Stock>;
      final watchlist = results[1] as Watchlist?;
      
      setState(() {
        _allStocks = stocks;
        _searchResults = stocks;
        _watchedSymbols = (watchlist?.stocks ?? [])
            .map((s) => s.symbol.toUpperCase())
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = _allStocks);
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = _allStocks.where((stock) =>
        stock.symbol.toLowerCase().contains(lowerQuery) ||
        stock.name.toLowerCase().contains(lowerQuery)
      ).toList();
    });
  }

  Future<void> _toggleWatchlist(Stock stock) async {
    final symbol = stock.symbol.toUpperCase();
    final isWatched = _watchedSymbols.contains(symbol);
    
    setState(() => _isSearching = true);
    
    try {
      if (isWatched) {
        final result = await MarketsService.removeFromWatchlist(stock.symbol);
        if (result['success'] == true) {
          setState(() => _watchedSymbols.remove(symbol));
          widget.onStockAdded();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${stock.symbol} removed from watchlist'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } else {
        final result = await MarketsService.addToWatchlist(
          symbol: stock.symbol,
          stockName: stock.name,
        );
        if (result['success'] == true) {
          setState(() => _watchedSymbols.add(symbol));
          widget.onStockAdded();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${stock.symbol} added to watchlist'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bookmark_add, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add to Watchlist',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search stocks by name or symbol...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[900] 
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  size: 16, 
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey.shade600
                ),
                const SizedBox(width: 4),
                Text(
                  'Watchlist tracks live prices',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey.shade600, 
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Stock list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off, 
                              size: 48, 
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[700] 
                                  : Colors.grey.shade400
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No stocks found', 
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[400] 
                                    : Colors.grey.shade600
                              )
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final stock = _searchResults[index];
                          final isWatched = _watchedSymbols.contains(stock.symbol.toUpperCase());
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => _toggleWatchlist(stock),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isWatched
                                      ? Colors.orange.withOpacity(0.1)
                                      : (stock.isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    stock.symbol.substring(0, stock.symbol.length.clamp(0, 2)),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isWatched
                                          ? Colors.orange
                                          : (stock.isPositive ? Colors.green : Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                stock.symbol,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                stock.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey[400] 
                                      : Colors.grey.shade600
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        stock.formattedPrice,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        stock.formattedChangePercent,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: stock.isPositive ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isWatched ? Icons.bookmark : Icons.bookmark_border,
                                    color: isWatched ? Colors.orange : Colors.grey,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}