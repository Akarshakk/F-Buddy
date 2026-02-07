const PaperTrade = require('../models/PaperTrade');
const PaperPortfolio = require('../models/PaperPortfolio');
const Watchlist = require('../models/Watchlist');
const yahooFinance = require('../config/yahooFinance');
// const YahooFinance = require('yahoo-finance2').default; // Removed
// const yahooFinance = new YahooFinance(); // Removed

// Popular Indian Stocks for "Get Stocks" list and Mock Gainers/Losers
// Popular Indian Stocks (Nifty 50 + Next 50 + US Tech)
const POPULAR_IND_STOCKS = [
  // NIFTY 50
  'RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'ICICIBANK.NS', 'INFY.NS', 'SBIN.NS', 'BHARTIARTL.NS', 'ITC.NS', 'KOTAKBANK.NS', 'LICI.NS',
  'HINDUNILVR.NS', 'LT.NS', 'BAJFINANCE.NS', 'HCLTECH.NS', 'MARUTI.NS', 'SUNPHARMA.NS', 'ASIANPAINT.NS', 'TITAN.NS', 'AXISBANK.NS', 'ULTRACEMCO.NS',
  'TATASTEEL.NS', 'NTPC.NS', 'M&M.NS', 'POWERGRID.NS', 'TATAMOTORS.NS', 'ADANIENT.NS', 'BAJAJFINSV.NS', 'WIPRO.NS', 'COALINDIA.NS', 'ONGC.NS',
  'NESTLEIND.NS', 'JSWSTEEL.NS', 'TATACONSUM.NS', 'GRASIM.NS', 'ADANIPORTS.NS', 'EICHERMOT.NS', 'BPCL.NS', 'HINDALCO.NS', 'DRREDDY.NS', 'CIPLA.NS',
  'DIVISLAB.NS', 'SBILIFE.NS', 'BRITANNIA.NS', 'APOLLOHOSP.NS', 'TECHM.NS', 'HEROMOTOCO.NS', 'UPL.NS', 'BAJAJ-AUTO.NS', 'TATACONSUM.NS', 'SHREECEM.NS',

  // NIFTY NEXT 50 & ACTIVE LARGE/MIDCAPS
  'ZOMATO.NS', 'PAYTM.NS', 'HAL.NS', 'BEL.NS', 'TRENT.NS', 'JIOFIN.NS', 'VBL.NS', 'CHOLAFIN.NS', 'SIEMENS.NS', 'DLF.NS',
  'PIDILITIND.NS', 'IOC.NS', 'BANKBARODA.NS', 'GAIL.NS', 'RECLTD.NS', 'SHRIRAMFIN.NS', 'ADANIPOWER.NS', 'ADANIGREEN.NS', 'AMBUJACEM.NS', 'TVSMOTOR.NS',
  'HAVELLS.NS', 'DABUR.NS', 'ABB.NS', 'VEDL.NS', 'GODREJCP.NS', 'INDUSINDBK.NS', 'NAUKRI.NS', 'ICICIGI.NS', 'SBICARD.NS', 'TATAPOWER.NS',
  'IRCTC.NS', 'BOSCHLTD.NS', 'BERGEPAINT.NS', 'MUTHOOTFIN.NS', 'PIIND.NS', 'MOTHERSON.NS', 'LTIM.NS', 'ICICIPRULI.NS', 'MARICO.NS', 'CANBK.NS',
  'POLYCAB.NS', 'SRF.NS', 'TORNTPHARM.NS', 'INDIGO.NS', 'PNB.NS', 'JINDALSTEL.NS', 'LUPIN.NS', 'AUROPHARMA.NS', 'TIINDIA.NS', 'ALKEM.NS',
  'MAXHEALTH.NS', 'TATAELXSI.NS', 'COLPAL.NS', 'PERSISTENT.NS', 'MANKIND.NS', 'KPITTECH.NS', 'YESBANK.NS', 'IDFCFIRSTB.NS', 'PAGEIND.NS', 'OBEROIRLTY.NS',
  'AU SMALL FINANCE BANK.NS', 'PATANJALI.NS', 'HINDZINC.NS', 'POLICYBZR.NS', 'BHEL.NS', 'MAHABANK.NS', 'UNIONBANK.NS', 'OIL.NS', 'CONCOR.NS', 'RVNL.NS',
  'IRFC.NS', 'MAZDOCK.NS', 'COCHINSHIP.NS', 'MAPMYINDIA.NS', 'METROBRAND.NS', 'SOLARINDS.NS', 'KEI.NS', 'DIXON.NS', 'SYNGENE.NS', 'GMRINFRA.NS',
  'IDEA.NS', 'NYKAA.NS', 'HONAUT.NS', 'ASTRAL.NS', 'ASHOKLEY.NS', 'CUMMINSIND.NS', 'LUPIN.NS', 'PETRONET.NS', 'PEL.NS', 'TATACOMM.NS', 'JSL.NS',
  'GLAND.NS', 'HINDPETRO.NS', 'MFSL.NS', 'IPCALAB.NS', 'AUBANK.NS', 'VOLTAS.NS', 'CROMPTON.NS', 'LAURUSLABS.NS', 'BANDHANBNK.NS', 'BALKRISIND.NS',
  'FEDERALBNK.NS', 'IDBI.NS', 'PRESTIGE.NS', 'APLLTD.NS', 'AJANTPHARM.NS', 'TATAINVEST.NS', 'NHPC.NS', 'SJVN.NS', 'MAHLOG.NS', 'CDSL.NS',
  'BSE.NS', 'MCX.NS', 'IEX.NS', 'KAYNES.NS', 'EMUDHRA.NS', 'DATAPATTNS.NS', 'MAHINDCIE.NS', 'SWSOLAR.NS', 'SUZLON.NS', 'TRIDENT.NS',
  'POONAWALLA.NS', 'HUDCO.NS', 'NBCC.NS', 'HUDCO.NS', 'HFCL.NS', 'GATEWAY.NS', 'DELHIVERY.NS', 'CARBORUNIV.NS', 'TIMKEN.NS', 'GRINDWELL.NS',
  'DEEPAKNTR.NS', 'ESCORTS.NS', 'TATACHEM.NS', 'GUJGASLTD.NS', 'LINDEINDIA.NS', 'ALKYLAMINE.NS', 'VINATIORGA.NS', 'NAVINFLUOR.NS', 'PIIND.NS',
  'RAMCOCEM.NS', 'JKCEMENT.NS', 'DALBHARAT.NS', 'STARHEALTH.NS', 'GOCOLOR.NS', 'SAPPHIRE.NS', 'DEVYANI.NS', 'RADICO.NS', 'UNOMINDA.NS', 'ENDURANCE.NS',
  'SCHAEFFLER.NS', 'SKFINDIA.NS', 'BHARATFORG.NS', 'SONACOMS.NS', 'CRAFTSMAN.NS', 'JWL.NS', 'TITAGARH.NS', 'RKFORGE.NS', 'MINDACORP.NS', 'SUPRAJIT.NS',
  'MAHSCOOTER.NS', 'PFC.NS', 'RECLTD.NS', 'L&TFH.NS', 'M&MFIN.NS', 'CHOLAHLDNG.NS', 'CREDITACC.NS', 'HOMEFIRST.NS', 'AAVAS.NS', 'CANFINHOME.NS',
  'ABCAPITAL.NS', 'L&TIDPL.NS', 'GRNR.NS', 'ACE.NS', 'TIPSINDLTD.NS', 'SAREGAMA.NS', 'NAZARA.NS', 'PRINCEPIPE.NS', 'FINPIPE.NS', 'SUPREMEIND.NS',
  'ASTRAL.NS', 'KAJARIACER.NS', 'CERA.NS', 'SOMANYCEMS.NS', 'CENTURYPLY.NS', 'GREENPANEL.NS', 'KAJARIACER.NS', 'BORORENEW.NS', 'AWL.NS', 'ADANIPOWER.NS',
  'CGPOWER.NS', 'HBLPOWER.NS', 'GENUSPOWER.NS', 'JINDALSTEL.NS', 'TATASTEEL.NS', 'JSWSTEEL.NS', 'HINDALCO.NS', 'NATIONALUM.NS', 'HINDZINC.NS', 'VEDL.NS',
  'NMDC.NS', 'KIOCL.NS', 'MOIL.NS', 'GPIL.NS', 'APLAPOLLO.NS', 'RATNAMANI.NS', 'WELCORP.NS', 'MASTEK.NS', 'SONATAW.NS', 'CYIENT.NS', 'ZENSARTECH.NS',
  'BSOFT.NS', 'NEWGEN.NS', 'INTELLECT.NS', 'CEINFO.NS', 'TATAELXSI.NS', 'L&T'.replace('L&T', 'LT.NS'), 'BSE.NS', 'CDSL.NS', 'MCX.NS', 'CAMS.NS', 'KFINTECH.NS',

  // GLOBAL TECH (For benchmark)
  'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'TSLA', 'META', 'NFLX', 'BRK-B'
];

