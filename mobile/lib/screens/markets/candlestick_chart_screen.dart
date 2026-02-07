import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/markets_service.dart';

// Candlestick accent color (amber/gold for charts)
const _candlestickAccent = Color(0xFFF59E0B);

class CandlestickChartScreen extends StatefulWidget {
  final String symbol;
  final String stockName;

  const CandlestickChartScreen({
    super.key,
    required this.symbol,
    required this.stockName,
  });

  @override
  State<CandlestickChartScreen> createState() => _CandlestickChartScreenState();
}

class _CandlestickChartScreenState extends State<CandlestickChartScreen>
    with SingleTickerProviderStateMixin {
  CandlestickData? _data;
  bool _isLoading = true;
  String _selectedTimeframe = '1M';
  bool _showVolume = true;
  bool _showSMA = true;
  int? _selectedCandleIndex;
  late AnimationController _animController;

  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '6M', '1Y'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await MarketsService.getCandlestickData(
      widget.symbol,
      timeframe: _selectedTimeframe,
    );
    setState(() {
      _data = data;
      _isLoading = false;
      _selectedCandleIndex = null;
    });
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E17) : Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol, style: const TextStyle(fontSize: 18)),
            Text(
              widget.stockName,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF0A0E17) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showVolume ? Icons.bar_chart : Icons.bar_chart_outlined,
              color: _showVolume ? _candlestickAccent : null,
            ),
            tooltip: 'Toggle Volume',
            onPressed: () => setState(() => _showVolume = !_showVolume),
          ),
          IconButton(
            icon: Icon(
              Icons.show_chart,
              color: _showSMA ? _candlestickAccent : null,
            ),
            tooltip: 'Toggle SMA',
            onPressed: () => setState(() => _showSMA = !_showSMA),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timeframe Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: isDark ? const Color(0xFF0A0E17) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _timeframes.map((tf) {
                final isSelected = _selectedTimeframe == tf;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTimeframe = tf);
                    _loadData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _candlestickAccent
                          : (isDark ? const Color(0xFF1A1F2E) : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tf,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data == null
                    ? _buildErrorState(isDark)
                    : _buildChartContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load chart data',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Selected Candle Info
          if (_selectedCandleIndex != null)
            _buildSelectedCandleInfo(isDark),

          // Candlestick Chart
          Container(
            height: 350,
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: CandlestickPainter(
                    candles: _data!.candles,
                    animationValue: Curves.easeOutCubic.transform(_animController.value),
                    isDark: isDark,
                    showVolume: _showVolume,
                    showSMA: _showSMA,
                    sma20: _data!.indicators.sma20,
                    selectedIndex: _selectedCandleIndex,
                  ),
                );
              },
            ),
          ),

          // Touch Overlay for Selection
          SizedBox(
            height: 60,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_data != null && _data!.candles.isNotEmpty) {
                  final width = MediaQuery.of(context).size.width - 32;
                  final candleWidth = width / _data!.candles.length;
                  final index = (details.localPosition.dx / candleWidth).floor();
                  if (index >= 0 && index < _data!.candles.length) {
                    setState(() => _selectedCandleIndex = index);
                  }
                }
              },
              onTap: () => setState(() => _selectedCandleIndex = null),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Technical Indicators Card
          _buildIndicatorsCard(isDark),

          // Patterns Detected
          if (_data!.patterns.isNotEmpty)
            _buildPatternsCard(isDark),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSelectedCandleInfo(bool isDark) {
    final candle = _data!.candles[_selectedCandleIndex!];
    final isGreen = candle.close >= candle.open;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            candle.date,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOHLCItem('Open', candle.open, isDark),
              _buildOHLCItem('High', candle.high, isDark, color: Colors.green),
              _buildOHLCItem('Low', candle.low, isDark, color: Colors.red),
              _buildOHLCItem('Close', candle.close, isDark,
                  color: isGreen ? Colors.green : Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Volume: ${_formatVolume(candle.volume)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOHLCItem(String label, double value, bool isDark, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorsCard(bool isDark) {
    final indicators = _data!.indicators;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
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
          Row(
            children: [
              const Icon(Icons.analytics, size: 20),
              const SizedBox(width: 8),
              Text(
                'Technical Indicators',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Trend Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: indicators.trend == 'bullish'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      indicators.trend == 'bullish'
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: indicators.trend == 'bullish' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      indicators.trend?.toUpperCase() ?? 'NEUTRAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: indicators.trend == 'bullish' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (indicators.rsiSignal != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRSIColor(indicators.rsiSignal).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    indicators.rsiSignal!.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRSIColor(indicators.rsiSignal),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Indicators Grid
          Row(
            children: [
              Expanded(
                child: _buildIndicatorItem(
                  'RSI (14)',
                  indicators.rsi?.toStringAsFixed(2) ?? 'N/A',
                  Icons.speed,
                  _getRSIColor(indicators.rsiSignal),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildIndicatorItem(
                  'MACD',
                  indicators.macd?.toStringAsFixed(2) ?? 'N/A',
                  Icons.compare_arrows,
                  (indicators.macd ?? 0) > 0 ? Colors.green : Colors.red,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIndicatorItem(
                  'SMA 20',
                  indicators.sma20 != null ? '₹${indicators.sma20!.toStringAsFixed(2)}' : 'N/A',
                  Icons.show_chart,
                  Colors.blue,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildIndicatorItem(
                  'SMA 50',
                  indicators.sma50 != null ? '₹${indicators.sma50!.toStringAsFixed(2)}' : 'N/A',
                  Icons.timeline,
                  Colors.orange,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
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
          Row(
            children: [
              const Icon(Icons.pattern, size: 20),
              const SizedBox(width: 8),
              Text(
                'Patterns Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_data!.patterns.take(5).map((pattern) => _buildPatternItem(pattern, isDark))),
        ],
      ),
    );
  }

  Widget _buildPatternItem(CandlePattern pattern, bool isDark) {
    Color patternColor;
    IconData patternIcon;

    switch (pattern.type) {
      case 'bullish':
        patternColor = Colors.green;
        patternIcon = Icons.arrow_upward;
        break;
      case 'bearish':
        patternColor = Colors.red;
        patternIcon = Icons.arrow_downward;
        break;
      default:
        patternColor = Colors.amber;
        patternIcon = Icons.remove;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: patternColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: patternColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: patternColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                pattern.icon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pattern.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(patternIcon, size: 16, color: patternColor),
                  ],
                ),
                Text(
                  pattern.significance,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            pattern.date,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRSIColor(String? signal) {
    switch (signal) {
      case 'overbought':
        return Colors.red;
      case 'oversold':
        return Colors.green;
      default:
        return Colors.grey;
    }
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

// Custom Painter for Candlestick Chart
class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double animationValue;
  final bool isDark;
  final bool showVolume;
  final bool showSMA;
  final double? sma20;
  final int? selectedIndex;

  CandlestickPainter({
    required this.candles,
    required this.animationValue,
    required this.isDark,
    required this.showVolume,
    required this.showSMA,
    this.sma20,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final chartHeight = showVolume ? size.height * 0.75 : size.height;
    final volumeHeight = showVolume ? size.height * 0.2 : 0;
    final volumeTop = chartHeight + 10;

    // Find min/max for scaling
    double minPrice = candles.map((c) => c.low).reduce(math.min);
    double maxPrice = candles.map((c) => c.high).reduce(math.max);
    final priceRange = maxPrice - minPrice;
    minPrice -= priceRange * 0.05;
    maxPrice += priceRange * 0.05;

    final maxVolume = candles.map((c) => c.volume).reduce(math.max);

    final candleWidth = size.width / candles.length;
    final bodyWidth = candleWidth * 0.7;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.grey[800] : Colors.grey[300])!
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate SMA points if showing
    List<Offset> smaPoints = [];
    if (showSMA && candles.length >= 20) {
      for (int i = 19; i < candles.length; i++) {
        final smaSum = candles.sublist(i - 19, i + 1).fold(0.0, (sum, c) => sum + c.close);
        final smaValue = smaSum / 20;
        final x = candleWidth * i + candleWidth / 2;
        final y = chartHeight - ((smaValue - minPrice) / (maxPrice - minPrice) * chartHeight);
        smaPoints.add(Offset(x, y));
      }
    }

    // Draw SMA line
    if (showSMA && smaPoints.length >= 2) {
      final smaPaint = Paint()
        ..color = Colors.blue.withOpacity(0.7 * animationValue)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(smaPoints.first.dx, smaPoints.first.dy);
      for (int i = 1; i < smaPoints.length; i++) {
        path.lineTo(smaPoints[i].dx, smaPoints[i].dy);
      }
      canvas.drawPath(path, smaPaint);
    }

    // Draw candles
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = candleWidth * i + candleWidth / 2;
      
      final isGreen = candle.close >= candle.open;
      final color = isGreen ? Colors.green : Colors.red;
      
      final animatedFactor = math.min(1.0, animationValue * candles.length / (i + 1));
      
      final highY = chartHeight - ((candle.high - minPrice) / (maxPrice - minPrice) * chartHeight * animatedFactor);
      final lowY = chartHeight - ((candle.low - minPrice) / (maxPrice - minPrice) * chartHeight * animatedFactor);
      final openY = chartHeight - ((candle.open - minPrice) / (maxPrice - minPrice) * chartHeight * animatedFactor);
      final closeY = chartHeight - ((candle.close - minPrice) / (maxPrice - minPrice) * chartHeight * animatedFactor);

      // Wick
      final wickPaint = Paint()
        ..color = color.withOpacity(animatedFactor)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Body
      final bodyPaint = Paint()
        ..color = color.withOpacity(animatedFactor)
        ..style = isGreen ? PaintingStyle.fill : PaintingStyle.fill;

      final bodyTop = math.min(openY, closeY);
      final bodyBottom = math.max(openY, closeY);
      final bodyHeight = math.max(bodyBottom - bodyTop, 1.0);

      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(bodyRect, bodyPaint);

      // Selected highlight
      if (selectedIndex == i) {
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRRect(bodyRect.inflate(4), highlightPaint);
      }

      // Volume bars
      if (showVolume) {
        final volumeHeight2 = (candle.volume / maxVolume) * volumeHeight * animatedFactor;
        final volumePaint = Paint()
          ..color = color.withOpacity(0.5 * animatedFactor);
        
        canvas.drawRect(
          Rect.fromLTWH(
            x - bodyWidth / 2,
            volumeTop + (volumeHeight - volumeHeight2),
            bodyWidth,
            volumeHeight2,
          ),
          volumePaint,
        );
      }
    }

    // Draw price labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = TextStyle(
      color: isDark ? Colors.grey[500] : Colors.grey[600],
      fontSize: 10,
    );

    for (int i = 0; i <= 4; i++) {
      final price = maxPrice - (maxPrice - minPrice) * i / 4;
      textPainter.text = TextSpan(text: '₹${price.toStringAsFixed(0)}', style: labelStyle);
      textPainter.layout();
      final y = chartHeight * i / 4 - 5;
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, y));
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.showVolume != showVolume ||
        oldDelegate.showSMA != showSMA;
  }
}
