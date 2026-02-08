import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/stock.dart';
import '../../services/markets_service.dart';
import '../../widgets/candlestick_chart.dart';
import '../../widgets/trading_view_chart.dart';

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

class _CandlestickChartScreenState extends State<CandlestickChartScreen> {
  bool _isLoading = true;
  StockDetail? _stockDetail;
  String _selectedTimeframe = '3M';
  final List<String> _timeframes = ['1W', '1M', '3M', '6M', '1Y'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final detail = await MarketsService.getStockDetail(widget.symbol, timeframe: _selectedTimeframe);
    if (mounted) {
      setState(() {
        _stockDetail = detail;
        _isLoading = false;
      });
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
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol, style: AppTextStyles.heading3.copyWith(color: textPrimary)),
            Text(widget.stockName, style: AppTextStyles.caption.copyWith(color: textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stockDetail == null
              ? Center(child: Text('Failed to load chart data', style: TextStyle(color: textSecondary)))
              : Column(
                  children: [
                    // Stats / Price Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stockDetail!.formattedPrice,
                                style: AppTextStyles.heading1.copyWith(color: textPrimary),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    _stockDetail!.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: _stockDetail!.isPositive ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  Text(
                                    ' ${_stockDetail!.formattedChange} (${_stockDetail!.formattedChangePercent})',
                                    style: TextStyle(
                                      color: _stockDetail!.isPositive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _buildTimeframeSelector(surfaceColor, primaryColor, textSecondary),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: TradingViewChart(
                          symbol: widget.symbol,
                          interval: _selectedTimeframe,
                          theme: isDark ? 'dark' : 'light',
                          height: double.infinity,
                        ),
                      ),
                    ),
                    // Volume or other stats could go here
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _buildTimeframeSelector(Color surfaceColor, Color primaryColor, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _timeframes.map((tf) {
          final isSelected = tf == _selectedTimeframe;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() => _selectedTimeframe = tf);
                _loadData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  color: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? AppColorsDark.background : Colors.white)
                      : textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
