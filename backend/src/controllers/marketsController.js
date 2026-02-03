const PaperTrade = require('../models/PaperTrade');
const PaperPortfolio = require('../models/PaperPortfolio');
const Watchlist = require('../models/Watchlist');

// ============================================================
// INDIAN STOCK API INTEGRATION WITH CACHING
// Architecture: IndianAPI → Backend (cache) → PaperTrade → Frontend
// ============================================================

const INDIAN_API_KEY = process.env.INDIAN_API_KEY;
const INDIAN_API_BASE_URL = process.env.INDIAN_API_BASE_URL || 'https://stock.indianapi.in';

// In-memory cache to reduce API calls (500 request limit)
const cache = {
  stocks: { data: null, timestamp: 0 },
  stockDetails: {}, // { symbol: { data, timestamp } }
  marketOverview: { data: null, timestamp: 0 }
};

// Cache duration: 5 minutes for stocks, 2 minutes for real-time prices
const CACHE_DURATION = {
  STOCKS_LIST: 5 * 60 * 1000,     // 5 minutes
  STOCK_DETAIL: 2 * 60 * 1000,    // 2 minutes  
  MARKET_OVERVIEW: 3 * 60 * 1000  // 3 minutes
};

// Helper: Fetch from Indian API
const fetchFromIndianAPI = async (endpoint) => {
  try {
    const url = `${INDIAN_API_BASE_URL}${endpoint}`;
    console.log(`[IndianAPI] Fetching: ${url}`);
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'X-Api-Key': INDIAN_API_KEY,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    console.log(`[IndianAPI] Success: ${endpoint}`);
    return data;
  } catch (error) {
    console.error(`[IndianAPI] Error fetching ${endpoint}:`, error.message);
    throw error;
  }
};

// Helper: Check if cache is valid
const isCacheValid = (cacheEntry, duration) => {
  return cacheEntry && cacheEntry.data && (Date.now() - cacheEntry.timestamp < duration);
};

// Fallback mock data when API fails or for development
const FALLBACK_STOCKS = {
  'RELIANCE': { name: 'Reliance Industries Ltd', price: 2456.75, change: 1.25 },
  'TCS': { name: 'Tata Consultancy Services', price: 3890.50, change: -0.45 },
  'HDFCBANK': { name: 'HDFC Bank Ltd', price: 1678.30, change: 0.85 },
  'INFY': { name: 'Infosys Ltd', price: 1542.20, change: 2.10 },
  'ICICIBANK': { name: 'ICICI Bank Ltd', price: 1125.40, change: -0.32 },
  'HINDUNILVR': { name: 'Hindustan Unilever Ltd', price: 2580.15, change: 0.65 },
  'ITC': { name: 'ITC Ltd', price: 445.80, change: 1.15 },
  'SBIN': { name: 'State Bank of India', price: 625.90, change: -1.20 },
  'BHARTIARTL': { name: 'Bharti Airtel Ltd', price: 1485.60, change: 0.95 },
  'KOTAKBANK': { name: 'Kotak Mahindra Bank', price: 1756.25, change: 0.45 },
  'WIPRO': { name: 'Wipro Ltd', price: 485.30, change: -0.75 },
  'AXISBANK': { name: 'Axis Bank Ltd', price: 1082.45, change: 1.35 },
  'LT': { name: 'Larsen & Toubro Ltd', price: 3245.80, change: 0.55 },
  'MARUTI': { name: 'Maruti Suzuki India', price: 10875.40, change: -0.25 },
  'ASIANPAINT': { name: 'Asian Paints Ltd', price: 2890.60, change: 0.85 },
  'TATAMOTORS': { name: 'Tata Motors Ltd', price: 785.25, change: 2.45 },
  'SUNPHARMA': { name: 'Sun Pharmaceutical', price: 1245.70, change: -0.55 },
  'TITAN': { name: 'Titan Company Ltd', price: 3125.90, change: 1.05 },
  'BAJFINANCE': { name: 'Bajaj Finance Ltd', price: 6890.45, change: -1.15 },
  'HCLTECH': { name: 'HCL Technologies', price: 1425.80, change: 0.95 }
};

