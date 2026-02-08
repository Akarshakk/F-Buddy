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
      print('[MarketsService] Fetching stocks from $_basePath/stocks');
      final response = await ApiService.get('$_basePath/stocks');
      print('[MarketsService] Response success: ${response['success']}');
      print('[MarketsService] Response data count: ${response['data']?.length}');
      
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

  // ============================================================
  // LEADERBOARD METHODS
  // ============================================================

  /// Get global leaderboard
  static Future<LeaderboardData?> getLeaderboard({int limit = 50, String sortBy = 'totalReturn'}) async {
    try {
      final response = await ApiService.get(
        '$_basePath/leaderboard',
        queryParams: {'limit': limit.toString(), 'sortBy': sortBy},
      );
      if (response['success'] == true && response['data'] != null) {
        return LeaderboardData.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching leaderboard: $e');
      return null;
    }
  }

  /// Get user's rank on leaderboard
  static Future<Map<String, dynamic>?> getMyRank() async {
    try {
      final response = await ApiService.get('$_basePath/leaderboard/me');
      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching my rank: $e');
      return null;
    }
  }

  // ============================================================
  // STOCK COMPARATOR METHODS
  // ============================================================

  /// Compare multiple stocks
  static Future<StockComparison?> compareStocks(List<String> symbols) async {
    try {
      final response = await ApiService.post(
        '$_basePath/compare',
        body: {'symbols': symbols},
      );
      if (response['success'] == true && response['data'] != null) {
        return StockComparison.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error comparing stocks: $e');
      return null;
    }
  }

  // ============================================================
  // CANDLESTICK / OHLC METHODS
  // ============================================================

  /// Get OHLC candlestick data
  static Future<CandlestickData?> getCandlestickData(String symbol, {String timeframe = '1M'}) async {
    try {
      final response = await ApiService.get(
        '$_basePath/stocks/$symbol/candles',
        queryParams: {'timeframe': timeframe},
      );
      if (response['success'] == true && response['data'] != null) {
        return CandlestickData.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('[MarketsService] Error fetching candlestick data: $e');
      return null;
    }
  }
}

// ============================================================
// ADDITIONAL MODELS
// ============================================================

/// Leaderboard data model
class LeaderboardData {
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardStats stats;
  final String lastUpdated;

  LeaderboardData({
    required this.leaderboard,
    required this.stats,
    required this.lastUpdated,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      leaderboard: (json['leaderboard'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      stats: LeaderboardStats.fromJson(json['stats'] ?? {}),
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String odUserId;
  final String username;
  final String? avatar;
  final double portfolioValue;
  final double totalReturn;
  final double totalPnL;
  final int totalTrades;
  final double winRate;
  final Map<String, dynamic>? bestTrade;
  final int streak;

  LeaderboardEntry({
    required this.rank,
    required this.odUserId,
    required this.username,
    this.avatar,
    required this.portfolioValue,
    required this.totalReturn,
    required this.totalPnL,
    required this.totalTrades,
    required this.winRate,
    this.bestTrade,
    required this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      odUserId: json['userId'] ?? '',
      username: json['username'] ?? 'Trader',
      avatar: json['avatar'],
      portfolioValue: (json['portfolioValue'] ?? 0).toDouble(),
      totalReturn: (json['totalReturn'] ?? 0).toDouble(),
      totalPnL: (json['totalPnL'] ?? 0).toDouble(),
      totalTrades: json['totalTrades'] ?? 0,
      winRate: (json['winRate'] ?? 0).toDouble(),
      bestTrade: json['bestTrade'],
      streak: json['streak'] ?? 0,
    );
  }
}

class LeaderboardStats {
  final int totalTraders;
  final double averageReturn;
  final double topReturn;
  final double totalVolume;

  LeaderboardStats({
    required this.totalTraders,
    required this.averageReturn,
    required this.topReturn,
    required this.totalVolume,
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    return LeaderboardStats(
      totalTraders: json['totalTraders'] ?? 0,
      averageReturn: (json['averageReturn'] ?? 0).toDouble(),
      topReturn: (json['topReturn'] ?? 0).toDouble(),
      totalVolume: (json['totalVolume'] ?? 0).toDouble(),
    );
  }
}

/// Stock comparison model
class StockComparison {
  final List<ComparedStock> stocks;
  final Map<String, dynamic> comparison;
  final String comparedAt;

  StockComparison({
    required this.stocks,
    required this.comparison,
    required this.comparedAt,
  });

  factory StockComparison.fromJson(Map<String, dynamic> json) {
    return StockComparison(
      stocks: (json['stocks'] as List? ?? [])
          .map((e) => ComparedStock.fromJson(e))
          .toList(),
      comparison: json['comparison'] ?? {},
      comparedAt: json['comparedAt'] ?? '',
    );
  }
}

class ComparedStock {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double dayHigh;
  final double dayLow;
  final double yearHigh;
  final double yearLow;
  final String marketCap;
  final double pe;
  final double pb;
  final double eps;
  final double dividend;
  final String sector;
  final String industry;
  final int volume;
  final int avgVolume;

  ComparedStock({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.dayHigh,
    required this.dayLow,
    required this.yearHigh,
    required this.yearLow,
    required this.marketCap,
    required this.pe,
    required this.pb,
    required this.eps,
    required this.dividend,
    required this.sector,
    required this.industry,
    required this.volume,
    required this.avgVolume,
  });

  factory ComparedStock.fromJson(Map<String, dynamic> json) {
    return ComparedStock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      dayHigh: (json['dayHigh'] ?? 0).toDouble(),
      dayLow: (json['dayLow'] ?? 0).toDouble(),
      yearHigh: (json['yearHigh'] ?? 0).toDouble(),
      yearLow: (json['yearLow'] ?? 0).toDouble(),
      marketCap: json['marketCap']?.toString() ?? 'N/A',
      pe: (json['pe'] ?? 0).toDouble(),
      pb: (json['pb'] ?? 0).toDouble(),
      eps: (json['eps'] ?? 0).toDouble(),
      dividend: (json['dividend'] ?? 0).toDouble(),
      sector: json['sector'] ?? 'N/A',
      industry: json['industry'] ?? 'N/A',
      volume: json['volume'] ?? 0,
      avgVolume: json['avgVolume'] ?? 0,
    );
  }
}

/// Candlestick data model
class CandlestickData {
  final String symbol;
  final String timeframe;
  final List<CandleData> candles;
  final List<CandlePattern> patterns;
  final TechnicalIndicators indicators;
  final int dataPoints;

  CandlestickData({
    required this.symbol,
    required this.timeframe,
    required this.candles,
    required this.patterns,
    required this.indicators,
    required this.dataPoints,
  });

  factory CandlestickData.fromJson(Map<String, dynamic> json) {
    return CandlestickData(
      symbol: json['symbol'] ?? '',
      timeframe: json['timeframe'] ?? '1M',
      candles: (json['candles'] as List? ?? [])
          .map((e) => CandleData.fromJson(e))
          .toList(),
      patterns: (json['patterns'] as List? ?? [])
          .map((e) => CandlePattern.fromJson(e))
          .toList(),
      indicators: TechnicalIndicators.fromJson(json['indicators'] ?? {}),
      dataPoints: json['dataPoints'] ?? 0,
    );
  }
}

class CandleData {
  final String date;
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  CandleData({
    required this.date,
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      date: json['date'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
    );
  }

  bool get isBullish => close > open;
  bool get isBearish => close < open;
}

class CandlePattern {
  final String name;
  final String type; // bullish, bearish, neutral
  final String date;
  final int index;
  final String significance;
  final String icon;

  CandlePattern({
    required this.name,
    required this.type,
    required this.date,
    required this.index,
    required this.significance,
    required this.icon,
  });

  factory CandlePattern.fromJson(Map<String, dynamic> json) {
    return CandlePattern(
      name: json['name'] ?? '',
      type: json['type'] ?? 'neutral',
      date: json['date'] ?? '',
      index: json['index'] ?? 0,
      significance: json['significance'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class TechnicalIndicators {
  final double? sma20;
  final double? sma50;
  final double? rsi;
  final double? macd;
  final String? trend;
  final String? rsiSignal;

  TechnicalIndicators({
    this.sma20,
    this.sma50,
    this.rsi,
    this.macd,
    this.trend,
    this.rsiSignal,
  });

  factory TechnicalIndicators.fromJson(Map<String, dynamic> json) {
    return TechnicalIndicators(
      sma20: json['sma20']?.toDouble(),
      sma50: json['sma50']?.toDouble(),
      rsi: json['rsi']?.toDouble(),
      macd: json['macd']?.toDouble(),
      trend: json['trend'],
      rsiSignal: json['rsiSignal'],
    );
  }
}