// Map of Base Symbol -> NSE Symbol (e.g., 'RELIANCE' -> 'RELIANCE.NS')
const INDIAN_STOCK_MAP = new Map(
  POPULAR_IND_STOCKS.map(s => [s.replace('.NS', ''), s])
);

// Helper to resolve symbol to NSE if applicable
const resolveSymbol = (symbol) => {
  const upper = symbol.toUpperCase();
  // If we have a mapping for the base name (e.g. INFY -> INFY.NS), use it
  if (INDIAN_STOCK_MAP.has(upper)) return INDIAN_STOCK_MAP.get(upper);
  // If it already has .NS or .BO, leave it
  if (upper.endsWith('.NS') || upper.endsWith('.BO')) return upper;
  // Default: Return as is (might be US stock)
  return upper;
};

const cache = {
  stocks: { data: null, timestamp: 0 },
  stockDetails: {},
  marketOverview: { data: null, timestamp: 0 }
};

const CACHE_DURATION = {
  STOCKS_LIST: 5 * 60 * 1000,
  STOCK_DETAIL: 2 * 60 * 1000,
  MARKET_OVERVIEW: 3 * 60 * 1000
};

const isCacheValid = (cacheEntry, duration) => {
  return cacheEntry && cacheEntry.data && (Date.now() - cacheEntry.timestamp < duration);
};