// Simple seeded random number generator for consistent mock data per symbol/timeframe
const seededRandom = (seed) => {
  const x = Math.sin(seed) * 10000;
  return x - Math.floor(x);
};

// Generate mock historical data for charts (fallback)
// Uses symbol hash + timeframe to generate consistent but different data per timeframe
const generateMockHistoricalData = (basePrice, days, symbol = 'DEFAULT', timeframe = '1M') => {
  const data = [];
  
  // Create a seed based on symbol and timeframe for consistent but different data
  let seed = 0;
  for (let i = 0; i < symbol.length; i++) {
    seed += symbol.charCodeAt(i);
  }
  // Add timeframe to seed so different timeframes show different patterns
  const timeframeSeed = { '1D': 1, '1W': 7, '1M': 30, '3M': 90, '6M': 180, '1Y': 365 };
  seed += (timeframeSeed[timeframe] || 30) * 100;
  
  let currentPrice = basePrice * (0.9 + seededRandom(seed) * 0.2); // Start between 90-110% of base
  const now = new Date();
  
  // Different volatility for different timeframes
  const volatility = timeframe === '1D' ? 0.005 : (timeframe === '1W' ? 0.015 : 0.025);
  // Different trend bias per symbol
  const trendBias = (seededRandom(seed + 1000) - 0.5) * 0.01;

  for (let i = days; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    
    // Use seeded random for this data point
    const pointSeed = seed + i * 17; // Different seed per day
    const change = (seededRandom(pointSeed) - 0.48 + trendBias) * volatility;
    currentPrice = currentPrice * (1 + change);
    
    // Ensure price doesn't go negative or too extreme
    currentPrice = Math.max(currentPrice, basePrice * 0.5);
    currentPrice = Math.min(currentPrice, basePrice * 1.5);
    
    const dailyVolatility = seededRandom(pointSeed + 1) * 0.02;
    const open = currentPrice * (1 + (seededRandom(pointSeed + 2) - 0.5) * dailyVolatility);
    const high = Math.max(open, currentPrice) * (1 + seededRandom(pointSeed + 3) * 0.015);
    const low = Math.min(open, currentPrice) * (1 - seededRandom(pointSeed + 4) * 0.015);
    const volume = Math.floor(seededRandom(pointSeed + 5) * 10000000) + 1000000;

    data.push({
      date: date.toISOString().split('T')[0],
      timestamp: date.getTime(),
      open: parseFloat(open.toFixed(2)),
      high: parseFloat(high.toFixed(2)),
      low: parseFloat(low.toFixed(2)),
      close: parseFloat(currentPrice.toFixed(2)),
      volume
    });
  }

  return data;
};

