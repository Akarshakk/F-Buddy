import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../models/stock.dart';
import '../../models/paper_portfolio.dart';
import '../../services/markets_service.dart';
import 'trade_screen.dart';
import 'candlestick_chart_screen.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String name;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  bool _isLoading = true;
  StockDetail? _stockDetail;
  PaperPortfolio? _portfolio;
  String _selectedTimeframe = '1M';
  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '6M', '1Y'];
  bool _isInWatchlist = false;
  bool _watchlistLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkWatchlist();
  }

  Future<void> _checkWatchlist() async {
    final isWatched = await MarketsService.isInWatchlist(widget.symbol);
    if (mounted) {
      setState(() => _isInWatchlist = isWatched);
    }
  }

  Future<void> _toggleWatchlist() async {
    setState(() => _watchlistLoading = true);
    
    try {
      if (_isInWatchlist) {
        final result = await MarketsService.removeFromWatchlist(widget.symbol);
        print('[Watchlist] Remove result: $result');
        if (result['success'] == true) {
          setState(() => _isInWatchlist = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.symbol} removed from watchlist'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: ${result['message'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        final result = await MarketsService.addToWatchlist(
          symbol: widget.symbol,
          stockName: widget.name,
        );
        print('[Watchlist] Add result: $result');
        if (result['success'] == true) {
          setState(() => _isInWatchlist = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.symbol} added to watchlist'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: ${result['message'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('[Watchlist] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _watchlistLoading = false);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      MarketsService.getStockDetail(widget.symbol, timeframe: _selectedTimeframe),
      MarketsService.getPortfolio(),
    ]);
    
    if (mounted) {
      setState(() {
        _stockDetail = results[0] as StockDetail?;
        _portfolio = results[1] as PaperPortfolio?;
        _isLoading = false;
      });
    }
  }

  Holding? get _currentHolding {
    if (_portfolio == null) return null;
    try {
      // Case-insensitive comparison since backend stores uppercase
      return _portfolio!.holdings.firstWhere(
        (h) => h.symbol.toUpperCase() == widget.symbol.toUpperCase()
      );
    } catch (_) {
      return null;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: AppTextStyles.heading3.copyWith(color: textPrimary),
            ),
            Text(
              widget.name,
              style: AppTextStyles.caption.copyWith(color: textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Candlestick chart button
          IconButton(
            icon: const Icon(
              Icons.candlestick_chart_rounded,
              color: Color(0xFFF59E0B),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CandlestickChartScreen(
                    symbol: widget.symbol,
                    stockName: widget.name,
                  ),
                ),
              );
            },
            tooltip: 'Full Candlestick Chart',
          ),
          // Watchlist button
          _watchlistLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    color: _isInWatchlist ? Colors.orange : primaryColor,
                  ),
                  onPressed: _toggleWatchlist,
                  tooltip: _isInWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stockDetail == null
              ? Center(
                  child: Text(
                    'Failed to load stock data',
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Header
                        _buildPriceHeader(isDark, surfaceColor, textPrimary, textSecondary),
                        
                        // Timeframe Selector
                        _buildTimeframeSelector(isDark, surfaceColor, primaryColor, textSecondary),
                        
                        // Price Chart (Line)
                        _buildPriceChart(isDark, surfaceColor, textPrimary, textSecondary),
                        
                        // Candlestick Chart
                        _buildCandlestickChartSection(isDark, surfaceColor, textPrimary, textSecondary),
                        
                        const SizedBox(height: 16),
                        
                        // Volume Chart
                        _buildVolumeChart(isDark, surfaceColor, textPrimary, textSecondary),
                        
                        // Stock Stats
                        _buildStockStats(isDark, surfaceColor, textPrimary, textSecondary),
                        
                        // Current Holding (if any)
                        if (_currentHolding != null)
                          _buildHoldingCard(isDark, surfaceColor, textPrimary, textSecondary),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _stockDetail != null
          ? _buildTradeButtons(isDark, surfaceColor, primaryColor)
          : null,
    );
  }

  Widget _buildPriceHeader(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Price',
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stockDetail!.formattedPrice,
                    style: AppTextStyles.heading1.copyWith(color: textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _stockDetail!.isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _stockDetail!.isPositive ? Icons.trending_up : Icons.trending_down,
                      color: _stockDetail!.isPositive ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stockDetail!.formattedChangePercent,
                      style: TextStyle(
                        color: _stockDetail!.isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _stockDetail!.formattedChange,
                      style: TextStyle(
                        color: _stockDetail!.isPositive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(bool isDark, Color surfaceColor, Color primaryColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _timeframes.map((tf) {
          final isSelected = tf == _selectedTimeframe;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() => _selectedTimeframe = tf);
                _loadData();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? null : Border.all(color: textSecondary.withOpacity(0.3)),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  color: isSelected ? Colors.white : textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceChart(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    final data = _stockDetail!.historicalData;
    if (data.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No chart data available', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    final minPrice = data.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final chartColor = _stockDetail!.isPositive ? Colors.green : Colors.red;

    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Price Chart',
            style: AppTextStyles.body1.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: priceRange > 0 ? priceRange / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: textSecondary.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '₹${value.toInt()}',
                          style: TextStyle(color: textSecondary, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minPrice - (priceRange * 0.05),
                maxY: maxPrice + (priceRange * 0.05),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.close);
                    }).toList(),
                    isCurved: true,
                    color: chartColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: chartColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dataPoint = data[spot.x.toInt()];
                        return LineTooltipItem(
                          '₹${dataPoint.close.toStringAsFixed(2)}\n${dataPoint.date}',
                          TextStyle(color: chartColor, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandlestickChartSection(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    final data = _stockDetail!.historicalData;
    if (data.isEmpty) return const SizedBox.shrink();

    final minPrice = data.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🕯️ Candlestick Chart',
                style: AppTextStyles.body1.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('▲ Bull', style: TextStyle(color: Colors.green, fontSize: 10)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('▼ Bear', style: TextStyle(color: Colors.red, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildCandlestickChart(data, minPrice, maxPrice, priceRange, textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCandlestickChart(
    List<StockHistoryPoint> data,
    double minPrice,
    double maxPrice,
    double priceRange,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - 60; // Reserve space for Y-axis
        final chartHeight = constraints.maxHeight;
        
        // Calculate candle width to fit all candles in available width
        final totalCandles = data.length;
        final availableWidth = chartWidth - 10; // Some padding
        final candleWidth = (availableWidth / totalCandles * 0.7).clamp(2.0, 12.0);
        
        return Row(
          children: [
            // Y-axis labels
            SizedBox(
              width: 55,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  final price = maxPrice - (priceRange * i / 4);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '₹${price.toInt()}',
                      style: TextStyle(color: textSecondary, fontSize: 10),
                    ),
                  );
                }),
              ),
            ),
            // Candlestick chart - full width, no scroll
            Expanded(
              child: CustomPaint(
                size: Size(chartWidth, chartHeight),
                painter: CandlestickPainter(
                  data: data,
                  minPrice: minPrice - (priceRange * 0.05),
                  maxPrice: maxPrice + (priceRange * 0.05),
                  candleWidth: candleWidth,
                  chartWidth: chartWidth,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeChart(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    final data = _stockDetail!.historicalData;
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVolume = data.map((e) => e.volume).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Volume',
            style: AppTextStyles.body1.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  final isUp = e.key > 0 && data[e.key].close >= data[e.key - 1].close;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.volume.toDouble(),
                        color: isUp ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                        width: data.length > 30 ? 2 : 6,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ],
                  );
                }).toList(),
                maxY: maxVolume * 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStats(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Stock Information',
            style: AppTextStyles.body1.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Day High', '₹${_stockDetail!.dayHigh.toStringAsFixed(2)}', Colors.green, textSecondary)),
              Expanded(child: _buildStatItem('Day Low', '₹${_stockDetail!.dayLow.toStringAsFixed(2)}', Colors.red, textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('Prev Close', '₹${_stockDetail!.previousClose.toStringAsFixed(2)}', Colors.blue, textSecondary)),
              Expanded(child: _buildStatItem('Volume', _formatVolume(_stockDetail!.volume), Colors.purple, textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem('Market Cap', _stockDetail!.marketCap, Colors.orange, textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: textSecondary)),
            Text(value, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildHoldingCard(bool isDark, Color surfaceColor, Color textPrimary, Color textSecondary) {
    final holding = _currentHolding!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: holding.isProfitable ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💼 Your Holdings',
                style: AppTextStyles.body1.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: holding.isProfitable 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  holding.formattedPnlPercent,
                  style: TextStyle(
                    color: holding.isProfitable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                    Text('${holding.quantity} shares', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avg Price', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                    Text(holding.formattedAvgPrice, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invested', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                    Text(holding.formattedCurrentValue, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('P&L', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                    Text(
                      holding.formattedPnl,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: holding.isProfitable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButtons(bool isDark, Color surfaceColor, Color primaryColor) {
    final hasHolding = _currentHolding != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show holdings info if user owns this stock
            if (hasHolding) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'You own ${_currentHolding!.quantity} shares',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Avg: ₹${_currentHolding!.avgPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToTrade('BUY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline),
                        SizedBox(width: 8),
                        Text('BUY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Tooltip(
                    message: hasHolding ? 'Sell your shares' : 'You don\'t own this stock yet',
                    child: ElevatedButton(
                      onPressed: hasHolding ? () => _navigateToTrade('SELL') : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(hasHolding ? Icons.remove_circle_outline : Icons.block),
                          const SizedBox(width: 8),
                          Text(
                            hasHolding ? 'SELL' : 'NO SHARES',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTrade(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradeScreen(
          symbol: widget.symbol,
          name: widget.name,
          currentPrice: _stockDetail!.currentPrice,
          tradeType: type,
          maxSellQuantity: _currentHolding?.quantity,
          availableBalance: _portfolio?.virtualBalance ?? 0,
        ),
      ),
    ).then((_) => _loadData());
  }

  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(2)} Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(2)} L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)} K';
    }
    return volume.toString();
  }
}

/// Custom painter for rendering candlestick chart
class CandlestickPainter extends CustomPainter {
  final List<StockHistoryPoint> data;
  final double minPrice;
  final double maxPrice;
  final double candleWidth;
  final double chartWidth;

  CandlestickPainter({
    required this.data,
    required this.minPrice,
    required this.maxPrice,
    required this.candleWidth,
    required this.chartWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.height <= 0 || size.width <= 0) return;
    
    final priceRange = (maxPrice - minPrice).clamp(0.01, double.infinity);
    
    // Calculate spacing to spread candles across full width
    final totalCandles = data.length;
    final totalCandleSpace = chartWidth / totalCandles;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      // Position each candle evenly across the chart width
      final x = (i * totalCandleSpace) + (totalCandleSpace / 2);

      // Determine if bullish (green) or bearish (red)
      final isBullish = point.close >= point.open;
      final color = isBullish ? Colors.green : Colors.red;

      // Calculate Y positions (inverted because canvas Y increases downward)
      final normalizedHigh = ((point.high - minPrice) / priceRange).clamp(0.0, 1.0);
      final normalizedLow = ((point.low - minPrice) / priceRange).clamp(0.0, 1.0);
      final normalizedOpen = ((point.open - minPrice) / priceRange).clamp(0.0, 1.0);
      final normalizedClose = ((point.close - minPrice) / priceRange).clamp(0.0, 1.0);
      
      final highY = size.height - (normalizedHigh * size.height);
      final lowY = size.height - (normalizedLow * size.height);
      final openY = size.height - (normalizedOpen * size.height);
      final closeY = size.height - (normalizedClose * size.height);

      // Draw the wick (high-low line)
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Draw the body (open-close rectangle)
      final bodyTop = isBullish ? closeY : openY;
      final bodyBottom = isBullish ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      // Adjust candle width based on available space
      final actualCandleWidth = (totalCandleSpace * 0.6).clamp(2.0, 12.0);

      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - actualCandleWidth / 2,
          bodyTop,
          actualCandleWidth,
          bodyHeight,
        ),
        const Radius.circular(1),
      );
      canvas.drawRRect(bodyRect, bodyPaint);

      // Draw border for hollow candles (bullish) when candles are large enough
      if (isBullish && actualCandleWidth > 4) {
        final borderPaint = Paint()
          ..color = color.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRRect(bodyRect, borderPaint);
      }
    }

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) {
    return data != oldDelegate.data ||
        minPrice != oldDelegate.minPrice ||
        maxPrice != oldDelegate.maxPrice ||
        candleWidth != oldDelegate.candleWidth ||
        chartWidth != oldDelegate.chartWidth;
  }
}