// Helper: Normalize Yahoo Quote to App Format
const normalizeYahooQuote = (q) => ({
  symbol: q.symbol,
  name: q.shortName || q.longName || q.symbol,
  price: q.regularMarketPrice || 0,
  currentPrice: q.regularMarketPrice || 0, // Alias for frontend compatibility
  previousClose: q.regularMarketPreviousClose || 0,
  change: q.regularMarketChange || 0,
  changePercent: q.regularMarketChangePercent || 0,
  dayHigh: q.regularMarketDayHigh || 0,
  dayLow: q.regularMarketDayLow || 0,
  volume: q.regularMarketVolume || 0,
  marketCap: q.marketCap || 0,
  pe: q.trailingPE || 0,
  eps: q.epsTrailingTwelveMonths || 0,
  weekHigh52: q.fiftyTwoWeekHigh || 0,
  weekLow52: q.fiftyTwoWeekLow || 0,
  exchange: q.exchange || 'NSE',
  currency: q.currency || 'INR'
});

// @desc    Get list of all available stocks (Yahoo Finance)
// @route   GET /api/markets/stocks
// @access  Private
exports.getStocks = async (req, res) => {
  try {
    if (isCacheValid(cache.stocks, CACHE_DURATION.STOCKS_LIST)) {
      return res.status(200).json({ success: true, count: cache.stocks.data.length, data: cache.stocks.data, cached: true });
    }

    // Fetch quotes for popular stocks
    const quotes = await yahooFinance.quote(POPULAR_IND_STOCKS);
    const stocks = quotes.map(normalizeYahooQuote);

    cache.stocks = { data: stocks, timestamp: Date.now() };
    res.status(200).json({ success: true, count: stocks.length, data: stocks, cached: false });
  } catch (error) {
    console.error('getStocks Error:', error);
    res.status(500).json({ success: false, message: 'Error fetching stocks' });
  }
};

