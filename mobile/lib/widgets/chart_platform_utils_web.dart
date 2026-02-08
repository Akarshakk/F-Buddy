import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

class ChartPlatformUtils {
  static void registerView(String viewId, String symbol, String interval, String theme, String type, String baseUrl, {String symbols = ''}) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final encodedSymbol = Uri.encodeComponent(symbol);
      final encodedInterval = Uri.encodeComponent(interval);
      final encodedBaseUrl = Uri.encodeComponent(baseUrl);
      final encodedSymbols = Uri.encodeComponent(symbols);
      
      final url = 'assets/chart.html?symbol=$encodedSymbol&interval=$encodedInterval&theme=$theme&type=$type&baseUrl=$encodedBaseUrl&symbols=$encodedSymbols';
      
      return html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }
}