// @desc    Get list of all available stocks (with real API data)
// @route   GET /api/markets/stocks
// @access  Private
exports.getStocks = async (req, res) => {
  try {
    // Check cache first
    if (isCacheValid(cache.stocks, CACHE_DURATION.STOCKS_LIST)) {
      console.log('[Cache] Returning cached stocks list');
      return res.status(200).json({
        success: true,
        count: cache.stocks.data.length,
        data: cache.stocks.data,
        cached: true
      });
    }

    // Try to fetch from real API
    let stocks = [];
    try {
      const apiData = await fetchFromIndianAPI('/trending');
      
      if (apiData && apiData.trending_stocks) {
        stocks = apiData.trending_stocks.map(stock => ({
          symbol: stock.symbol || stock.ticker,
          name: stock.company_name || stock.name,
          price: parseFloat(stock.price || stock.ltp || 0),
          change: parseFloat(stock.change || 0),
          changePercent: parseFloat(stock.percent_change || stock.change_percent || 0).toFixed(2)
        }));
      }

      // Also fetch top gainers and losers to get more stocks
      const [gainersData, losersData] = await Promise.all([
        fetchFromIndianAPI('/NSE_top_gainers').catch(() => null),
        fetchFromIndianAPI('/NSE_top_losers').catch(() => null)
      ]);

      if (gainersData && Array.isArray(gainersData)) {
        gainersData.forEach(stock => {
          if (!stocks.find(s => s.symbol === stock.symbol)) {
            stocks.push({
              symbol: stock.symbol,
              name: stock.company_name || stock.name,
              price: parseFloat(stock.ltp || stock.price || 0),
              change: parseFloat(stock.change || 0),
              changePercent: parseFloat(stock.percent_change || 0).toFixed(2)
            });
          }
        });
      }

      if (losersData && Array.isArray(losersData)) {
        losersData.forEach(stock => {
          if (!stocks.find(s => s.symbol === stock.symbol)) {
            stocks.push({
              symbol: stock.symbol,
              name: stock.company_name || stock.name,
              price: parseFloat(stock.ltp || stock.price || 0),
              change: parseFloat(stock.change || 0),
              changePercent: parseFloat(stock.percent_change || 0).toFixed(2)
            });
          }
        });
      }

    } catch (apiError) {
      console.error('[IndianAPI] Falling back to mock data:', apiError.message);
    }

    // Fallback to mock data if API fails or returns empty
    if (stocks.length === 0) {
      stocks = Object.entries(FALLBACK_STOCKS).map(([symbol, data]) => ({
        symbol,
        name: data.name,
        price: parseFloat((data.price * (1 + (Math.random() - 0.5) * 0.02)).toFixed(2)),
        change: data.change + (Math.random() - 0.5) * 0.5,
        changePercent: (data.change + (Math.random() - 0.5) * 0.5).toFixed(2)
      }));
    }

    // Update cache
    cache.stocks = { data: stocks, timestamp: Date.now() };

    res.status(200).json({
      success: true,
      count: stocks.length,
      data: stocks,
      cached: false
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching stocks',
      error: error.message
    });
  }
};

// @desc    Get stock details with price history
// @route   GET /api/markets/stocks/:symbol
// @access  Private
exports.getStockDetail = async (req, res) => {
  try {
    const { symbol } = req.params;
    const { timeframe = '1M' } = req.query;
    const upperSymbol = symbol.toUpperCase();

    // Check cache
    const cacheKey = `${upperSymbol}_${timeframe}`;
    if (cache.stockDetails[cacheKey] && isCacheValid(cache.stockDetails[cacheKey], CACHE_DURATION.STOCK_DETAIL)) {
      console.log(`[Cache] Returning cached stock detail: ${upperSymbol}`);
      return res.status(200).json({
        success: true,
        data: cache.stockDetails[cacheKey].data,
        cached: true
      });
    }

    let stockData = null;
    let historicalData = [];

    // Try to fetch from real API
    try {
      // Fetch stock info
      const stockInfo = await fetchFromIndianAPI(`/stock?name=${encodeURIComponent(upperSymbol)}`);
      
      if (stockInfo) {
        const currentPrice = parseFloat(stockInfo.currentPrice?.NSE || stockInfo.currentPrice?.BSE || stockInfo.price || 0);
        const previousClose = parseFloat(stockInfo.previousClose || currentPrice * 0.99);
        const change = currentPrice - previousClose;
        const changePercent = ((change / previousClose) * 100);

        stockData = {
          symbol: upperSymbol,
          name: stockInfo.companyName || stockInfo.name || upperSymbol,
          currentPrice,
          previousClose,
          change: parseFloat(change.toFixed(2)),
          changePercent: parseFloat(changePercent.toFixed(2)),
          dayHigh: parseFloat(stockInfo.dayHigh || currentPrice * 1.02),
          dayLow: parseFloat(stockInfo.dayLow || currentPrice * 0.98),
          volume: parseInt(stockInfo.totalTradedVolume || stockInfo.volume || 0),
          marketCap: stockInfo.marketCap || 'N/A',
          pe: stockInfo.pe || 'N/A',
          eps: stockInfo.eps || 'N/A',
          weekHigh52: stockInfo['52weekHigh'] || stockInfo.yearHigh,
          weekLow52: stockInfo['52weekLow'] || stockInfo.yearLow
        };

        // Try to get historical data
        try {
          const histData = await fetchFromIndianAPI(`/historical_data?stock_name=${encodeURIComponent(upperSymbol)}&period=${timeframe.toLowerCase()}`);
          
          if (histData && histData.datasets) {
            historicalData = histData.datasets.map((point, index) => ({
              date: point.date || new Date(Date.now() - (histData.datasets.length - index) * 86400000).toISOString().split('T')[0],
              timestamp: new Date(point.date || Date.now() - (histData.datasets.length - index) * 86400000).getTime(),
              open: parseFloat(point.open || point.close),
              high: parseFloat(point.high || point.close),
              low: parseFloat(point.low || point.close),
              close: parseFloat(point.close || point.price),
              volume: parseInt(point.volume || 0)
            }));
          }
        } catch (histError) {
          console.log('[IndianAPI] Historical data not available, using generated data');
        }
      }
    } catch (apiError) {
      console.error('[IndianAPI] Stock detail fetch failed:', apiError.message);
    }

    // Fallback to mock data
    if (!stockData) {
      const fallbackStock = FALLBACK_STOCKS[upperSymbol];
      if (!fallbackStock) {
        return res.status(404).json({
          success: false,
          message: `Stock ${upperSymbol} not found`
        });
      }

      const currentPrice = parseFloat((fallbackStock.price * (1 + (Math.random() - 0.5) * 0.01)).toFixed(2));
      const previousClose = fallbackStock.price;
      const change = currentPrice - previousClose;

      stockData = {
        symbol: upperSymbol,
        name: fallbackStock.name,
        currentPrice,
        previousClose,
        change: parseFloat(change.toFixed(2)),
        changePercent: parseFloat(((change / previousClose) * 100).toFixed(2)),
        dayHigh: currentPrice * 1.015,
        dayLow: currentPrice * 0.985,
        volume: Math.floor(Math.random() * 10000000) + 1000000,
        marketCap: `₹${(currentPrice * (Math.random() * 1000 + 500)).toFixed(0)} Cr`
      };
    }

    // Generate mock historical data if not available
    if (historicalData.length === 0) {
      const daysMap = { '1D': 1, '1W': 7, '1M': 30, '3M': 90, '6M': 180, '1Y': 365 };
      const days = daysMap[timeframe] || 30;
      historicalData = generateMockHistoricalData(stockData.currentPrice, days, upperSymbol, timeframe);
    }

    const responseData = {
      ...stockData,
      historicalData
    };

    // Update cache
    cache.stockDetails[cacheKey] = { data: responseData, timestamp: Date.now() };

    res.status(200).json({
      success: true,
      data: responseData,
      cached: false
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching stock details',
      error: error.message
    });
  }
};