// @desc    Get stock details with price history (Yahoo Finance)
// @route   GET /api/markets/stocks/:symbol
// @access  Private
exports.getStockDetail = async (req, res) => {
  try {
    const { symbol } = req.params;
    const { timeframe = '1M' } = req.query;
    const resolvedSymbol = resolveSymbol(symbol);

    let stockData = null;
    try {
      const quote = await yahooFinance.quote(resolvedSymbol);
      stockData = normalizeYahooQuote(quote);

      // Fetch Historical Data
      const end = new Date();
      let start = new Date();
      let interval = '1d';

      switch (timeframe) {
        case '1D': start.setDate(start.getDate() - 1); interval = '15m'; break;
        case '1W': start.setDate(start.getDate() - 7); interval = '1h'; break;
        case '1M': start.setMonth(start.getMonth() - 1); interval = '1d'; break;
        case '6M': start.setMonth(start.getMonth() - 6); interval = '1d'; break;
        case '1Y': start.setFullYear(start.getFullYear() - 1); interval = '1wk'; break;
        default: start.setMonth(start.getMonth() - 1);
      }

      const queryOptions = { period1: start, period2: end, interval };
      // Use chart() instead of historical()
      const result = await yahooFinance.chart(resolvedSymbol, queryOptions);

      let historicalData = [];
      if (result && result.quotes) {
        historicalData = result.quotes.map(q => ({
          date: q.date.toISOString().split('T')[0],
          timestamp: new Date(q.date).getTime(),
          open: q.open,
          high: q.high,
          low: q.low,
          close: q.close,
          volume: q.volume
        }));
      }

      const responseData = { ...stockData, historicalData };
      res.status(200).json({ success: true, data: responseData });
    } catch (err) {
      console.error('Info/History error for ' + resolvedSymbol + ':', err);
      // Attempt to return at least the quote data if chart fails
      if (stockData) {
        console.log('Returning quote only due to chart failure');
        return res.status(200).json({ success: true, data: { ...stockData, historicalData: [] } });
      } else {
        return res.status(404).json({ success: false, message: 'Stock data not found: ' + err.message });
      }
    }
  } catch (error) {
    console.error('getStockDetail fatal error:', error);
    res.status(500).json({ success: false, message: 'Error fetching stock details' });
  }
};

// @desc    Search stocks by name or symbol (Yahoo Finance)
// @route   GET /api/markets/search
// @access  Private
exports.searchStocks = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 2) return res.status(400).json({ success: false, message: 'Query too short' });

    const searchRes = await yahooFinance.search(q);

    // 1. Filter for Indian stocks
    const filteredQuotes = (searchRes.quotes || []).filter(q => {
      if (!q.symbol) return false;
      const s = q.symbol.toUpperCase();
      const isIndian = s.endsWith('.NS') || s.endsWith('.BO');
      const isIndex = s === '^NSEI' || s === '^BSESN';
      return isIndian || isIndex;
    });

    // 2. Extract symbols
    const symbols = filteredQuotes.map(q => q.symbol);

    // 3. Fetch full real-time data for these symbols (Search API doesn't give price)
    let fullQuotes = [];
    if (symbols.length > 0) {
      try {
        fullQuotes = await yahooFinance.quote(symbols);
      } catch (e) {
        console.error('Search quote fetch failed:', e);
        // Fallback to search results if quote fails (better than nothing)
        fullQuotes = filteredQuotes;
      }
    }

    const results = fullQuotes.map(normalizeYahooQuote);

    res.status(200).json({ success: true, count: results.length, data: results });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error searching stocks' });
  }
};

