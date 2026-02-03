import '../services/api_service.dart';
import '../models/stock.dart';
import '../models/paper_portfolio.dart';

/// Service for Markets Lab - Paper Trading
class MarketsService {
  static const String _basePath = '/markets';

  /// Get market overview with indices and top gainers/losers
  static Future<MarketOverview?> getMarketOverview() async {
    try {
      final response = await ApiService.get('$_basePath/overview');
      if (response['success'] == true && response['data'] != null) {
        return MarketOverview.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching market overview: $e');
      return null;
    }
  }

  /// Get list of all available stocks
  static Future<List<Stock>> getStocks() async {
    try {
      final response = await ApiService.get('$_basePath/stocks');
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((e) => Stock.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('[MarketsService] Error fetching stocks: $e');
      return [];
    }
  }

  /// Get stock detail with historical data
  static Future<StockDetail?> getStockDetail(String symbol, {String timeframe = '1M'}) async {
    try {
      final response = await ApiService.get(
        '$_basePath/stocks/$symbol',
        queryParams: {'timeframe': timeframe},
      );
      if (response['success'] == true && response['data'] != null) {
        return StockDetail.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching stock detail: $e');
      return null;
    }
  }

  /// Search stocks by name or symbol
  static Future<List<Stock>> searchStocks(String query) async {
    try {
      final response = await ApiService.get(
        '$_basePath/search',
        queryParams: {'q': query},
      );
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((e) => Stock.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('[MarketsService] Error searching stocks: $e');
      return [];
    }
  }

  /// Get user's paper trading portfolio
  static Future<PaperPortfolio?> getPortfolio() async {
    try {
      final response = await ApiService.get('$_basePath/portfolio');
      if (response['success'] == true && response['data'] != null) {
        return PaperPortfolio.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching portfolio: $e');
      return null;
    }
  }

  /// Execute a paper trade (BUY or SELL)
  static Future<Map<String, dynamic>> executeTrade({
    required String symbol,
    required String type, // 'BUY' or 'SELL'
    required int quantity,
  }) async {
    try {
      final response = await ApiService.post(
        '$_basePath/trade',
        body: {
          'symbol': symbol,
          'type': type,
          'quantity': quantity,
        },
      );
      return response;
    } catch (e) {
      print('[MarketsService] Error executing trade: $e');
      return {'success': false, 'message': 'Failed to execute trade: $e'};
    }
  }

  /// Get trade history
  static Future<List<PaperTrade>> getTradeHistory({int limit = 50, String? symbol}) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};
      if (symbol != null) {
        queryParams['symbol'] = symbol;
      }
      
      final response = await ApiService.get(
        '$_basePath/trades',
        queryParams: queryParams,
      );
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List)
            .map((e) => PaperTrade.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('[MarketsService] Error fetching trade history: $e');
      return [];
    }
  }

  /// Reset portfolio to initial state
  static Future<Map<String, dynamic>> resetPortfolio() async {
    try {
      final response = await ApiService.post('$_basePath/portfolio/reset');
      return response;
    } catch (e) {
      print('[MarketsService] Error resetting portfolio: $e');
      return {'success': false, 'message': 'Failed to reset portfolio: $e'};
    }
  }

  // ============================================================
  // WATCHLIST METHODS
  // ============================================================

  /// Get user's watchlist with current stock details
  static Future<Watchlist?> getWatchlist() async {
    try {
      final response = await ApiService.get('$_basePath/watchlist');
      if (response['success'] == true && response['data'] != null) {
        return Watchlist.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching watchlist: $e');
      return null;
    }
  }

  /// Add stock to watchlist
  static Future<Map<String, dynamic>> addToWatchlist({
    required String symbol,
    required String stockName,
  }) async {
    try {
      print('[MarketsService] Adding to watchlist: $symbol - $stockName');
      final response = await ApiService.post(
        '$_basePath/watchlist/add',
        body: {
          'symbol': symbol,
          'stockName': stockName,
        },
      );
      print('[MarketsService] Watchlist add response: $response');
      return response;
    } catch (e) {
      print('[MarketsService] Error adding to watchlist: $e');
      return {'success': false, 'message': 'Failed to add to watchlist: $e'};
    }
  }

  /// Remove stock from watchlist
  static Future<Map<String, dynamic>> removeFromWatchlist(String symbol) async {
    try {
      final response = await ApiService.delete('$_basePath/watchlist/$symbol');
      return response;
    } catch (e) {
      print('[MarketsService] Error removing from watchlist: $e');
      return {'success': false, 'message': 'Failed to remove from watchlist: $e'};
    }
  }

  /// Check if stock is in watchlist
  static Future<bool> isInWatchlist(String symbol) async {
    try {
      final response = await ApiService.get('$_basePath/watchlist/check/$symbol');
      if (response['success'] == true && response['data'] != null) {
        return response['data']['isWatched'] == true;
      }
      return false;
    } catch (e) {
      print('[MarketsService] Error checking watchlist: $e');
      return false;
    }
  }
}