// @desc    Search stocks by name or symbol
// @route   GET /api/markets/search
// @access  Private
exports.searchStocks = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Search query must be at least 2 characters'
      });
    }

    let results = [];

    // Try real API search
    try {
      const searchData = await fetchFromIndianAPI(`/stock?name=${encodeURIComponent(q)}`);
      
      if (searchData && searchData.companyName) {
        results.push({
          symbol: q.toUpperCase(),
          name: searchData.companyName,
          price: parseFloat(searchData.currentPrice?.NSE || searchData.currentPrice?.BSE || 0),
          change: 0
        });
      }
    } catch (apiError) {
      console.log('[IndianAPI] Search failed, using fallback');
    }

    // Also search in cached/fallback stocks
    const searchTerm = q.toLowerCase();
    const fallbackResults = Object.entries(FALLBACK_STOCKS)
      .filter(([symbol, data]) => 
        symbol.toLowerCase().includes(searchTerm) || 
        data.name.toLowerCase().includes(searchTerm)
      )
      .map(([symbol, data]) => ({
        symbol,
        name: data.name,
        price: parseFloat((data.price * (1 + (Math.random() - 0.5) * 0.01)).toFixed(2)),
        change: data.change
      }));

    // Merge results (API results first, then fallback)
    results = [...results, ...fallbackResults.filter(f => !results.find(r => r.symbol === f.symbol))];

    res.status(200).json({
      success: true,
      count: results.length,
      data: results
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error searching stocks',
      error: error.message
    });
  }
};

