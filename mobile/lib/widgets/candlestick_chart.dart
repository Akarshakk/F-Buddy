import 'package:flutter/material.dart';
import '../models/stock.dart';

class CandlestickChart extends StatelessWidget {
  final List<StockHistoryPoint> data;
  final double height;
  final Color bullColor;
  final Color bearColor;
  final Color gridColor;
  final Color labelColor;

  const CandlestickChart({
    Key? key,
    required this.data,
    this.height = 300,
    this.bullColor = Colors.green,
    this.bearColor = Colors.red,
    this.gridColor = Colors.grey,
    this.labelColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final minPrice = data.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth.isFinite ? constraints.maxWidth - 50 : 300.0;
        final chartHeight = height;
        
        // Calculate candle width - dynamic but clamped
        final totalCandles = data.length;
        final availableWidth = chartWidth - 10;
        final candleWidth = (availableWidth / totalCandles * 0.7).clamp(2.0, 15.0);
        
        return Row(
          children: [
            // Y-axis labels
            SizedBox(
              width: 50,
              height: chartHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  final price = maxPrice - (priceRange * i / 4);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      price.toStringAsFixed(1),
                      style: TextStyle(color: labelColor, fontSize: 10),
                    ),
                  );
                }),
              ),
            ),
            // Chart
            Expanded(
              child: SizedBox(
                height: chartHeight,
                child: CustomPaint(
                  size: Size(chartWidth, chartHeight),
                  painter: CandlestickPainter(
                    data: data,
                    minPrice: minPrice - (priceRange * 0.05), // Add padding
                    maxPrice: maxPrice + (priceRange * 0.05),
                    candleWidth: candleWidth,
                    chartWidth: chartWidth,
                    bullColor: bullColor,
                    bearColor: bearColor,
                    gridColor: gridColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CandlestickPainter extends CustomPainter {
  final List<StockHistoryPoint> data;
  final double minPrice;
  final double maxPrice;
  final double candleWidth;
  final double chartWidth;
  final Color bullColor;
  final Color bearColor;
  final Color gridColor;

  CandlestickPainter({
    required this.data,
    required this.minPrice,
    required this.maxPrice,
    required this.candleWidth,
    required this.chartWidth,
    required this.bullColor,
    required this.bearColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.height <= 0 || size.width <= 0) return;
    
    final priceRange = (maxPrice - minPrice).clamp(0.01, double.infinity);
    final totalCandles = data.length;
    final totalCandleSpace = chartWidth / totalCandles;

    final paint = Paint()..style = PaintingStyle.fill;
    final wickPaint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = (i * totalCandleSpace) + (totalCandleSpace / 2);

      final isBullish = point.close >= point.open;
      final color = isBullish ? bullColor : bearColor;

      paint.color = color;
      wickPaint.color = color;

      // Normalize Y values
      // Canvas Y is 0 at top, height at bottom
      final highY = size.height - ((point.high - minPrice) / priceRange) * size.height;
      final lowY = size.height - ((point.low - minPrice) / priceRange) * size.height;
      final openY = size.height - ((point.open - minPrice) / priceRange) * size.height;
      final closeY = size.height - ((point.close - minPrice) / priceRange) * size.height;

      // Draw Wick
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Draw Body
      final bodyTop = isBullish ? closeY : openY;
      final bodyBottom = isBullish ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      final bodyRect = Rect.fromCenter(
        center: Offset(x, bodyTop + bodyHeight / 2),
        width: candleWidth,
        height: bodyHeight,
      );
      
      canvas.drawRect(bodyRect, paint);
    }
    
    // Grid Lines
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.2)
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
        chartWidth != oldDelegate.chartWidth;
  }
}
