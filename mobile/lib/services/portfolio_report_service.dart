
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/paper_portfolio.dart';

class PortfolioReportService {
  static Future<void> generateAndPrintReport(PaperPortfolio portfolio) async {
    final pdf = pw.Document();
    
    // Use NotoSans for better currency symbol support (Rupee)
    final fontBase = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();
    
    final theme = pw.ThemeData.withFont(
      base: fontBase,
      bold: fontBold,
    );

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM d, yyyy h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(portfolio, dateFormat),
            pw.SizedBox(height: 24),
            _buildSummarySection(portfolio, currencyFormat),
            pw.SizedBox(height: 24),
            
            // Asset Allocation Section
            pw.Text('Asset Allocation', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            _buildAllocationPieChart(portfolio, currencyFormat),
            
            pw.SizedBox(height: 24),
            
            // Holdings Table
            pw.Text('Detailed Holdings', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            _buildHoldingsTable(portfolio, currencyFormat),
            
            pw.SizedBox(height: 24),
            
            // P&L Chart
            pw.Text('Profit/Loss Analysis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            _buildPnlBarChart(portfolio, currencyFormat),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Finzo_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
    );
  }

  static pw.Widget _buildHeader(PaperPortfolio portfolio, DateFormat dateFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Finzo', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
            pw.Text('Portfolio Performance Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Generated', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Text(dateFormat.format(DateTime.now()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(PaperPortfolio portfolio, NumberFormat currencyFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Net Worth', currencyFormat.format(portfolio.netWorth), true, PdfColors.blue800),
          _buildSummaryItem('Invested', currencyFormat.format(portfolio.totalInvested), false, PdfColors.black),
          _buildSummaryItem('Current Value', currencyFormat.format(portfolio.currentPortfolioValue), false, PdfColors.black),
          _buildSummaryItem(
            'Total P&L',
            '${portfolio.formattedPnl} (${portfolio.formattedPnlPercent})',
            false,
            portfolio.totalPnl >= 0 ? PdfColors.green700 : PdfColors.red700,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, bool isMain, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isMain ? 20 : 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAllocationPieChart(PaperPortfolio portfolio, NumberFormat currencyFormat) {
    if (portfolio.holdings.isEmpty) {
      return pw.Text('No holdings to display.');
    }

    final sortedHoldings = List.from(portfolio.holdings)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
    
    // Top 5 holdings + Others
    final topHoldings = sortedHoldings.take(5).toList();
    final otherValue = sortedHoldings.skip(5).fold(0.0, (sum, h) => sum + h.currentValue);
    
    final colors = [
      PdfColors.blue700,
      PdfColors.red700,
      PdfColors.amber700,
      PdfColors.green700,
      PdfColors.purple700,
      PdfColors.grey600,
    ];

    return pw.Row(
      children: [
        // Pie Chart
        pw.Expanded(
          flex: 2,
          child: pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Container(
              height: 150,
              width: 150,
              child: pw.Chart(
                grid: pw.PieGrid(),
                datasets: List.generate(topHoldings.length + (otherValue > 0 ? 1 : 0), (index) {
                  if (index < topHoldings.length) {
                    final h = topHoldings[index];
                    return pw.PieDataSet(
                      legend: h.symbol,
                      value: h.currentValue.abs(),
                      color: colors[index % colors.length],
                      legendStyle: const pw.TextStyle(fontSize: 10),
                    );
                  } else {
                    return pw.PieDataSet(
                      legend: 'Others',
                      value: otherValue,
                      color: colors[5],
                      legendStyle: const pw.TextStyle(fontSize: 10),
                    );
                  }
                }),
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 32),
        // Legend
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: List.generate(topHoldings.length + (otherValue > 0 ? 1 : 0), (index) {
              String label;
              double value;
              PdfColor color;
              
              if (index < topHoldings.length) {
                final h = topHoldings[index];
                label = h.symbol;
                value = h.currentValue;
                color = colors[index % colors.length];
              } else {
                label = 'Others';
                value = otherValue;
                color = colors[5];
              }
              
              final percent = (value / portfolio.currentPortfolioValue * 100).toStringAsFixed(1);
              
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    pw.Container(width: 12, height: 12, color: color),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 11))),
                    pw.Text(currencyFormat.format(value), style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(width: 8),
                    pw.Text('$percent%', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }


  static pw.Widget _buildHoldingsTable(PaperPortfolio portfolio, NumberFormat currencyFormat) {
    return pw.TableHelper.fromTextArray(
      headers: ['Symbol', 'Qty', 'Avg Price', 'Current', 'Value', 'P&L'],
      data: portfolio.holdings.map((h) => [
        h.symbol,
        h.quantity.toString(),
        currencyFormat.format(h.avgPrice),
        currencyFormat.format(h.currentPrice),
        currencyFormat.format(h.currentValue),
        '${h.pnl >= 0 ? '+' : ''}${currencyFormat.format(h.pnl)}\n(${h.pnlPercent.toStringAsFixed(2)}%)',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
      cellAlignment: pw.Alignment.centerRight,
      cellAlignments: {0: pw.Alignment.centerLeft},
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
    );
  }

  static pw.Widget _buildPnlBarChart(PaperPortfolio portfolio, NumberFormat currencyFormat) {
    if (portfolio.holdings.isEmpty) return pw.Container();
    
    final sortedHoldings = List.from(portfolio.holdings)..sort((a, b) => b.pnl.compareTo(a.pnl));
    final maxPnl = sortedHoldings.map((h) => h.pnl.abs()).reduce((a, b) => a > b ? a : b);
    if (maxPnl == 0) return pw.Text('No P&L data');

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Loss', style: const pw.TextStyle(color: PdfColors.red700, fontSize: 10)),
            pw.Text('Profit', style: const pw.TextStyle(color: PdfColors.green700, fontSize: 10)),
          ],
        ),
        pw.Divider(color: PdfColors.grey300),
        ...sortedHoldings.map((h) {
          final barWidth = ((h.pnl.abs() / maxPnl) * 150).toDouble(); // Scale to 150 width
          final isProfitable = h.pnl >= 0;

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      if (!isProfitable) ...[
                        pw.Text(
                          currencyFormat.format(h.pnl), 
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700)
                        ),
                        pw.SizedBox(width: 4),
                        pw.Container(
                          height: 12,
                          width: barWidth,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.red600,
                            borderRadius: pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(2),
                              bottomLeft: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Container(width: 1, color: PdfColors.grey400, height: 16),
                pw.Expanded(
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      if (isProfitable) ...[
                        pw.Container(
                          height: 12,
                          width: barWidth,
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.green600,
                            borderRadius: pw.BorderRadius.only(
                              topRight: pw.Radius.circular(2),
                              bottomRight: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          currencyFormat.format(h.pnl), 
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.green700)
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: sortedHoldings.map((h) => 
            pw.Container(
              width: 300 / sortedHoldings.length, // Distribute labels somewhat
              alignment: pw.Alignment.center,
              child: pw.Text(
                h.symbol.substring(0, h.symbol.length.clamp(0, 3)),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            )
          ).toList(),
        ),
      ],
    );
  }
}
