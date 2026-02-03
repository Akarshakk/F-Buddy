/// Paper trading portfolio model
class PaperPortfolio {
  final String id;
  final double virtualBalance;
  final List<Holding> holdings;
  final double totalInvested;
  final double currentPortfolioValue;
  final double totalPnl;
  final double totalPnlPercent;
  final double netWorth;
  final String createdAt;
  final String updatedAt;

  PaperPortfolio({
    required this.id,
    required this.virtualBalance,
    required this.holdings,
    required this.totalInvested,
    required this.currentPortfolioValue,
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.netWorth,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaperPortfolio.fromJson(Map<String, dynamic> json) {
    return PaperPortfolio(
      id: json['id'] ?? '',
      virtualBalance: (json['virtualBalance'] ?? 0).toDouble(),
      holdings: (json['holdings'] as List? ?? [])
          .map((e) => Holding.fromJson(e))
          .toList(),
      totalInvested: (json['totalInvested'] ?? 0).toDouble(),
      currentPortfolioValue: (json['currentPortfolioValue'] ?? 0).toDouble(),
      totalPnl: (json['totalPnl'] ?? 0).toDouble(),
      totalPnlPercent: (json['totalPnlPercent'] ?? 0).toDouble(),
      netWorth: (json['netWorth'] ?? 0).toDouble(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String get formattedBalance => '₹${_formatNumber(virtualBalance)}';
  String get formattedInvested => '₹${_formatNumber(totalInvested)}';
  String get formattedPortfolioValue => '₹${_formatNumber(currentPortfolioValue)}';
  String get formattedNetWorth => '₹${_formatNumber(netWorth)}';
  String get formattedPnl => '${totalPnl >= 0 ? '+' : ''}₹${_formatNumber(totalPnl.abs())}';
  String get formattedPnlPercent => '${totalPnl >= 0 ? '+' : ''}${totalPnlPercent.toStringAsFixed(2)}%';

  bool get isProfitable => totalPnl >= 0;

  static String _formatNumber(double num) {
    if (num >= 10000000) {
      return '${(num / 10000000).toStringAsFixed(2)} Cr';
    } else if (num >= 100000) {
      return '${(num / 100000).toStringAsFixed(2)} L';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(2)} K';
    }
    return num.toStringAsFixed(2);
  }
}

/// Individual stock holding
class Holding {
  final String symbol;
  final String stockName;
  final int quantity;
  final double avgPrice;
  final double currentPrice;
  final double currentValue;
  final double investedValue;
  final double pnl;
  final double pnlPercent;

  Holding({
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.currentValue,
    required this.investedValue,
    required this.pnl,
    required this.pnlPercent,
  });

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] ?? '',
      stockName: json['stockName'] ?? '',
      quantity: json['quantity'] ?? 0,
      avgPrice: (json['avgPrice'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      currentValue: (json['currentValue'] ?? 0).toDouble(),
      investedValue: (json['investedValue'] ?? 0).toDouble(),
      pnl: (json['pnl'] ?? 0).toDouble(),
      pnlPercent: (json['pnlPercent'] ?? 0).toDouble(),
    );
  }

  bool get isProfitable => pnl >= 0;

  String get formattedAvgPrice => '₹${avgPrice.toStringAsFixed(2)}';
  String get formattedCurrentPrice => '₹${currentPrice.toStringAsFixed(2)}';
  String get formattedCurrentValue => '₹${currentValue.toStringAsFixed(2)}';
  String get formattedPnl => '${pnl >= 0 ? '+' : ''}₹${pnl.abs().toStringAsFixed(2)}';
  String get formattedPnlPercent => '${pnl >= 0 ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%';
}

/// Paper trade record
class PaperTrade {
  final String id;
  final String symbol;
  final String stockName;
  final String type; // BUY or SELL
  final int quantity;
  final double price;
  final double totalValue;
  final String createdAt;

  PaperTrade({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalValue,
    required this.createdAt,
  });

  factory PaperTrade.fromJson(Map<String, dynamic> json) {
    return PaperTrade(
      id: json['id'] ?? json['_id'] ?? '',
      symbol: json['symbol'] ?? '',
      stockName: json['stockName'] ?? '',
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool get isBuy => type.toUpperCase() == 'BUY';

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  String get formattedTotalValue => '₹${totalValue.toStringAsFixed(2)}';

  DateTime? get dateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }
}

/// Watchlist item with stock details
class WatchlistItem {
  final String symbol;
  final String stockName;
  final String addedAt;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double dayHigh;
  final double dayLow;

  WatchlistItem({
    required this.symbol,
    required this.stockName,
    required this.addedAt,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.dayHigh,
    required this.dayLow,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      symbol: json['symbol'] ?? '',
      stockName: json['stockName'] ?? '',
      addedAt: json['addedAt'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      dayHigh: (json['dayHigh'] ?? 0).toDouble(),
      dayLow: (json['dayLow'] ?? 0).toDouble(),
    );
  }

  bool get isPositive => change >= 0;

  String get formattedPrice => '₹${currentPrice.toStringAsFixed(2)}';
  String get formattedChange => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
  String get formattedDayHigh => '₹${dayHigh.toStringAsFixed(2)}';
  String get formattedDayLow => '₹${dayLow.toStringAsFixed(2)}';
}

/// User's watchlist
class Watchlist {
  final String id;
  final List<WatchlistItem> stocks;
  final int count;
  final String updatedAt;

  Watchlist({
    required this.id,
    required this.stocks,
    required this.count,
    required this.updatedAt,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] ?? '',
      stocks: (json['stocks'] as List<dynamic>?)
          ?.map((e) => WatchlistItem.fromJson(e))
          .toList() ?? [],
      count: json['count'] ?? 0,
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}