// @desc    Get user's portfolio
// @route   GET /api/markets/portfolio
// @access  Private
exports.getPortfolio = async (req, res) => {
  try {
    const portfolio = await PaperPortfolio.getOrCreatePortfolio(req.user.id);
    // Map holdings to resolved symbols (e.g. INFY -> INFY.NS) for fetching
    const holdingSymbols = (portfolio.holdings || []).map(h => resolveSymbol(h.symbol));

    // Batch fetch current prices
    let quotes = [];
    if (holdingSymbols.length > 0) {
      try {
        quotes = await yahooFinance.quote(holdingSymbols);
      } catch (e) {
        console.log('Portfolio quote fetch failed, trying individual');
      }
    }

    const holdingsWithCurrentValue = (portfolio.holdings || []).map(holding => {
      // Find quote using the resolved symbol
      const resolved = resolveSymbol(holding.symbol);
      const quote = quotes.find(q => q.symbol === resolved);
      const currentPrice = quote ? (quote.regularMarketPrice || holding.avgPrice) : holding.avgPrice;

      const currentValue = holding.quantity * currentPrice;
      const investedValue = holding.quantity * holding.avgPrice;
      const pnl = currentValue - investedValue;
      const pnlPercent = investedValue > 0 ? ((pnl / investedValue) * 100) : 0;

      return {
        ...holding,
        currentPrice,
        currentValue: parseFloat(currentValue.toFixed(2)),
        investedValue: parseFloat(investedValue.toFixed(2)),
        pnl: parseFloat(pnl.toFixed(2)),
        pnlPercent: parseFloat(pnlPercent.toFixed(2))
      };
    });

    // Calculate totals
    const totalCurrentValue = holdingsWithCurrentValue.reduce((sum, h) => sum + h.currentValue, 0);
    const totalInvestedValue = holdingsWithCurrentValue.reduce((sum, h) => sum + h.investedValue, 0);
    const totalPnl = totalCurrentValue - totalInvestedValue;
    const totalPnlPercent = totalInvestedValue > 0 ? ((totalPnl / totalInvestedValue) * 100) : 0;

    res.status(200).json({
      success: true,
      data: {
        id: portfolio.id,
        virtualBalance: portfolio.virtualBalance,
        holdings: holdingsWithCurrentValue,
        totalInvested: parseFloat(totalInvestedValue.toFixed(2)),
        currentPortfolioValue: parseFloat(totalCurrentValue.toFixed(2)),
        totalPnl: parseFloat(totalPnl.toFixed(2)),
        totalPnlPercent: parseFloat(totalPnlPercent.toFixed(2)),
        netWorth: parseFloat((portfolio.virtualBalance + totalCurrentValue).toFixed(2)),
        createdAt: portfolio.createdAt,
        updatedAt: portfolio.updatedAt
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching portfolio' });
  }
};

// @desc    Execute a paper trade (BUY/SELL)
// @route   POST /api/markets/trade
// @access  Private
exports.executeTrade = async (req, res) => {
  try {
    const { symbol, type, quantity } = req.body;
    const rawSymbol = symbol.toUpperCase();
    const resolvedSymbol = resolveSymbol(rawSymbol);

    if (!symbol || !type || !quantity) return res.status(400).json({ success: false, message: 'Invalid input' });
    if (!['BUY', 'SELL'].includes(type.toUpperCase())) return res.status(400).json({ success: false, message: 'Invalid type' });

    let executionPrice = 0;
    let stockName = rawSymbol;

    try {
      const quote = await yahooFinance.quote(resolvedSymbol);
      if (quote) {
        executionPrice = quote.regularMarketPrice;
        stockName = quote.shortName || quote.longName || rawSymbol;
      }
    } catch (e) {
      console.error(`Trade price fetch failed for ${resolvedSymbol}:`, e);
    }

    if (!executionPrice || executionPrice <= 0) {
      return res.status(503).json({ success: false, message: 'Could not fetch live price for ' + resolvedSymbol });
    }

    let updatedPortfolio;
    if (type.toUpperCase() === 'BUY') {
      updatedPortfolio = await PaperPortfolio.executeBuyTrade(req.user.id, resolvedSymbol, stockName, quantity, executionPrice);
    } else {
      updatedPortfolio = await PaperPortfolio.executeSellTrade(req.user.id, resolvedSymbol, quantity, executionPrice);
    }

    await PaperTrade.createTrade({
      userId: req.user.id,
      symbol: resolvedSymbol,
      stockName,
      type: type.toUpperCase(),
      quantity,
      price: executionPrice
    });

    res.status(200).json({
      success: true,
      message: `Successfully ${type.toUpperCase() === 'BUY' ? 'bought' : 'sold'} ${quantity} shares of ${resolvedSymbol} at ${executionPrice}`,
      data: { portfolio: updatedPortfolio }
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Get trade history
// @route   GET /api/markets/trades
// @access  Private
exports.getTradeHistory = async (req, res) => {
  try {
    const { limit = 50, symbol } = req.query;
    let trades;
    if (symbol) {
      trades = await PaperTrade.getTradesBySymbol(req.user.id, symbol);
    } else {
      trades = await PaperTrade.getTradeHistory(req.user.id, { limit: parseInt(limit) });
    }
    res.status(200).json({ success: true, count: trades.length, data: trades });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching trade history' });
  }
};

// @desc    Reset portfolio to initial state
// @route   POST /api/markets/portfolio/reset
// @access  Private
exports.resetPortfolio = async (req, res) => {
  try {
    const portfolio = await PaperPortfolio.resetPortfolio(req.user.id);
    res.status(200).json({ success: true, message: 'Portfolio reset successfully', data: portfolio });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error resetting portfolio' });
  }
};

// @desc    Get market overview / indices (with real API data)
// @route   GET /api/markets/overview
// @access  Private
exports.getMarketOverview = async (req, res) => {
  try {
    if (isCacheValid(cache.marketOverview, CACHE_DURATION.MARKET_OVERVIEW)) {
      return res.status(200).json({ success: true, data: cache.marketOverview.data, cached: true });
    }

    let indices = [];
    let topGainers = [];
    let topLosers = [];

    // 1. Fetch Indices
    try {
      const indexQuotes = await yahooFinance.quote(['^NSEI', '^BSESN', '^NSEBANK']);
      indices = indexQuotes.map(normalizeYahooQuote).map(q => {
        let name = q.symbol.replace('^', '');
        if (q.symbol === '^NSEI') name = 'NIFTY 50';
        if (q.symbol === '^BSESN') name = 'SENSEX';
        if (q.symbol === '^NSEBANK') name = 'BANK NIFTY';

        return {
          name,
          value: q.price,
          change: q.change,
          changePercent: q.changePercent
        };
      });
    } catch (e) { console.log('Index fetch failed'); }

    // 2. Fetch "Gainers/Losers" from our Popular list (since API doesn't support easily)
    try {
      const quotes = await yahooFinance.quote(POPULAR_IND_STOCKS);
      const sorted = quotes.map(normalizeYahooQuote).sort((a, b) => b.changePercent - a.changePercent);
      topGainers = sorted.slice(0, 5);
      topLosers = sorted.slice(sorted.length - 5, sorted.length).reverse(); // Worst losers first
    } catch (e) { console.log('Gainers/Losers fetch failed'); }

    const overviewData = { indices, topGainers, topLosers };
    cache.marketOverview = { data: overviewData, timestamp: Date.now() };

    res.status(200).json({ success: true, data: overviewData });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching market overview' });
  }
};

// @desc    Get user's watchlist
// @route   GET /api/markets/watchlist
// @access  Private
exports.getWatchlist = async (req, res) => {
  try {
    const watchlist = await Watchlist.getWatchlist(req.user.id);
    const symbols = watchlist.stocks.map(s => resolveSymbol(s.symbol));

    let quotes = [];
    if (symbols.length > 0) {
      try { quotes = await yahooFinance.quote(symbols); } catch (e) { }
    }

    // Merge existing data with live price
    // Merge existing data with live price
    const data = watchlist.stocks.map(stock => {
      const resolved = resolveSymbol(stock.symbol);
      const quote = quotes.find(q => q.symbol === resolved);
      return {
        symbol: stock.symbol,
        stockName: stock.stockName || stock.symbol,
        addedAt: stock.addedAt,
        currentPrice: quote ? (quote.regularMarketPrice || 0) : 0,
        change: quote ? (quote.regularMarketChange || 0) : 0,
        changePercent: quote ? (quote.regularMarketChangePercent || 0) : 0,
        dayHigh: quote ? (quote.regularMarketDayHigh || 0) : 0,
        dayLow: quote ? (quote.regularMarketDayLow || 0) : 0
      };
    });

    res.status(200).json({
      success: true,
      data: {
        id: watchlist.id,
        stocks: data,
        count: data.length,
        updatedAt: watchlist.updatedAt
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching watchlist' });
  }
};

// @desc    Add to watchlist
// @route   POST /api/markets/watchlist/add
// @access  Private
exports.addToWatchlist = async (req, res) => {
  try {
    const { symbol } = req.body;
    const resolvedSymbol = resolveSymbol(symbol);
    let stockName = symbol;
    // Try to get name
    try {
      const quote = await yahooFinance.quote(resolvedSymbol);
      stockName = quote.shortName || quote.longName || symbol;
    } catch (e) { }

    const updated = await Watchlist.addToWatchlist(req.user.id, symbol, stockName);
    res.status(200).json({ success: true, message: 'Added to watchlist', data: updated });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Remove from watchlist
// @route   DELETE /api/markets/watchlist/:symbol
// @access  Private
exports.removeFromWatchlist = async (req, res) => {
  try {
    const { symbol } = req.params;
    await Watchlist.removeFromWatchlist(req.user.id, symbol);
    res.status(200).json({ success: true, message: 'Removed from watchlist' });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Check if stock is in watchlist
// @route   GET /api/markets/watchlist/check/:symbol
// @access  Private
exports.checkWatchlist = async (req, res) => {
  try {
    const { symbol } = req.params;
    const inWatchlist = await Watchlist.isInWatchlist(req.user.id, symbol);
    res.status(200).json({ success: true, inWatchlist });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error checking watchlist' });
  }
};

// @desc    Compare stocks
// @route   POST /api/markets/compare
// @access  Private
exports.compareStocks = async (req, res) => {
  try {
    const { symbols } = req.body;
    if (!symbols || !Array.isArray(symbols)) return res.status(400).json({ success: false, message: 'Symbols array required' });

    const resolvedSymbols = symbols.map(s => resolveSymbol(s));
    const quotes = await yahooFinance.quote(resolvedSymbols);

    const stocks = quotes.map(q => ({
      symbol: q.symbol,
      name: q.shortName || q.longName || q.symbol,
      currentPrice: q.regularMarketPrice || 0,
      change: q.regularMarketChange || 0,
      changePercent: q.regularMarketChangePercent || 0,
      dayHigh: q.regularMarketDayHigh || 0,
      dayLow: q.regularMarketDayLow || 0,
      yearHigh: q.fiftyTwoWeekHigh || 0,
      yearLow: q.fiftyTwoWeekLow || 0,
      marketCap: q.marketCap || 0,
      pe: q.trailingPE || 0,
      pb: q.priceToBook || 0,
      eps: q.epsTrailingTwelveMonths || 0,
      dividend: q.dividendYield || 0,
      sector: q.sector || 'N/A', // quote might not have this, but let's try
      industry: q.industry || 'N/A',
      volume: q.regularMarketVolume || 0,
      avgVolume: q.averageDailyVolume3Month || 0
    }));

    const responseData = {
      stocks,
      comparison: {},
      comparedAt: new Date().toISOString()
    };

    res.status(200).json({ success: true, data: responseData });
  } catch (error) {
    console.error('compareStocks error:', error);
    res.status(500).json({ success: false, message: 'Error comparing stocks' });
  }
};

// @desc    Get candlestick data 
// @route   GET /api/markets/stocks/:symbol/candles
// @access  Private
exports.getCandlestickData = async (req, res) => {
  try {
    const { symbol } = req.params;
    const { range = '1mo', interval = '1d' } = req.query;

    const validIntervals = ['1m', '2m', '5m', '15m', '30m', '60m', '90m', '1h', '1d', '5d', '1wk', '1mo', '3mo'];
    const useInterval = validIntervals.includes(interval) ? interval : '1d';

    const end = new Date();
    const start = new Date();
    if (range.endsWith('d')) start.setDate(start.getDate() - parseInt(range));
    else if (range.endsWith('w')) start.setDate(start.getDate() - parseInt(range) * 7);
    else if (range.endsWith('mo') || range.endsWith('m')) start.setMonth(start.getMonth() - parseInt(range));
    else if (range.endsWith('y')) start.setFullYear(start.getFullYear() - parseInt(range));
    else start.setMonth(start.getMonth() - 1);

    const queryOptions = { period1: start, period2: end, interval: useInterval };
    const result = await yahooFinance.chart(symbol, queryOptions);

    let data = [];
    if (result && result.quotes) {
      data = result.quotes.map(q => ({
        time: new Date(q.date).getTime(),
        open: q.open,
        high: q.high,
        low: q.low,
        close: q.close,
        volume: q.volume
      }));
    }
    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching candles' });
  }
};