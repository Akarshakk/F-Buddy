/// Stock model for Markets Lab
class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    try {
      return Stock(
        symbol: json['symbol']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        change: double.tryParse(json['change']?.toString() ?? '0') ?? 0.0,
        changePercent: double.tryParse(json['changePercent']?.toString() ?? '0') ?? 0.0,
      );
    } catch (e) {
      print('Error parsing stock: ${json['symbol']} - $e');
      return Stock(
        symbol: json['symbol']?.toString() ?? 'ERR',
        name: 'Parse Error',
        price: 0,
        change: 0,
        changePercent: 0,
      );
    }
  }

  bool get isPositive => change >= 0;

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  String get formattedChange => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}';
  String get formattedChangePercent => '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}

/// Stock detail with historical data
class StockDetail {
  final String symbol;
  final String name;
  final double currentPrice;
  final double previousClose;
  final double change;
  final double changePercent;
  final double dayHigh;
  final double dayLow;
  final int volume;
  final String marketCap;
  final List<StockHistoryPoint> historicalData;

  StockDetail({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.dayHigh,
    required this.dayLow,
    required this.volume,
    required this.marketCap,
    required this.historicalData,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) {
    return StockDetail(
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      currentPrice: double.tryParse((json['currentPrice'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      previousClose: double.tryParse((json['previousClose'] ?? 0).toString()) ?? 0.0,
      change: double.tryParse((json['change'] ?? 0).toString()) ?? 0.0,
      changePercent: double.tryParse((json['changePercent'] ?? 0).toString()) ?? 0.0,
      dayHigh: double.tryParse((json['dayHigh'] ?? 0).toString()) ?? 0.0,
      dayLow: double.tryParse((json['dayLow'] ?? 0).toString()) ?? 0.0,
      volume: int.tryParse((json['volume'] ?? 0).toString()) ?? 0,
      marketCap: json['marketCap']?.toString() ?? '',
      historicalData: (json['historicalData'] as List? ?? [])
          .map((e) => StockHistoryPoint.fromJson(e))
          .toList(),
    );
  }

  bool get isPositive => change >= 0;

  String get formattedPrice => '₹${currentPrice.toStringAsFixed(2)}';
  String get formattedChange => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}';
  String get formattedChangePercent => '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}

/// Historical price point for charts
class StockHistoryPoint {
  final String date;
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  StockHistoryPoint({
    required this.date,
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory StockHistoryPoint.fromJson(Map<String, dynamic> json) {
    return StockHistoryPoint(
      date: json['date'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
    );
  }
}

/// Market index model
class MarketIndex {
  final String name;
  final double value;
  final double change;
  final double changePercent;

  MarketIndex({
    required this.name,
    required this.value,
    required this.change,
    required this.changePercent,
  });

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: double.tryParse(json['changePercent']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isPositive => change >= 0;

  String get formattedValue => value.toStringAsFixed(2);
  String get formattedChange => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}';
  String get formattedChangePercent => '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}

/// Market overview data
class MarketOverview {
  final List<MarketIndex> indices;
  final List<Stock> topGainers;
  final List<Stock> topLosers;
  final String marketStatus;
  final String lastUpdated;

  MarketOverview({
    required this.indices,
    required this.topGainers,
    required this.topLosers,
    required this.marketStatus,
    required this.lastUpdated,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    return MarketOverview(
      indices: (json['indices'] as List? ?? [])
          .map((e) => MarketIndex.fromJson(e))
          .toList(),
      topGainers: (json['topGainers'] as List? ?? [])
          .map((e) => Stock.fromJson(e))
          .toList(),
      topLosers: (json['topLosers'] as List? ?? [])
          .map((e) => Stock.fromJson(e))
          .toList(),
      marketStatus: json['marketStatus'] ?? 'CLOSED',
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}