// @desc    Get user's portfolio
// @route   GET /api/markets/portfolio
// @access  Private
exports.getPortfolio = async (req, res) => {
  try {
    const portfolio = await PaperPortfolio.getOrCreatePortfolio(req.user.id);

    // Calculate current values for holdings using latest prices
    const holdingsWithCurrentValue = await Promise.all(
      (portfolio.holdings || []).map(async (holding) => {
        let currentPrice = holding.avgPrice;

        // Try to get real price from multiple sources
        try {
          // 1. Check stock detail cache first
          const cacheKey = `${holding.symbol}_1M`;
          if (cache.stockDetails[cacheKey] && 
              isCacheValid(cache.stockDetails[cacheKey], CACHE_DURATION.STOCK_DETAIL)) {
            currentPrice = cache.stockDetails[cacheKey].data.currentPrice;
          } else {
            // 2. Try fetching from API
            const stockInfo = await fetchFromIndianAPI(`/stock?name=${encodeURIComponent(holding.symbol)}`);
            if (stockInfo) {
              // Extract price from various possible formats
              if (stockInfo.currentPrice) {
                const nsePrice = stockInfo.currentPrice.NSE || stockInfo.currentPrice.BSE;
                if (nsePrice) {
                  currentPrice = parseFloat(nsePrice.replace(/,/g, ''));
                }
              } else if (stockInfo.priceInfo && stockInfo.priceInfo.lastPrice) {
                currentPrice = parseFloat(stockInfo.priceInfo.lastPrice);
              } else if (stockInfo.lastPrice) {
                currentPrice = parseFloat(stockInfo.lastPrice);
              }
            }
          }
        } catch (e) {
          console.log(`[Portfolio] Could not fetch live price for ${holding.symbol}:`, e.message);
        }

        // 3. Fallback: Add small variance to simulate market movement if price unchanged
        if (currentPrice === holding.avgPrice) {
          const fallback = FALLBACK_STOCKS[holding.symbol];
          if (fallback) {
            // Use fallback price with small random variance
            currentPrice = parseFloat((fallback.price * (1 + (Math.random() - 0.5) * 0.03)).toFixed(2));
          } else {
            // Add small random variance (-1.5% to +1.5%) to avgPrice
            currentPrice = parseFloat((holding.avgPrice * (1 + (Math.random() - 0.5) * 0.03)).toFixed(2));
          }
        }

        const currentValue = holding.quantity * currentPrice;
        const investedValue = holding.quantity * holding.avgPrice;
        const pnl = currentValue - investedValue;
        const pnlPercent = ((pnl / investedValue) * 100).toFixed(2);

        return {
          ...holding,
          currentPrice,
          currentValue: parseFloat(currentValue.toFixed(2)),
          investedValue: parseFloat(investedValue.toFixed(2)),
          pnl: parseFloat(pnl.toFixed(2)),
          pnlPercent: parseFloat(pnlPercent)
        };
      })
    );

    // Calculate totals
    const totalCurrentValue = holdingsWithCurrentValue.reduce((sum, h) => sum + h.currentValue, 0);
    const totalInvestedValue = holdingsWithCurrentValue.reduce((sum, h) => sum + h.investedValue, 0);
    const totalPnl = totalCurrentValue - totalInvestedValue;
    const totalPnlPercent = totalInvestedValue > 0 
      ? ((totalPnl / totalInvestedValue) * 100).toFixed(2) 
      : 0;

    res.status(200).json({
      success: true,
      data: {
        id: portfolio.id,
        virtualBalance: portfolio.virtualBalance,
        holdings: holdingsWithCurrentValue,
        totalInvested: parseFloat(totalInvestedValue.toFixed(2)),
        currentPortfolioValue: parseFloat(totalCurrentValue.toFixed(2)),
        totalPnl: parseFloat(totalPnl.toFixed(2)),
        totalPnlPercent: parseFloat(totalPnlPercent),
        netWorth: parseFloat((portfolio.virtualBalance + totalCurrentValue).toFixed(2)),
        createdAt: portfolio.createdAt,
        updatedAt: portfolio.updatedAt
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching portfolio',
      error: error.message
    });
  }
};

// @desc    Execute a paper trade (BUY/SELL)
// @route   POST /api/markets/trade
// @access  Private
exports.executeTrade = async (req, res) => {
  try {
    const { symbol, type, quantity } = req.body;
    const upperSymbol = symbol.toUpperCase();

    // Validation
    if (!symbol || !type || !quantity) {
      return res.status(400).json({
        success: false,
        message: 'Symbol, type (BUY/SELL), and quantity are required'
      });
    }

    if (!['BUY', 'SELL'].includes(type.toUpperCase())) {
      return res.status(400).json({
        success: false,
        message: 'Type must be BUY or SELL'
      });
    }

    if (quantity < 1 || !Number.isInteger(quantity)) {
      return res.status(400).json({
        success: false,
        message: 'Quantity must be a positive integer'
      });
    }

    // Get current price (try real API first)
    let executionPrice = 0;
    let stockName = upperSymbol;

    try {
      const stockInfo = await fetchFromIndianAPI(`/stock?name=${encodeURIComponent(upperSymbol)}`);
      if (stockInfo && stockInfo.currentPrice) {
        executionPrice = parseFloat(stockInfo.currentPrice.NSE || stockInfo.currentPrice.BSE);
        stockName = stockInfo.companyName || upperSymbol;
      }
    } catch (e) {
      console.log('[Trade] Using fallback price for', upperSymbol);
    }

    // Fallback to mock price
    if (!executionPrice) {
      const fallback = FALLBACK_STOCKS[upperSymbol];
      if (!fallback) {
        return res.status(404).json({
          success: false,
          message: `Stock ${upperSymbol} not found`
        });
      }
      executionPrice = parseFloat((fallback.price * (1 + (Math.random() - 0.5) * 0.005)).toFixed(2));
      stockName = fallback.name;
    }

    let updatedPortfolio;

    if (type.toUpperCase() === 'BUY') {
      updatedPortfolio = await PaperPortfolio.executeBuyTrade(
        req.user.id,
        upperSymbol,
        stockName,
        quantity,
        executionPrice
      );
    } else {
      updatedPortfolio = await PaperPortfolio.executeSellTrade(
        req.user.id,
        upperSymbol,
        quantity,
        executionPrice
      );
    }

    // Record the trade
    const trade = await PaperTrade.createTrade({
      userId: req.user.id,
      symbol: upperSymbol,
      stockName,
      type: type.toUpperCase(),
      quantity,
      price: executionPrice
    });

    res.status(200).json({
      success: true,
      message: `Successfully ${type.toUpperCase() === 'BUY' ? 'bought' : 'sold'} ${quantity} shares of ${upperSymbol} at ₹${executionPrice}`,
      data: {
        trade,
        portfolio: {
          virtualBalance: updatedPortfolio.virtualBalance,
          totalInvested: updatedPortfolio.totalInvested,
          holdingsCount: updatedPortfolio.holdings.length
        }
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
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

    res.status(200).json({
      success: true,
      count: trades.length,
      data: trades
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching trade history',
      error: error.message
    });
  }
};

// @desc    Reset portfolio to initial state
// @route   POST /api/markets/portfolio/reset
// @access  Private
exports.resetPortfolio = async (req, res) => {
  try {
    const portfolio = await PaperPortfolio.resetPortfolio(req.user.id);

    res.status(200).json({
      success: true,
      message: 'Portfolio reset successfully. Starting fresh with ₹10,00,000 virtual balance.',
      data: {
        virtualBalance: portfolio.virtualBalance,
        holdings: portfolio.holdings,
        totalInvested: portfolio.totalInvested
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error resetting portfolio',
      error: error.message
    });
  }
};

// @desc    Get market overview / indices (with real API data)
// @route   GET /api/markets/overview
// @access  Private
exports.getMarketOverview = async (req, res) => {
  try {
    // Check cache
    if (isCacheValid(cache.marketOverview, CACHE_DURATION.MARKET_OVERVIEW)) {
      console.log('[Cache] Returning cached market overview');
      return res.status(200).json({
        success: true,
        data: cache.marketOverview.data,
        cached: true
      });
    }

    let indices = [];
    let topGainers = [];
    let topLosers = [];

    // Try to fetch real data
    try {
      // Fetch trending/index data
      const [trendingData, gainersData, losersData] = await Promise.all([
        fetchFromIndianAPI('/trending').catch(() => null),
        fetchFromIndianAPI('/NSE_top_gainers').catch(() => null),
        fetchFromIndianAPI('/NSE_top_losers').catch(() => null)
      ]);

      // Parse indices from trending data
      if (trendingData) {
        if (trendingData.index_data) {
          indices = Object.entries(trendingData.index_data).map(([name, data]) => ({
            name,
            value: parseFloat(data.price || data.value || 0),
            change: parseFloat(data.change || 0),
            changePercent: parseFloat(data.percent_change || data.change_percent || 0).toFixed(2)
          })).slice(0, 5);
        }
      }

      // Top gainers
      if (gainersData && Array.isArray(gainersData)) {
        topGainers = gainersData.slice(0, 5).map(stock => ({
          symbol: stock.symbol,
          name: stock.company_name || stock.name || stock.symbol,
          price: parseFloat(stock.ltp || stock.price || 0),
          change: parseFloat(stock.change || 0),
          changePercent: parseFloat(stock.percent_change || 0).toFixed(2)
        }));
      }

      // Top losers
      if (losersData && Array.isArray(losersData)) {
        topLosers = losersData.slice(0, 5).map(stock => ({
          symbol: stock.symbol,
          name: stock.company_name || stock.name || stock.symbol,
          price: parseFloat(stock.ltp || stock.price || 0),
          change: parseFloat(stock.change || 0),
          changePercent: parseFloat(stock.percent_change || 0).toFixed(2)
        }));
      }

    } catch (apiError) {
      console.error('[IndianAPI] Market overview fetch failed:', apiError.message);
    }

    // Fallback mock data
    if (indices.length === 0) {
      indices = [
        { name: 'NIFTY 50', value: 22456.80 + (Math.random() - 0.5) * 200, change: (Math.random() - 0.5) * 150, changePercent: ((Math.random() - 0.5) * 1.5).toFixed(2) },
        { name: 'SENSEX', value: 73856.45 + (Math.random() - 0.5) * 500, change: (Math.random() - 0.5) * 400, changePercent: ((Math.random() - 0.5) * 1.2).toFixed(2) },
        { name: 'NIFTY BANK', value: 48234.60 + (Math.random() - 0.5) * 300, change: (Math.random() - 0.5) * 250, changePercent: ((Math.random() - 0.5) * 1.8).toFixed(2) }
      ];
    }

    if (topGainers.length === 0 || topLosers.length === 0) {
      const allStocks = Object.entries(FALLBACK_STOCKS).map(([symbol, data]) => ({
        symbol,
        name: data.name,
        price: parseFloat((data.price * (1 + (Math.random() - 0.5) * 0.02)).toFixed(2)),
        change: data.change + (Math.random() - 0.5) * 2,
        changePercent: (data.change + (Math.random() - 0.5) * 2).toFixed(2)
      }));

      const sorted = [...allStocks].sort((a, b) => b.change - a.change);
      if (topGainers.length === 0) topGainers = sorted.slice(0, 5);
      if (topLosers.length === 0) topLosers = sorted.slice(-5).reverse();
    }

    const responseData = {
      indices: indices.map(idx => ({
        ...idx,
        value: parseFloat(typeof idx.value === 'number' ? idx.value.toFixed(2) : idx.value),
        change: parseFloat(typeof idx.change === 'number' ? idx.change.toFixed(2) : idx.change)
      })),
      topGainers,
      topLosers,
      marketStatus: 'OPEN',
      lastUpdated: new Date().toISOString()
    };

    // Update cache
    cache.marketOverview = { data: responseData, timestamp: Date.now() };

    res.status(200).json({
      success: true,
      data: responseData,
      cached: false
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching market overview',
      error: error.message
    });
  }
};
// ============================================================
// WATCHLIST ENDPOINTS
// ============================================================

// @desc    Get user's watchlist with current stock details
// @route   GET /api/markets/watchlist
// @access  Private
exports.getWatchlist = async (req, res) => {
  try {
    const watchlist = await Watchlist.getWatchlist(req.user.id);
    
    // Fetch current prices for all watchlisted stocks
    const stocksWithDetails = await Promise.all(
      (watchlist.stocks || []).map(async (item) => {
        let currentPrice = 0;
        let change = 0;
        let changePercent = 0;
        let dayHigh = 0;
        let dayLow = 0;

        // Try to get real price
        try {
          const cacheKey = `${item.symbol}_1M`;
          if (cache.stockDetails[cacheKey] && 
              isCacheValid(cache.stockDetails[cacheKey], CACHE_DURATION.STOCK_DETAIL)) {
            const cached = cache.stockDetails[cacheKey].data;
            currentPrice = cached.currentPrice;
            change = cached.change;
            changePercent = cached.changePercent;
            dayHigh = cached.dayHigh;
            dayLow = cached.dayLow;
          } else {
            const stockInfo = await fetchFromIndianAPI(`/stock?name=${encodeURIComponent(item.symbol)}`);
            if (stockInfo) {
              currentPrice = parseFloat(stockInfo.currentPrice?.NSE?.replace(/,/g, '') || 
                                       stockInfo.currentPrice?.BSE?.replace(/,/g, '') || 0);
              change = parseFloat(stockInfo.percentChange || 0);
              changePercent = parseFloat(stockInfo.percentChange || 0);
              dayHigh = parseFloat(stockInfo.dayHigh?.replace(/,/g, '') || currentPrice * 1.02);
              dayLow = parseFloat(stockInfo.dayLow?.replace(/,/g, '') || currentPrice * 0.98);
            }
          }
        } catch (e) {
          // Use fallback
          const fallback = FALLBACK_STOCKS[item.symbol];
          if (fallback) {
            currentPrice = parseFloat((fallback.price * (1 + (Math.random() - 0.5) * 0.02)).toFixed(2));
            change = fallback.change;
            changePercent = fallback.change;
            dayHigh = currentPrice * 1.015;
            dayLow = currentPrice * 0.985;
          }
        }

        return {
          ...item,
          currentPrice: parseFloat(currentPrice.toFixed(2)),
          change: parseFloat(change.toFixed(2)),
          changePercent: parseFloat(changePercent.toFixed(2)),
          dayHigh: parseFloat(dayHigh.toFixed(2)),
          dayLow: parseFloat(dayLow.toFixed(2))
        };
      })
    );

    res.status(200).json({
      success: true,
      data: {
        id: watchlist.id,
        stocks: stocksWithDetails,
        count: stocksWithDetails.length,
        updatedAt: watchlist.updatedAt
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching watchlist',
      error: error.message
    });
  }
};

// @desc    Add stock to watchlist
// @route   POST /api/markets/watchlist/add
// @access  Private
exports.addToWatchlist = async (req, res) => {
  try {
    const { symbol, stockName } = req.body;

    if (!symbol) {
      return res.status(400).json({
        success: false,
        message: 'Symbol is required'
      });
    }

    const watchlist = await Watchlist.addToWatchlist(
      req.user.id, 
      symbol, 
      stockName || symbol
    );

    res.status(200).json({
      success: true,
      message: `${symbol.toUpperCase()} added to watchlist`,
      data: watchlist
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Remove stock from watchlist
// @route   DELETE /api/markets/watchlist/:symbol
// @access  Private
exports.removeFromWatchlist = async (req, res) => {
  try {
    const { symbol } = req.params;

    if (!symbol) {
      return res.status(400).json({
        success: false,
        message: 'Symbol is required'
      });
    }

    const watchlist = await Watchlist.removeFromWatchlist(req.user.id, symbol);

    res.status(200).json({
      success: true,
      message: `${symbol.toUpperCase()} removed from watchlist`,
      data: watchlist
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Check if stock is in watchlist
// @route   GET /api/markets/watchlist/check/:symbol
// @access  Private
exports.checkWatchlist = async (req, res) => {
  try {
    const { symbol } = req.params;
    const isWatched = await Watchlist.isInWatchlist(req.user.id, symbol);

    res.status(200).json({
      success: true,
      data: { isWatched, symbol: symbol.toUpperCase() }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};